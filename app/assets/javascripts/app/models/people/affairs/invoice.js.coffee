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

class App.PersonAffairInvoice extends Spine.Model

  @configure 'PersonAffairInvoice', 'invoice_template_id', 'affair_id',
             'affair_title', 'title', 'description', 'printed_address', 'value', 'cancelled',
             'owner_id', 'buyer_id', 'receiver_id', 'owner_name', 'buyer_name', 'receiver_name',
             'offered', 'receipts_value', 'balance_value', 'created_at'

  @extend Spine.Model.Ajax

  # URL is defined when loading an affair
  @url: -> undefined

  constructor: ->
    super

  validate: ->
    errors = new App.ErrorsList

#    if @title.length == 0
#      errors.add ['title', I18n.t("activerecord.errors.messages.blank")].to_property()

#    if @value.length == 0
#      errors.add ['value', I18n.t("activerecord.errors.messages.blank")].to_property()

#    if @created_at.length == 0
#      errors.add ['created_at', I18n.t("activerecord.errors.messages.blank")].to_property()
#    else
#      unless Ui.validate_date_format(@created_at)
#        errors.add ['created_at', I18n.t('common.errors.date_must_match_format')].to_property()

    return errors unless errors.is_empty()