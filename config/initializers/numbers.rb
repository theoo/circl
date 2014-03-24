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
