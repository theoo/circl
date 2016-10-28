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

module InvoicesConcern

  extend ActiveSupport::Concern

  def search
    if params[:term].blank?
      result = []
    else
      if params[:term].is_i?
        result = @invoices.where("invoices.id = ?", params[:term])
      else
        param = params[:term].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes
        result = @invoices.where("invoices.title ~* ?", param)
      end
    end

    result = result.limit(10)

    respond_to do |format|
      format.json do
        render json: result.map{|t|
          desc = t.try(:owner).try(:name)
          desc += "<br />" + t.description.exerpt unless t.description.blank?

          { id: t.id,
            title: t.id.to_s,
            label: t.title,
            desc: desc }}
      end
    end
  end

end