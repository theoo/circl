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

# TODO apply money instead of composed_of to every models
module MoneyComposer
  def money(name, cents_attr = nil, currency_attr = nil)
    cents_attr     ||= name.to_s + "_in_cents"
    currency_attr ||= name.to_s + "_currency"

    # FIXME: Will be obsolete in Rails 4
    composed_of name,
      :class_name => 'Money',
      :mapping => [[cents_attr, "cents"], [currency_attr, "currency_as_string"]],
      :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
      :converter => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }
  end
end