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

class Salaries::PdfJob < ApplicationJob

  queue_as :documents

  def perform(params = nil)
    # Resque::Plugins::Status options
    params ||= options
    # i18n-tasks-use I18n.t("salaries.jobs.pdf.title")
    set_status(translation_options: ["salaries.jobs.pdf.title"])

    validates(params, [:salary_id])

    @salary = Salaries::Salary.find(@salary_id)
    generator = AttachmentGenerator.new(@salary)

    generator.pdf do |o, pdf|
      o.update_attributes pdf: pdf

      # this won't touch updated_at column and thereby set PDF as uptodate
      o.update_column(:pdf_updated_at, Time.now)
    end

  end

end
