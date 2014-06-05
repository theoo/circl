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
class BackgroundTasks::GenerateGenericTemplateJpg < BackgroundTask
  def self.generate_title(options)
    I18n.t("background_task.tasks.generate_template_jpg",
      generic_template_id: options[:salary_id],
      generic_template_title: GenericTemplate.find(options[:generic_template_id]).title)
  end

  def process!
    generic_template = GenericTemplate.find(options[:generic_template_id])
    generic_template.take_snapshot
  end
end
