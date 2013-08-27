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

BankImportHistory = App.BankImportHistory

class Form extends App.ExtendedController
  events:
    'click input[name="import_bank_import_history"]': 'validate'

  constructor: (params) ->
    super

  validate: (e) ->
    errors = new App.ErrorsList

    file = @el.find('input[type="file"]').val()

    if file.length == 0
      errors.add [I18n.t("common.file"), I18n.t("activerecord.errors.messages.blank")].to_property()

    unless errors.is_empty()
      e.preventDefault()
      @renderErrors(errors.errors)

  render: ->
    @html @view('admin/bank_import_histories/form')(@)
    Ui.load_ui(@el)

  activate: ->
    super
    @render()

class Index extends App.ExtendedController

  constructor: (params) ->
    super
    BankImportHistory.bind('refresh', @render)

  render: =>
    @html @view('admin/bank_import_histories/index')(@)
    Ui.load_ui(@el)

  activate: ->
    super
    @render()

class Export extends App.ExtendedController
  events:
    'click input[name="export_bank_import_history"]': 'validate'

  constructor: (params) ->
    super

  validate: (e) ->
    errors = new App.ErrorsList

    from = @el.find('input[name=from]').val()
    to = @el.find('input[name=to]').val()

    if from.length == 0
      errors.add [I18n.t("common.from"), I18n.t("activerecord.errors.messages.blank")].to_property()
    else
      unless @validate_date_format(from)
        errors.add [I18n.t("common.from"), I18n.t('common.errors.date_must_match_format')].to_property()

    if to.length == 0
      errors.add [I18n.t("common.to"), I18n.t("activerecord.errors.messages.blank")].to_property()
    else
      unless @validate_date_format(to)
        errors.add [I18n.t("common.to"), I18n.t('common.errors.date_must_match_format')].to_property()

    unless errors.is_empty()
      e.preventDefault()
      @renderErrors(errors.errors)

  render: =>
    @html @view('admin/bank_import_histories/export')(@)
    Ui.load_ui(@el)

  activate: ->
    super
    @render()

class App.ImportReceipts extends Spine.Controller
  className: 'adminReceipts'

  constructor: (params) ->
    super

    @new    = new Form
    @index  = new Index
    @export = new Export
    @append(@new, @index, @export)

  activate: ->
    super
    @new.activate()
    @export.activate()
    BankImportHistory.fetch()
