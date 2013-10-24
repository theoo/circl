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

class App.Receipt extends Spine.Model

  @configure 'Receipt', 'id', 'invoice_id', 'invoice_title', 'affair_id',
  	'affair_title', 'owner_id', 'owner_name', 'subscription_id',
  	'subscription_title', 'means_of_payment', 'value', 'value_date',
  	'invoice_template_id', 'created_at'

  @extend Spine.Model.Ajax

  @url: ->
    "#{Spine.Model.host}/admin/receipts"

  constructor: ->
    super

  validate: (e) ->
    # e = new App.ErrorsList

    # unless @owner_id
    #   e.add owner: I18n.t("receipt.validations.owner_required")

    # if ! @subscription_id and ! @affair_id
    #   e.add subscription: I18n.t("activerecord.errors.messages.blank")

    # unless @value_date
    #   e.add value_date: I18n.t("activerecord.errors.messages.blank")

    # unless @value
    #   e.add value: I18n.t("activerecord.errors.messages.blank")

    #  return e unless e.is_empty()
