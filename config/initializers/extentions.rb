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

module NilClassExtension

  def to_datepicker
    ""
  end

  def round
    0
  end

  # many models use the attr value, it's a shortcut for listings helper
  def value
    nil
  end

  def title

  end

end

class NilClass
  include NilClassExtension
end

module StringExtension
  def is_i?
     /^[-+]?\d+$/ === self
  end

  def exerpt(number_of_chars = 250)
    if self.size > number_of_chars
      self[0..number_of_chars] + " (...)"
    else
      self
    end
  end

  def valid_json?
    begin
      JSON.parse(self).symbolize_keys
    rescue JSON::ParserError => e
      false
    end
  end
end

class String
  include StringExtension
end

module ArrayClassExtension

  # expect a bidimentional array
  def to_csv
    CSV.generate do |csv|
      self.each do |line|
        if line.is_a? Array
          csv << line
        else
          csv << line.to_a
        end
      end
    end
  end

end

class Array
  include ArrayClassExtension
end

module IntegerExtension
  def mod10rec
        code = [ 0, 9, 4, 6, 8, 2, 7, 1, 3, 5 ]
        num = 0
        self.to_s.each_char do |char|
            num = code[ (num + char.to_i) % 10 ]
        end
        return (10 - num) % 10
  end
end

class Integer
  include IntegerExtension
end

module FloatExtension
  def to_doc
    self.to_i == self ? self.to_i : self
  end
end

class Float
  include FloatExtension
end
