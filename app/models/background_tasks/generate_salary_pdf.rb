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
# == Schema Information
#
# Table name: background_tasks
#
# *id*::         <tt>integer, not null, primary key</tt>
# *type*::       <tt>string(255)</tt>
# *options*::    <tt>text</tt>
# *created_at*:: <tt>datetime</tt>
# *updated_at*:: <tt>datetime</tt>
#--
# == Schema Information End
#++

# Options are: salary_id, :person
class BackgroundTasks::GenerateSalaryPdf < BackgroundTask
  def self.generate_title(options)
    I18n.t("background_task.tasks.generate_salary_pdf",
      :salary_id => options[:salary_id],
      :salary_title => Salary.find(options[:salary_id]).title)
  end

  def process!
    salary = Salaries::Salary.find(options[:salary_id])

    controller = People::Salaries::SalariesController.new
    html = controller.render_to_string( :inline => controller.build_from_template(salary),
                                        :layout => 'pdf.html.haml' )

    html.assets_to_full_path!

    file = Tempfile.new(['salary', '.pdf'], :encoding => 'ascii-8bit')
    file.binmode
    file.write(PDFKit.new(html).to_pdf)
    file.flush
    salary.pdf = file
    salary.save

    # this won't touch updated_at column
    salary.update_column(:pdf_updated_at, Time.now)

    file.unlink
  end
end
