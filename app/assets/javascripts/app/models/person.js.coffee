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

class App.Person extends Spine.Model

  @configure 'Person', 'name', 'job_name', 'job_id', 'location_name', 'location_id',
    'main_communication_language_id', 'communication_language_ids',
    'is_an_organization', 'organization_name', 'title', 'first_name', 'last_name',
    'phone', 'second_phone', 'mobile', 'email', 'second_email', 'postal_code', 'fax_number',
    'address', 'birth_date', 'nationality', 'avs_number', 'bank_informations',
    'generate_authentication_token', 'errors', 'hidden', 'alias_name',
    'created_at', 'task_rate_id', 'latitude', 'longitude', 'gender', 'website',
    'creditor_transitional_account', 'creditor_account'

  @extend Spine.Model.Ajax
  @url: ->
    "#{Spine.Model.host}/people"

  constructor: ->
    @is_an_organization = @hidden = false
    super
