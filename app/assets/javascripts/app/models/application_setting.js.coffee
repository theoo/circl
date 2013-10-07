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

class App.ApplicationSetting extends Spine.Model

  @configure 'ApplicationSetting', 'key', 'value'

  @extend Spine.Model.Ajax
  @url: ->
    "#{Spine.Model.host}/settings/application_settings"

  constructor: ->
    super

  validate: ->
    e = new App.ErrorsList

#    unless @key
#      e.add key: I18n.t("activerecord.errors.messages.blank")

#    unless @value
#      e.add value: I18n.t("activerecord.errors.messages.blank")

    return e unless e.is_empty()

  @value: (key) ->
   (a.value for a in @all() when a.key == key)[0]
