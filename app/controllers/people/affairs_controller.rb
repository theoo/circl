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

class People::AffairsController < ApplicationController

  include ControllerExtensions::Affairs

  layout false

  load_resource :person
  load_and_authorize_resource through: :person

  monitor_changes :@affair

  def index
    respond_to do |format|
      format.json do
        render json: PersonAffairsDatatable.new(view_context, @person)
      end
    end
  end

  def show

    if params[:template_id]
      @affair.template = GenericTemplate.find params[:template_id]
    end

    respond_to do |format|
      format.json { render json: @affair }

      format.html do
        generator = AttachmentGenerator.new(@affair)
        render inline: generator.html, layout: 'preview'
      end

      format.pdf do
        @pdf = ""
        generator = AttachmentGenerator.new(@affair)
        generator.pdf { |o,pdf| @pdf = pdf.read }
        send_data @pdf,
                  filename: "affair_#{params[:id]}.pdf",
                  type: 'application/pdf'
      end

      format.odt do
        @odt = ""
        generator = AttachmentGenerator.new(@affair)
        generator.odt { |o,odt| @odt = odt.read }
        send_data @odt,
                  filename: "affair_#{params[:id]}.odt",
                  type: 'application/vnd.oasis.opendocument.text'
      end
    end

  end

  def create
    success = false
    parent_ids = {}
    @parent = Affair.find params[:parent_id] if not params[:copy_parent].blank? and not params[:parent_id].blank?

    Affair.transaction do
      @affair.value = Money.new(params[:value].to_f * 100, params[:value_currency])
      @affair.vat = Money.new(params[:vat].to_f * 100, params[:value_currency])

      # raise the error and rollback transaction if validation fails
      raise ActiveRecord::Rollback unless @affair.save

      # append stakeholders
      unless params[:affairs_stakeholders].blank?
        params[:affairs_stakeholders].each do |s|
          stakeholder = @affair.affairs_stakeholders.new(
            person_id: s[:person_id],
            title: s[:title] )
          unless stakeholder.save
            stakeholder.errors.messages.each do |k,v|
              @affair.errors.add(("stakeholders[][" + k.to_s + "]").to_sym, v.join(", "))
            end
            raise ActiveRecord::Rollback
          end
        end
      end

      # Copy tasks, products, extras and subscriptions if it has a parent.
      if @parent
        @parent.tasks.each do |t|
          nt = t.dup
          nt.affair = @affair
          raise ActiveRecord::Rollback unless nt.save
          nt
        end

        @parent.product_items.each do |t|
          nt = t.dup
          nt.affair = @affair

          # Create category if not existing or select it
          if @affair.product_categories.where(title: t.category.title).count == 0
            cat = @affair.product_categories.create!(title: t.category.title, position: t.category.position)
          else
            cat = @affair.product_categories.where(title: t.category.title).first
          end

          nt.category = cat
          raise ActiveRecord::Rollback unless nt.save
          # Require to prevent removal of unused categories, it reloads product_items
          @affair.reload
          parent_ids[t.id] = nt.id
          nt
        end
        @affair.product_items.where("parent_id is not null").each do |t|
          unless t.update_attributes(parent_id: parent_ids[t.parent_id])
            raise ActiveRecord::Rollback
          end
        end

        @parent.extras.each do |t|
          nt = t.dup
          nt.affair = @affair
          raise ActiveRecord::Rollback unless nt.save
          nt
        end

        # HABTM
        @affair.subscriptions = @parent.subscriptions

        @affair.value = @parent.value
        @affair.vat = @parent.vat

      end

      success = @affair.save

    end # transaction

    respond_to do |format|
      if success
        format.json { render json: @affair }
      else
        format.json { render json: @affair.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json { render json: @affair }
    end
  end

  def update

    success = false

    Affair.transaction do
      # remove parent if not sent
      params[:parent_id] = nil if ! params[:parent_id] or ! params[:parent_name]

      # raise the error and rollback transaction if validation fails
      raise ActiveRecord::Rollback unless @affair.update_attributes(params[:affair])

      # Only keep values that are returned
      if params[:affairs_stakeholders].blank?
        sent_ids = []
      else
        sent_ids = params[:affairs_stakeholders].map{|v| v[:id].to_i}
      end

      recorded_ids = @affair.affairs_stakeholders.map(&:id)
      surplus_values = recorded_ids - sent_ids
      AffairsStakeholder.destroy surplus_values

      @affair.created_at = Time.now if params[:created_at].blank?

      # and append or update stakeholders
      unless params[:affairs_stakeholders].blank?
        params[:affairs_stakeholders].each do |s|
          if @affair.affairs_stakeholders.exists?(s[:id])
            stakeholder = @affair.affairs_stakeholders.find(s[:id])
            stakeholder.person_id = s[:person_id]
            stakeholder.title = s[:title]
          else
            stakeholder = @affair.affairs_stakeholders.new(
              person_id: s[:person_id],
              title: s[:title] )
          end

          unless stakeholder.save
            stakeholder.errors.messages.each do |k,v|
              @affair.errors.add(("stakeholders[][" + k.to_s + "]").to_sym, v.join(", "))
            end
            raise ActiveRecord::Rollback
          end
        end
      end

      @affair.value = Money.new(params[:value].to_f * 100, params[:value_currency])
      @affair.vat = Money.new(params[:vat].to_f * 100, params[:vat_currency])
      # FIXME Why this is required to evaluate correctly the checkbox ? Only this one.
      @affair.custom_value_with_taxes = params[:custom_value_with_taxes]

      success = @affair.save
      @affair.reload # Required to update affairs_stakeholders (?)
    end

    respond_to do |format|
      if success
        format.json { render json: @affair }
      else
        format.json { render json: @affair.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @affair.destroy
        format.json { render json: {} }
      else
        format.json { render json: @affair.errors, status: :unprocessable_entity}
      end
    end
  end

  # Search is in AffairsExtension

  def affairs

    errors, from, to = validate_export_input(params)

    respond_to do |format|

      if errors.empty?
        ######### PREPARE ############

        # fetch affairs corresponding to selected statuses and interval
        if params[:statuses]
          mask = params[:statuses].map(&:to_i).sum
          @affairs = @person.get_affairs_from_status_values(mask)
        else
          @affairs = @person.affairs
        end

        if from and to
          @affairs = @affairs.where("created_at BETWEEN ? AND ?", from, to)
        end

        # exclude affairs for which value is below unit threshold
        if params[:unit_value]
          @affairs = @affairs.reject{|a| a.value < params[:unit_value]}
        end

        # exclude affairs for which overpaid value is below unit threshold
        if params[:unit_overpaid]
          @affairs = @affairs.reject{|a| a.overpaid_value < params[:unit_overpaid]}
        end

        @affairs.uniq!

        # Ensure at least a template is given

        if params[:format] != 'csv'
          # build generator using selected generic template
          fake_object = OpenStruct.new
          fake_object.template = GenericTemplate.find params[:generic_template_id]
          fake_object.person = @person
          fake_object.affairs = @affairs

          generator = AttachmentGenerator.new(fake_object, nil)
        end

        ######### RENDER ############

        format.json do
          render json: @affairs
        end

        format.csv do
          fields = []
          fields << 'id'
          fields << 'owner_id'
          fields << 'owner.try(:name)'
          fields << 'buyer_id'
          fields << 'buyer.try(:name)'
          fields << 'receiver_id'
          fields << 'receiver.try(:name)'
          fields << 'title'
          fields << 'description'
          fields << 'value'
          fields << 'overpaid_value'
          fields << 'get_statuses.join(", ")'
          fields << 'created_at'
          fields << 'updated_at'
          render inline: csv_ify(@affairs, fields)
        end

        format.pdf do
          send_data generator.pdf,
            filename: "person_#{@person.id}_affairs.pdf",
            type: 'application/pdf'
        end

        format.odt do
          send_data generator.odt,
            filename: "person_#{@person.id}_affairs.odt",
            type: 'application/vnd.oasis.opendocument.text'
        end

      else
        format.json do
          render json: errors, status: :unprocessable_entity
        end
      end
    end
  end

  def invoices

    errors, from, to = validate_export_input(params)

    respond_to do |format|

      if errors.empty?
        ######### PREPARE ############

        # fetch affairs corresponding to selected statuses and interval
        if params[:statuses]
          mask = params[:statuses].map(&:to_i).sum
          @invoices = @person.get_invoices_from_status_values(mask)
        else
          @invoices = @person.invoices
        end

        @invoices.order(:affair_id, :created_at)

        if from and to
          @invoices = @invoices.where("created_at BETWEEN ? AND ?", from, to)
        end

        # exclude invoices for which value is below unit threshold
        if params[:unit_value]
          @invoices = @invoices.reject{|a| a.value < params[:unit_value]}
        end
        if params[:global_value]
          @invoices = @invoices.reject{|a| a.affair.value < params[:global_value]}
        end

        # exclude invoices for which overpaid value is below unit threshold
        if params[:unit_overpaid]
          @invoices = @invoices.reject{|a| a.overpaid_value < params[:unit_overpaid]}
        end
        if params[:global_overpaid]
          @invoices = @invoices.reject{|a| a.affair.overpaid_value < params[:global_overpaid]}
        end

        @invoices.uniq!

        # Ensure at least a template is given

        if params[:format] != 'csv'
          # build generator using selected generic template
          fake_object = OpenStruct.new
          fake_object.template = GenericTemplate.find params[:generic_template_id]
          fake_object.person = @person
          fake_object.invoices = @invoices

          generator = AttachmentGenerator.new(fake_object, nil)
        end

        ######### RENDER ############

        format.json do
          render json: @invoices
        end

        format.csv do
          fields = []
          fields << 'id'
          fields << 'affair_id'
          fields << 'affair.try(:title)'
          fields << 'affair.try(:buyer).try(:id)'
          fields << 'affair.buyer.try(:name)'
          fields << 'title'
          fields << 'description'
          fields << 'printed_address'
          fields << 'value'
          fields << 'overpaid_value'
          fields << 'get_statuses.join(", ")'
          fields << 'invoice_template_id'
          fields << 'created_at'
          fields << 'updated_at'
          render inline: csv_ify(@invoices, fields)
        end

        format.pdf do
          send_data generator.pdf,
            filename: "person_#{@person.id}_invoices.pdf",
            type: 'application/pdf'
        end

        format.odt do
          send_data generator.odt,
            filename: "person_#{@person.id}_invoices.odt",
            type: 'application/vnd.oasis.opendocument.text'
        end

      else
        format.json do
          render json: errors, status: :unprocessable_entity
        end
      end
    end
  end

  def receipts

    errors, from, to = validate_export_input(params)

    respond_to do |format|

      if errors.empty?
        ######### PREPARE ############
        @receipts = @person.receipts.order(:invoice_id, :value_date)

        if from and to
          @receipts = @receipts.where("value_date BETWEEN ? AND ?", from, to)
        end

        # exclude receipts for which value is below unit threshold
        if params[:unit_value]
          @receipts = @receipts.reject{|a| a.value < params[:unit_value]}
        end

        if params[:global_value]
          @receipts = @receipts.reject{|a| a.invoice.receipts_value < params[:global_value]}
        end

        # exclude receipts for which overpaid value is below unit threshold
        if params[:unit_overpaid]
          @receipts = @receipts.reject{|a| a.overpaid_value < params[:unit_overpaid]}
        end

        if params[:global_overpaid]
          @receipts = @receipts.reject{|a| a.invoice.overpaid_value < params[:global_overpaid]}
        end

        @receipts.uniq!

        # Ensure at least a template is given

        if params[:format] != 'csv'
          # build generator using selected generic template
          fake_object = OpenStruct.new
          fake_object.template = GenericTemplate.find params[:generic_template_id]
          fake_object.person = @person
          fake_object.receipts = @receipts

          generator = AttachmentGenerator.new(fake_object, nil)
        end

        ######### RENDER ############

        format.json do
          render json: @receipts
        end

        format.csv do
          fields = []
          fields << 'id'
          fields << 'invoice_id'
          fields << 'invoice.try(:title)'
          fields << 'invoice.try(:affair_id)'
          fields << 'invoice.try(:affair).try(:title)'
          fields << 'invoice.try(:affair).try(:buyer_id)'
          fields << 'invoice.try(:affair).try(:buyer).try(:name)'
          fields << 'value'
          fields << 'overpaid_value'
          fields << 'value_date'
          fields << 'means_of_payment'
          fields << 'created_at'
          fields << 'updated_at'
          render inline: csv_ify(@receipts, fields)
        end

        format.pdf do
          send_data generator.pdf,
            filename: "person_#{@person.id}_receipts.pdf",
            type: 'application/pdf'
        end

        format.odt do
          send_data generator.odt,
            filename: "person_#{@person.id}_receipts.odt",
            type: 'application/vnd.oasis.opendocument.text'
        end

      else
        format.json do
          render json: errors, status: :unprocessable_entity
        end
      end
    end
  end

  def count
    respond_to do |format|
      format.json { render json: {count: @person.affairs.count} }
    end
  end

  private

  def validate_export_input(params)
    errors = {}
    # pseudo validation
    unless params[:from].blank?
      if validate_date_format(params[:from])
        from = Date.parse params[:from]
      else
        errors[:from] = I18n.t("affair.errors.wrong_date")
      end
    end

    unless params[:to].blank?
      if validate_date_format(params[:to])
        to = Date.parse params[:to]
      else
        errors[:to] = I18n.t("affair.errors.wrong_date")
      end
    end

    if from and to and from > to
      errors[:from] = I18n.t("salary.errors.from_date_should_be_before_to_date")
    end

    if params[:format] != 'csv'
      unless params[:generic_template_id]
        errors[:generic_template_id] = I18n.t("activerecord.errors.messages.blank")
      end
    end

    [errors, from, to]
  end

end
