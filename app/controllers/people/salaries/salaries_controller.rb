=begin
  CIRCL Directory
  Copyright (C) 2011 Complex IT sàrl

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU Affero General Public License as
  published by the Free Software Foundation, either version 3 of the
  License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Affero General Public License for more details.

  You should have received a copy of the GNU Affero General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end

class People::Salaries::SalariesController < ApplicationController

  layout false

  def self.model
    Salaries::Salary
  end

  load_resource :person
  # load_and_authorize_resource :class => model, :through => :person
  load_resource :class => model, :through => :person

  monitor_changes :@salary

  def index
    respond_to do |format|
      format.json { render :json => @salaries }
    end
  end

  def show
    respond_to do |format|
      format.json { render :json => @salary }

      format.html do
        html = build_from_template(@salary)
        html.assets_to_full_path!
        render :inline => html, :layout => 'preview'
      end

      format.pdf do
        if ! @salary.pdf_up_to_date? or ! File.exists?(@salary.pdf.path)
          BackgroundTasks::GenerateSalaryPdf.process!(:salary_id => @salary.id)
          @salary.reload
        end
        send_data File.read(@salary.pdf.path),
                  :filename => "salary_#{params[:id]}.pdf",
                  :type => 'application/pdf'
      end
    end
  end

  def create
    respond_to do |format|
      if @salary.save
        format.json { render :json => @salary }
      else
        format.json { render :json => @salary.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json { render :json => @salary }
    end
  end

  def update
    respond_to do |format|
      if @salary.update_attributes(params[:salary])
        format.json { render :json => @salary }
      else
        format.json { render :json => @salary.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update_items
    items = params[:items].each_with_object([]) do |(unused, attributes), arr|
      attributes[:tax_ids] ||= [] # make sure this is reset if not sent
      item = attributes.has_key?(:id) ? Salaries::Item.find(attributes[:id]) : Salaries::Item.new
      item.assign_attributes(attributes)
      item.salary_id = @salary.id # Override given salary
      arr << item
    end
    items.reject!{ |i| i.new_record? && i.empty? }

    # Validate each item separatly
    errors = items.reject(&:valid?).each_with_object({}) do |item, h|
      h[:base] = item.errors.messages.map do |k, arr|
        msg = I18n.t("item.views.line") + " " + (item.position + 1).to_s + ": "
        msg += "#{I18n.t("tax_data.views." + k.to_s)}: #{arr.join(',')}"
      end
    end

    removed_items = @salary.items.reject{ |i| items.include?(i) }
    # TODO Validate items positions
    # TODO move all this in ItemsController#update

    respond_to do |format|
      if errors.empty?
        # Save new items
        items.each(&:save!)

        # Delete removed items
        removed_items.each(&:destroy)

        format.json { render :json => @salary.reload }
      else
        format.json { render :json => errors, :status => :unprocessable_entity }
      end
    end
  end

  def update_tax_data
    tax_data = params[:tax_data].each_with_object([]) do |(unused, attributes), arr|
      item = Salaries::TaxData.find(attributes[:id])
      item.assign_attributes(attributes)
      arr << item
    end

    # Validate each tax separatly
    errors = tax_data.reject(&:valid?).each_with_object({}) do |data, h|
      h[:base] = data.errors.messages.map do |k, arr|
        msg = I18n.t("item.views.line") + " " + (data.position + 1).to_s + ": "
        msg += "#{I18n.t("tax_data.views." + k.to_s)}: #{arr.join(',')}"
      end
    end

    # TODO Validate items positions
    # TODO move all this in TaxDataController#update

    respond_to do |format|
      if errors.size == 0
        # Save new items
        tax_data.each(&:save!)

        format.json { render :json => @salary.reload }
      else
        format.json { render :json => errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @salary.destroy
        format.json { render :json => {} }
      else
        format.json { render :json => @salary.errors, :status => :unprocessable_entity}
      end
    end
  end

  ##
  # PDF generation
  #

  ##
  # Returns an HTML page (that can be used to build a PDF)
  # with its placeholders substituted.
  #
  def build_from_template(salary)
    html = salary.salary_template.html.dup

    salary.placeholders[:simples].each { |p, v| html.gsub!("##{p}", v) }

    salary.placeholders[:iterators].each do |p, v|
      regex = "##{p}#{TEMPLATES_PLACEHOLDER_OPTIONS_REGEX}"
      ph = html.match(regex).to_s
      # substitute only if a placeholder matches
      unless ph.blank?
        #begin
          opts = ph.match(TEMPLATES_PLACEHOLDER_OPTIONS_REGEX)[1].split("|")
          fields = opts[0].blank? ? nil : opts[0].split(",").map{|o| o.strip.to_sym unless o.blank?}.select{|o| ! o.nil?}
          order  = (opts[1].blank? ? nil : opts[1].strip) if opts.size > 0
          join   = (opts[2].blank? ? :table : opts[2]) if opts.size > 1

          iterator = "build_#{p.downcase}_list(salary, :fields => fields, :order => order, :join => join)"

          # Don't substitute if this relation is empty
          if salary.send(p.downcase).size > 0
            sub = eval iterator
          else
            sub = ""
          end

          html.gsub!(ph, sub)
        #rescue Exception => e
        #  error = I18n.t("invoice_template.views.errors.failed_to_substitute_iterator", :iterator => p)
        #  error += "<br />"
        #  error += CGI::escapeHTML(e.inspect)
        #  html.gsub!(ph, error)
        #end
      end
    end

    html
  end

  ##
  # Returns a list of taxed items for a given salary.
  #
  # Available options:
  #
  # *fields*:: <tt>+id, position, title, value, category, created_at+</tt>
  # *order*::  <tt>+any available attributes</tt>
  # *joins*::  <tt>+:table+, any kind of string as separator, like ", "</tt>
  #
  def build_taxed_items_list(salary, options = {})
    defaults = {:fields => ['id', 'position', 'title', 'value', 'category', 'created_at'],
                :order  => 'position ASC',
                :join  => :table }

    defaults.each{|k,v| options[k] = v if options[k].blank? }

    html = ""

    if options[:join].to_s.strip == 'table'
      html << render_to_string( :partial => 'taxed_items.html',
                                :locals => {:salary => salary,
                                            :options => options})
    else
      salary.taxed_items.order(options[:order]).each do |s|
        fields = options[:fields].map do |f|
          field = s.send(f)
          field = field.to_date if field.is_a? Time
          field = field.to_view if field.is_a? Money
          field.to_s
        end
        html << fields.join(options[:join]) + "<br />"
      end
    end

    html
  end


  ##
  # Returns the list of taxes for a given salary.
  #
  # Available options:
  #
  # *fields*:: <tt>+id, salary_id, tax_id, title, position, employer_value,
  # employer_percent, employer_use_percent, employee_value, employee_percent,
  # employee_use_percent, created_at, updated_at+</tt>
  # *order*::  <tt>+any available attributes</tt>
  # *joins*::  <tt>+:table+, any kind of string as separator, like ", "</tt>
  #
  def build_tax_data_list(salary, options = {})
    defaults = {:fields => ['id', 'salary_id', 'tax_id', 'title', 'position',
                            'employer_value', 'employer_percent',
                            'employer_use_percent', 'employee_value',
                            'employee_percent', 'employee_use_percent',
                            'created_at', 'updated_at'],
                :order  => 'position ASC',
                :join  => :table }

    defaults.each{|k,v| options[k] = v if options[k].blank? }

    html = ""

    if options[:join].to_s.strip == 'table'
      html << render_to_string( :partial => 'tax_data.html',
                                :locals => {:salary => salary,
                                            :options => options})
    else
      salary.selected_tax_data.order(options[:order]).each do |s|
        fields = options[:fields].map do |f|
          field = s.send(f)
          field = field.to_date if field.is_a? Time
          field = field.to_view if field.is_a? Money
          field.to_s
        end
        html << fields.join(options[:join]) + "<br />"
      end
    end

    html
  end

  ##
  # Returns a list of untaxed items for a given salary.
  #
  # Available options:
  #
  # *fields*:: <tt>+id, position, title, value, category, created_at+</tt>
  # *order*::  <tt>+any available attributes</tt>
  # *joins*::  <tt>+:table+, any kind of string as separator, like ", "</tt>
  #
  def build_untaxed_items_list(salary, options = {})
    defaults = {:fields => ['id', 'position', 'title', 'value', 'category', 'created_at'],
                :order  => 'position ASC',
                :join  => :table }

    defaults.each{|k,v| options[k] = v if options[k].blank? }

    html = ""

    if options[:join].to_s.strip == 'table'
      html << render_to_string( :partial => 'untaxed_items.html',
                                :locals => {:salary => salary,
                                            :options => options})
    else
      salary.untaxed_items.order(options[:order]).each do |s|
        fields = options[:fields].map do |f|
          field = s.send(f)
          field = field.to_date if field.is_a? Time
          field = field.to_view if field.is_a? Money
          field.to_s
        end
        html << fields.join(options[:join]) + "<br />"
      end
    end

    html
  end

  ##
  # Returns the salary summary as an html table.
  #
  # Available options:
  #
  # *fields*:: <tt>+category, value+ unvariable</tt>
  # *order*::  <tt>+position+ unvariable</tt>
  # *joins*::  <tt>+:table+ only</tt>
  #
  def build_summary_list(salary, options = {})
    defaults = {:fields => ['category', 'value'],
                :order  => 'position ASC',
                :join  => :table }

    defaults.each{|k,v| options[k] = v if options[k].blank? }

    html = render_to_string(:partial => 'summary.html',
                            :locals => {:summary => salary.summary,
                                        :options => options})


    html
  end


end
