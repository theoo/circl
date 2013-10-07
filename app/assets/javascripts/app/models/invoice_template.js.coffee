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

class App.InvoiceTemplate extends Spine.Model

  @configure 'InvoiceTemplate', 'title', 'html', 'with_bvr', 'show_invoice_value', 
              'bvr_address', 'bvr_account', 'thumb_url', 'language_id'

  @extend Spine.Model.Ajax
  @url: ->
    "#{Spine.Model.host}/settings/invoice_templates"

  constructor: ->
    super

  validate: ->
    e = new App.ErrorsList

#    if @with_bvr
#      if ! @bvr_address or ! @bvr_account
#        e.add with_bvr: I18n.t('invoice_template.errors.bvr_address_and_bvr_account_are_required_if_with_bvr_is_set')

#      unless @bvr_account.match(/^[0-9]{1,2}-[0-9]{1,6}-[0-9]{1,2}$/)
#        e.add bvr_account: I18n.t('invoice_template.errors.bvr_account_must_match_format')

#    unless @title
#      e.add title: I18n.t("activerecord.errors.messages.blank")

#    unless @html
#      e.add html: I18n.t("activerecord.errors.messages.blank")

    return e unless e.is_empty()
