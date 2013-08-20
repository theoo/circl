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

class App.SalaryTaxData extends Spine.Model

  @configure 'SalaryTaxData', 'salary_id', 'tax_id', 'position',
                              'employer_value_in_cents', 'employer_percent', 'employer_use_percent',
                              'employee_value_in_cents', 'employee_percent', 'employee_use_percent', 'visible'

  @extend Spine.Model.Ajax

  constructor: ->
    super
