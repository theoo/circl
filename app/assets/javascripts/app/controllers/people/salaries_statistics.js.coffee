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

class App.PersonSalariesStatistics extends Spine.Controller

  className: 'salaries_statistics'

  events:
    'change select[name=step]': 'update'

  constructor: (params) ->
    super

    @person_id = params.person_id
    @url = "#{Spine.Model.host}/people/#{@person_id}/salaries/statistics.json"

    # Defaults
    d = new Date
    @params =
      from: "01-01-" + d.getFullYear()
      to: "31-12-" + d.getFullYear()
      step: "month"

    @append(@)

  render: =>
    @html @view('people/salaries/statistics')(@)

    if @data

      stats = @el.find("#person_tasks_stats")

      options =
        legend:
          show: false
        series:
          stack: true
          bars:
            show: true
        bars:
          align: 'center'
          lineWidth: 1
          label: false
        xaxis:
          ticks: []
        yaxis:
          ticks: []
        grid:
          hoverable: true
          borderWidth: 0
          borderColor: null
        tooltip: true
        tooltipOpts:
          content: "%s"

      $.plot(stats, @data, options)


  update: (e) ->
    e.preventDefault()
    @params =
      from: @el.find('input[name=from]').val()
      to: @el.find('input[name=to]').val()
      step: @el.find('select[name=step]').val()

    @fetch()

  fetch: ->
    $.ajax(
      type: "POST"
      url: @url
      data: @params
      dataType: "json"
      )
      .done( (data) =>
        @data = data
        @render()
      )

  activate: ->
    super
    @fetch()
