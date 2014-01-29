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

#= require jquery
#= require jquery-ujs
#= require jquery.cookie
#= require jquery.iframe-transport
#= require jquery_serialize_object
#
#= require jquery-ui
#= require password_strength
#= require jquery.strength
#
#= require bootstrap
#= require bootstrap-slider.js
#
#= require hamlcoffee
#= require app
#= require_tree ./datatables

$ = jQuery

##################
### PROTOTYPING ##
##################

# very simple humanize method...
String.prototype.humanize = ->
  string = @
  string = string.replace(/_/g, " ")
  string = string.substring(0, 1).toUpperCase() + string.substring(1)
  string

Array.prototype.to_property = ->
  hash = {}
  hash[@[0]] = @[1]
  hash

# quick search
$(document).ready ->
  $("form#quick_search").on 'submit', (e) ->
    e.preventDefault()
    search_string = $('form#quick_search input[type=search]').val()
    if(search_string.match(/^\d+$/g) != null)
      window.location = '/people/' + search_string
    else
      Directory.search({ search_string: search_string })

  # This overrides HTML5 behavior which doesn't clear inputs on focus but when typing
  $("#quick_search input[type='search']").on 'focus', (e) ->
    $(e.target).attr('placeholder', '')

  # This resets the placeholder when clicking on the clear button
  $("#quick_search input[type='search']").on 'search', (e) ->
    $(e.target).attr('placeholder', I18n.t('directory.views.quick_search_placeholder'))


Number.prototype.to_view = (num)->
    # this defines currency precision - decimals
    num = @ unless num

    defaults = JSON.parse App.ApplicationSetting.value("default_currency_details")
    thousands_separator = defaults.separator
    decimal_mark = defaults.delimiter
    precision = (defaults.subunit_to_unit + "").match(/0+/)[0].length

    money = num.toFixed(precision)

    # Format money corresponding to currency configuration
    if num >= 1000
      # split the fixed in two
      a = String(money).match(/^(\d+)(.\d{2})$/)
      integers = a[1]
      decimals = a[2]

      # test the length and save remains of the modulo of three
      remaining_digits_length = integers.length % 3
      remaining_digits = integers.slice(0,remaining_digits_length) # from the begining to the index
      thousands = integers.slice(remaining_digits_length) # from the index to the end

      if thousands.length > 3
        thousands = thousands.match(/\d{3}/g)
      else
        thousands = [thousands]

      thousands.splice(0,0,remaining_digits) if remaining_digits_length > 0
      integers_with_separators = thousands.join(thousands_separator)

      money = integers_with_separators + decimals

    return money # as a string

Number.prototype.pad = (length) ->
  str = @ + ""
  while (str.length < length)
    str = "0" + str;
  str.substring(0,2)

# If I dared to write somewhere how javascript sucks that would be here.
Date.prototype.to_view = (date)->
  # TODO localization, check also the rest of the code for localization
  @.getDate().pad(2) + "-" + (@.getMonth() + 1).pad(2) + "-" + @.getFullYear()

String.prototype.to_date = ->
  ary = @.split("-").reverse()
  new Date(parseInt(ary[0]), parseInt(ary[1]) - 1, parseInt(ary[2]))
  "1-1-2013"
