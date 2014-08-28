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

# require turbolinks
#= require jquery
#= require jquery-ujs
#= require jquery.cookie
#= require jquery.iframe-transport
#= require jquery_serialize_object
# require jquery.turbolinks
#
#= require extensions
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
#= require ./flot/jquery.flot
#= require ./flot/jquery.flot.categories
#= require ./flot/jquery.flot.tooltip

$ = jQuery

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

  # Reveal content
  $("body").css('margin-left': 0)
  $("body").animate({opacity: 1}, 500)