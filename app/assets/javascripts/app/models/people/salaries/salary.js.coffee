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

class App.PersonSalary extends Spine.Model

  @configure 'PersonSalary', 'parent_id', 'person_id', 'generic_template_id',
             'activity_rate', 'from', 'to', 'title', 'is_reference',
             'married', 'children_count', 'yearly_salary', 'yearly_salary_count',
             'paid', 'brut_account', 'net_account', 'employer_account', 'created_at'

  @extend Spine.Model.Ajax

  @url: ->
    undefined

  constructor: ->
    @items = []
    @tax_data = []
    @summary = []
    super

  @references: ->
    (r for r in @all() when r.is_reference)

  @instances: ->
    (s for s in @all() when !s.is_reference)
