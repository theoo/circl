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

class Cleanup::AttachmentsJob < ApplicationJob

  queue_as :cleanup

  def perform(params = nil)
    params || options
    # i18n-tasks-use I18n.t("admin.jobs.cleanup.attachments.title")
    set_status(translation_options: ["admin.jobs.cleanup.attachments.title"])

    # Find old attachment that can be regenerated (like invoices) and remove them to gain some space.
    CachedDocument.erase_outdated_documents
  end

end
