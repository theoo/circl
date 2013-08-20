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

class App.PersonAffairReceipt extends Spine.Model

  @configure 'PersonAffairReceipt', 'invoice_id', 'invoice_title', 'invoice_pool_title', 'means_of_payment', 'value', 'value_date', 'created_at'

  @extend Spine.Model.Ajax

  constructor: ->
    super

  validate: ->
    errors = new App.ErrorsList

    if @invoice_id.length == 0
      errors.add [I18n.t("receipt.views.invoice_title"), I18n.t("activerecord.errors.messages.blank")].to_property()

    if @value.length == 0
      errors.add [I18n.t("receipt.views.value"), I18n.t("activerecord.errors.messages.blank")].to_property()

    if @value_date.length == 0
      errors.add [I18n.t("receipt.views.value_date"), I18n.t("activerecord.errors.messages.blank")].to_property()
    else
      unless Ui.validate_date_format(@value_date)
        errors.add [I18n.t("receipt.views.value_date"), I18n.t('common.errors.date_must_match_format')].to_property()

    return errors unless errors.is_empty()
