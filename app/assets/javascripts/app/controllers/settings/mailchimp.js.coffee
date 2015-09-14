#  CIRCL Directory
#  Copyright (C) 2011 Complex IT sàrl
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU Affero General Public License as
#  published by the Free Software Foundation, either version 3 of the
#  License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU Affero General Public License for more details.
#
#  You should have received a copy of the GNU Affero General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

class App.SettingsMailchimp extends Spine.Controller
  className: 'mailchimp'
  events:
    'click button[name="synchronize_mailchimp"]': 'sync'

  sync: (e) ->
    e.preventDefault()

    list_id = @el.find("select#mailchimp_lists").val()
    list_name = @el.find("option[value='#{list_id}']").text()

    query       = new App.QueryPreset
    url         = "#{Spine.Model.host}/directory/#{list_id}/mailchimp"
    title       = I18n.t('settings.views.sync_mailchimp_title', name: list_name)
    message     = I18n.t('settings.views.sync_mailchimp_message')

    Directory.search_with_custom_action query,
      url: url
      title: title
      message: message