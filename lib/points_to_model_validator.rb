=begin
  CIRCL Directory
  Copyright (C) 2011 Complex IT sàrl

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU Affero General Public License as
  published by the Free Software Foundation, either version 3 of the
  License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Affero General Public License for more details.

  You should have received a copy of the GNU Affero General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end


# validate that record.resource_type is a string representation of a rails model

class PointsToModelValidator < ActiveModel::Validator
  include Reflection

  def initialize(options)
    super
    @validate_me = options[:attr]

  end

  def validate(record)
    record.errors[@validate_me] << I18n.t('common.errors.does_not_point_to_valid_model') unless
      list_model_names.include?(record.send (@validate_me))
  end

end
