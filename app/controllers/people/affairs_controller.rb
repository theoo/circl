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

  layout false

  load_resource :person
  load_and_authorize_resource :through => :person

  monitor_changes :@affair

  def index
    @affairs = Affair.where("owner_id = ? OR buyer_id = ? OR receiver_id = ?", *([@person.id]*3)).uniq

    respond_to do |format|
      format.json do
        render :json => @affairs
      end
    end
  end

  def show
    edit
  end

  def create
    respond_to do |format|
      if @affair.save
        format.json { render :json => @affair }
      else
        format.json { render :json => @affair.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    respond_to do |format|
      format.json { render :json => @affair }
    end
  end

  def update
    respond_to do |format|
      if @affair.update_attributes(params[:affair])
        format.json { render :json => @affair }
      else
        format.json { render :json => @affair.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if @affair.destroy
        format.json { render :json => {} }
      else
        format.json { render :json => @affair.errors, :status => :unprocessable_entity}
      end
    end
  end

  def search
    if params[:term].blank?
      result = []
    else
      param = params[:term].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes
      result = @affairs.where("affairs.title ~* ?", param)
    end

    respond_to do |format|
      format.json { render :json => result.map{|t| {:id => t.id, :label => t.title}}}
    end
  end

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
          fake_object.generic_template = GenericTemplate.find params[:generic_template_id]
          fake_object.person = @person
          fake_object.affairs = @affairs

          generator = AttachmentGenerator.new(fake_object, nil)
        end

        ######### RENDER ############

        format.json do
          render :json => @affairs
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
          render :inline => csv_ify(@affairs, fields)
        end

        format.pdf do
          send_data generator.pdf,
            :filename => "person_#{@person.id}_affairs.pdf",
            :type => 'application/pdf'
        end

        format.odt do
          send_data generator.odt,
            :filename => "person_#{@person.id}_affairs.odt",
            :type => 'application/vnd.oasis.opendocument.text'
        end

      else
        format.json do
          render :json => errors, :status => :unprocessable_entity
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
          fake_object.generic_template = GenericTemplate.find params[:generic_template_id]
          fake_object.person = @person
          fake_object.invoices = @invoices

          generator = AttachmentGenerator.new(fake_object, nil)
        end

        ######### RENDER ############

        format.json do
          render :json => @invoices
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
          render :inline => csv_ify(@invoices, fields)
        end

        format.pdf do
          send_data generator.pdf,
            :filename => "person_#{@person.id}_invoices.pdf",
            :type => 'application/pdf'
        end

        format.odt do
          send_data generator.odt,
            :filename => "person_#{@person.id}_invoices.odt",
            :type => 'application/vnd.oasis.opendocument.text'
        end

      else
        format.json do
          render :json => errors, :status => :unprocessable_entity
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
          fake_object.generic_template = GenericTemplate.find params[:generic_template_id]
          fake_object.person = @person
          fake_object.receipts = @receipts

          generator = AttachmentGenerator.new(fake_object, nil)
        end

        ######### RENDER ############

        format.json do
          render :json => @receipts
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
          render :inline => csv_ify(@receipts, fields)
        end

        format.pdf do
          send_data generator.pdf,
            :filename => "person_#{@person.id}_receipts.pdf",
            :type => 'application/pdf'
        end

        format.odt do
          send_data generator.odt,
            :filename => "person_#{@person.id}_receipts.odt",
            :type => 'application/vnd.oasis.opendocument.text'
        end

      else
        format.json do
          render :json => errors, :status => :unprocessable_entity
        end
      end
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
