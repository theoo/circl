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
    respond_to do |format|
      format.json do
        render :json => @affairs
        @affairs = Affair.where("owner_id = ? OR buyer_id = ? OR receiver_id = ?", *([@person.id]*3)).uniq
      end

      format.pdf do
        generator, errors = prepare_attachment(params)
        send_data generator.pdf,
          :filename => "person_#{@person.id}_affairs.pdf",
          :type => 'application/pdf'
      end

      format.odt do
        generator, errors = prepare_attachment(params)
        send_data generator.odt,
          :filename => "person_#{@person.id}_affairs.odt",
          :type => 'application/vnd.oasis.opendocument.text'
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
      result = @affairs.where("affairs.title #{SQL_REGEX_KEYWORD} ?", param)
    end

    respond_to do |format|
      format.json { render :json => result.map{|t| {:id => t.id, :label => t.title}}}
    end
  end

  private

  def prepare_attachment(params)
    errors = {}

    # pseudo validation
    if validate_date_format(params[:from])
      from = Date.parse params[:from]
    else
      errors[:from] = I18n.t("affair.errors.wrong_date")
    end

    if validate_date_format(params[:to])
      to = Date.parse params[:to]
    else
      errors[:to] = I18n.t("affair.errors.wrong_date")
    end

    # fetch affairs corresponding to selected statuses and interval
    if params[:statuses]
      mask = params[:statuses].map(&:to_i).sum
      affairs = @person.get_affairs_from_status_values(mask)
    else
      affairs = @person.affairs
    end

    if from and to
      affairs = affairs.joins(:receipts)
        .where("receipts.value_date BETWEEN ? AND ?", from, to)
    end

    # exclude affairs which are below threshold
    affairs = affairs.reject{|a| a.overpaid_value < params[:value]}

    affairs.uniq!

    # Build a Struct of affairs with receipts corresponding to the selection
    #affairs = affairs.map do |a|
    #  h = a.attributes

    #  if from and to
    #    h[:receipts] = a.receipts
    #      .where("receipts.value_date BETWEEN ? AND ?", from, to)
    #    h[:invoices] = a.invoices
    #      .joins(:receipts)
    #      .where("receipts.id IN (?)", h[:receipts].map(&:id))
    #      .uniq
    #  else
    #    h[:receipts] = a.receipts
    #    h[:invoices] = a.invoices
    #  end

    #  h[:receipts] = a.receipts.map{|r| OpenStruct.new r.attributes}
    #  h[:invoices] = a.invoices.map{|r| OpenStruct.new r.attributes}
    #  OpenStruct.new h

    #end
    #raise ArgumentError, affairs.inspect

    # generate a pdf using selected generic template
    fake_object = OpenStruct.new
    fake_object.generic_template = GenericTemplate.find params[:generic_template_id]
    fake_object.person = @person
    fake_object.affairs = affairs

    generator = AttachmentGenerator.new(fake_object, nil)

    [generator, errors]
  end

end
