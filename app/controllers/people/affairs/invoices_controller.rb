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

class People::Affairs::InvoicesController < ApplicationController

  layout false

  load_resource :person
  load_resource :affair
  load_and_authorize_resource through: :affair

  monitor_changes :@invoice

  def index
    @affair = Affair.find(params[:affair_id])
    @invoices = @affair.invoices

    if params[:template_id]
      @affair.generic_template = GenericTemplate.find params[:template_id]
    end

    respond_to do |format|
      format.json { render json: @invoices }

      format.csv do
        fields = []
        fields << 'title'
        fields << 'created_at.try(:to_date)'
        fields << 'value'
        fields << 'owner.first_name'
        fields << 'owner.last_name'
        fields << 'owner.full_address'
        fields << 'owner.try(:location).try(:postal_code_prefix)'
        fields << 'owner.try(:location).try(:country).try(:name)'
        fields << 'owner.try(:main_communication_language).try(:name)'
        fields << 'owner.email'
        render inline: csv_ify(@invoices, fields)
      end

      if params[:template_id]
        format.html do
          generator = AttachmentGenerator.new(@affair)
          render inline: generator.html, layout: 'preview'
        end

        format.pdf do
          @pdf = ""
          generator = AttachmentGenerator.new(@affair)
          generator.pdf { |o,pdf| @pdf = pdf.read }
          send_data @pdf,
                    filename: "affair_invoices_#{params[:affair_id]}.pdf",
                    type: 'application/pdf'
        end

        format.odt do
          @odt = ""
          generator = AttachmentGenerator.new(@affair)
          generator.odt { |o,odt| @odt = odt.read }
          send_data @odt,
                    filename: "affair_invoices_#{params[:affair_id]}.odt",
                    type: 'application/vnd.oasis.opendocument.text'
        end
      end
    end
  end

  def show
    respond_to do |format|
      format.json { render json: @invoice }

      # Render HTML but don't build PDF.
      format.html do
        html = build_from_template(@invoice)
        html.assets_to_full_path!
        render inline: html, layout: 'preview'
      end

      # Call Background task to build pdf through invoice model.
      format.pdf do
        unless @invoice.pdf_up_to_date? and File.exist?(@invoice.pdf.path)
          @invoice.update_pdf!
          @invoice.reload
        end
        send_data File.read(@invoice.pdf.path), filename: "invoice_#{params[:id]}.pdf", type: 'application/pdf'
      end
    end
  end

  def create
    @invoice.value = Money.new(params[:value].to_f * 100, params[:value_currency])
    @invoice.vat = Money.new(params[:vat].to_f * 100, params[:value_currency])
    respond_to do |format|
      if @invoice.save
        format.json { render json: @invoice }
      else
        format.json { render json: @invoice.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json { render json: @invoice }
    end
  end

  def update
    @invoice.value = Money.new(params[:value].to_f * 100, params[:value_currency])
    @invoice.vat = Money.new(params[:vat].to_f * 100, params[:value_currency])
    respond_to do |format|
      if @invoice.update_attributes(params[:invoice])
        format.json { render json: @invoice }
      else
        format.json { render json: @invoice.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @invoice.destroy
        format.json { render json: {} }
      else
        format.json { render json: @invoice.errors, status: :unprocessable_entity }
      end
    end
  end

  def search
    if params[:term].blank?
      result = []
    else
      param = params[:term].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes
      result = @invoices.where("invoices.title ~* ?", param)
    end

    respond_to do |format|
      format.json { render json: result.map{|t| {id: t.id, label: t.title}}}
    end
  end

  ##
  # PDF generation
  #

  ##
  # Returns an HTML page (that can be used to build a PDF)
  # with its placeholders substituted.
  #
  def build_from_template(invoice, html = 'html')
    html = invoice.invoice_template.send(html).dup

    # Add bvr if requested
    if invoice.invoice_template.with_bvr
      @invoice_template = invoice.invoice_template
      html << render_to_string("bvr")
    end

    invoice.placeholders[:simples].each do |p, v|
      html.gsub!("##{p}", v) if html.match("#{p}")
    end

    invoice.placeholders[:iterators].each do |p, v|
      regex = "##{p}#{TEMPLATES_PLACEHOLDER_OPTIONS_REGEX}"
      ph = html.match(regex).to_s
      # substitute only if a placeholder matches
      unless ph.blank?
        begin
          opts = ph.match(TEMPLATES_PLACEHOLDER_OPTIONS_REGEX)[1].split("|")
          fields = opts[0].split(",").map{|o| o.strip.to_sym unless o.blank?}.select{|o| ! o.nil?}
          order  = opts[1].strip if opts.size > 0
          join   = opts[2] if opts.size > 1

          iterator = "build_#{p.downcase}_list(invoice, fields: fields, order: order, join: join)"
          # TODO ensure that what is evaluated is safe
          sub = eval iterator

          html.gsub!(ph, sub)
        rescue Exception => e
          error = I18n.t("invoice_template.errors.failed_to_substitute_iterator", iterator: p)
          error += "<br />"
          error += CGI::escapeHTML(e.inspect)
          html.gsub!(ph, error)
         end
      end
    end


    html
  end

  ##
  # Returns subscriptions as an HTML fragment build from the given options.
  #
  # Available options:
  #
  # *fields*:: <tt>+id, parent_id, title, description, 'value', interval_starts_on, interval_ends_on, created_at, updated_at+</tt>
  # *order*::  <tt>+:interval_starts_on+, any available attributes</tt>
  # *joins*::  <tt>+:table+, any kind of string as separator, like ", "</tt>
  #
  def build_subscriptions_list(invoice, options = {})
    defaults = {fields: ['id', 'parent_id', 'title', 'description',
                            'interval_starts_on', 'interval_ends_on',
                            'created_at', 'updated_at', 'value'],
                order: 'interval_starts_on ASC',
                join: :table }

    defaults.each{|k,v| options[k] = v if options[k].blank? }

    html = ""

    if options[:join].to_s.strip == 'table'
      html << render_to_string( partial: 'subscriptions.html',
                                locals: {subscriptions: invoice.subscriptions,
                                            invoice: invoice,
                                            options: options})
    else
      invoice.subscriptions.order(options[:order]).each do |s|
        fields = options[:fields].map do |f|
          if f == :value
            field = value_for(invoice.buyer)
          else
            field = s.send(f)
          end
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
  # Returns services as an HTML fragment build from the given options.
  #
  # Available options:
  #
  # TODO
  #
  # available = ['id', 'executer_name', 'description', 'duration', 'start_date', 'created_at', 'updated_at', 'task_type_title', 'task_type_description', 'task_type_ratio', 'task_type_value', 'value', 'value_in_cents', 'value_currency', 'position']
  def build_tasks_list(invoice, options = {})
    defaults = {fields: ['executer_name', 'task_type_title', 'description', 'start_date', 'duration', 'value'],
                order: 'start_date ASC',
                join: :table }

    defaults.each{|k,v| options[k] = v if options[k].blank? }

    html = ""
    html << build_join_for(invoice, 'tasks', options)
    html
  end

  ##
  # Returns products as an HTML fragment build from the given options.
  #
  # Available options:
  #
  # TODO
  #
  # available = ['id', 'parent_id', 'created_at', 'updated_at', 'key', 'title', 'description', 'category', 'quantity', 'value', 'value_in_cents', 'value_currency']
  def build_product_items_list(invoice, options = {})
    defaults = {fields: ['key', 'title', 'description', 'quantity', 'value'],
                order: 'position ASC',
                join: :table }

    defaults.each{|k,v| options[k] = v if options[k].blank? }

    html = ""
    html << build_join_for(invoice, 'product_items', options)
    html
  end

  ##
  # Returns extras as an HTML fragment build from the given options.
  #
  # Available options:
  #
  # TODO
  #
  # available = ['id', 'title', 'description', 'value', 'value_in_cents', 'value_currency', 'quantity', 'position', 'created_at', 'updated_at']
  def build_extras_list(invoice, options = {})
    defaults = {fields: ['title', 'description', 'quantity', 'value'],
                order: 'position ASC',
                join: :table }

    defaults.each{|k,v| options[k] = v if options[k].blank? }

    html = ""
    html << build_join_for(invoice, 'extras', options)
    html
  end

  ##
  # Returns receipts as an HTML fragment build from the given options.
  #
  # Available options:
  #
  # *fields*:: <tt>+id, invoice_id, value, value_date, means_of_payment, created_at, updated_at</tt>
  # *order*::  <tt>+:interval_starts_on+, any available attributes</tt>
  # *joins*::  <tt>+:table+, any kind of string as separator, like ", "</tt>
  #
  def build_receipts_list(invoice, options = {})
    defaults = {fields: ['id', 'invoice_id', 'value', 'value_date',
                            'means_of_payment', 'created_at', 'updated_at'],
                order: 'value_date ASC',
                join: :table }

    defaults.each{|k,v| options[k] = v if options[k].blank? }

    html = ""
    html << build_join_for(invoice, 'receipts', options)
    html
  end

  ##
  # Returns receipts as an HTML fragment build from the given options.
  #
  # Available options:
  #
  # *fields*:: <tt>+id, invoice_id, value, value_date, means_of_payment, created_at, updated_at</tt>
  # *order*::  <tt>+:interval_starts_on+, any available attributes</tt>
  # *joins*::  <tt>+:table+, any kind of string as separator, like ", "</tt>
  #
  def build_affair_receipts_list(invoice, options = {})
    defaults = {fields: ['id', 'invoice_id', 'value', 'value_date',
                            'means_of_payment', 'created_at', 'updated_at'],
                order: 'value_date ASC',
                join: :table,
                translation_path: 'receipt' }

    defaults.each{|k,v| options[k] = v if options[k].blank? }

    html = ""
    html << build_join_for(invoice, 'affair_receipts', options)
    html
  end


  private

  def build_join_for(invoice, object_name, options)

    raise ArgumentError, "An invoice is required as first parameter." unless invoice.is_a? Invoice

    [:order, :fields, :join].each do |opt|
      raise ArgumentError, "options[:#{opt}] is required." unless options[opt]
    end

    begin
      objects = invoice.send(object_name)
    rescue Exception => e
      raise ArgumentError, "object name: #{object_name} is not a valid method."
    end

    options[:translation_path] ||= object_name.singularize

    html = ""

    # print table or join only if there is objects
    if objects.size > 0
      if options[:join].to_s.strip == 'table'
        html << render_to_string( partial: "generic",
                                  locals: {objects: objects,
                                              object_name: object_name,
                                              options: options})
      else
          objects.order(options[:order]).each do |s|
            fields = options[:fields].map do |f|
              field = s.send(f)
              field = field.to_date if field.is_a? Time
              field = field.to_view if field.is_a? Money
              field.to_s
            end
            html << fields.join(options[:join]) + "<br />"
          end
      end
    end

    html

  end

end
