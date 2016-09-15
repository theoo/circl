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

class Validators::Interval < ActiveModel::Validator

  # validates that end_interval is a date after start_interval
  def validate(record)
    return if record.interval_starts_on.blank? ||
              record.interval_ends_on.blank? ||
              record.interval_starts_on <= record.interval_ends_on

    record.errors.add(:interval_ends_on, I18n.t('common.errors.end_must_be_after_start'))
  end

end
