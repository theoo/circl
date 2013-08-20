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

class FullNameValidator < ActiveModel::Validator


  def validate(record)
    return if record.first_name.blank? && record.last_name.blank?

    if first_name_valid_for(record) && !last_name_valid_for(record)
      record.errors[:last_name] << I18n.t('common.errors.must_provide_last_name_if_first_name')
    end

    if last_name_valid_for(record) && !first_name_valid_for(record)
      record.errors[:first_name] << I18n.t('common.errors.must_provide_first_name_if_last_name')
    end

  end


private
  def first_name_valid_for(record)
    !record.first_name.blank?
  end

  def last_name_valid_for(record)
    !record.last_name.blank?
  end

end
