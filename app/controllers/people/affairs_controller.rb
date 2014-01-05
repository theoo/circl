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

        # generate a pdf using selected generic template
        fake_object = OpenStruct.new
        fake_object.generic_template = GenericTemplate.find params[:generic_template_id]
        fake_object.person = @person
        fake_object.affairs = affairs

        generator = AttachmentGenerator.new(fake_object, nil)

        file = Tempfile.new(['affairs_export', '.odt'], :encoding => 'ascii-8bit')
        file.binmode
        generator.pdf {|o, pdf| file.write pdf.read}
        file.flush

        send_data File.read(file),
          :filename => "person_#{@person.id}_affairs.pdf",
          :type => 'application/pdf'

        file.unlink
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

end
