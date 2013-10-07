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

class App.PersonEmploymentContract extends Spine.Model

  @configure 'PersonEmploymentContract', 'interval_starts_on', 'interval_ends_on', 'percentage', 'description'

  @extend Spine.Model.Ajax

  constructor: ->
    super

  validate: ->
    e = new App.ErrorsList

    # TODO: Check it's a valid date.
#    unless @interval_starts_on
#      e.add interval_starts_on: I18n.t("activerecord.errors.messages.blank")

#    unless @interval_ends_on
#      e.add interval_ends_on: I18n.t("activerecord.errors.messages.blank")

#    unless @percentage
#      e.add percentage: I18n.t("activerecord.errors.messages.blank")

#    unless _.isNumber(parseInt(@percentage))
#      e.add percentage: I18n.t("activerecord.errors.messages.not_a_number")

#    unless @description
#      e.add description: I18n.t("activerecord.errors.messages.blank")

    return e unless e.is_empty()
