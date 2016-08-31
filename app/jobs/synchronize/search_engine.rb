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

class Synchronize::SearchEngine

  @queue = :sync

  include ResqueHelper

  def perform(params = nil)
    # Resque::Plugins::Status options
    params ||= options
    # i18n-tasks-use I18n.t("admin.background_tasks.search_engine.title"))
    set_status(translation_options: ["admin.background_tasks.search_engine.title"])

    required = %i(people_ids)
    validates(params, required)

    people = Person.where(id: people_ids)

    total = people.count
    people.each_with_index do |p, index|
      at(index + 1, total, I18n.t("backgroun_tasks.progress", index: index + 1, total: total))
      person.update_index
    end

    completed(message: ["admin.background_tasks.mailchimp.completed"])

  end

end
