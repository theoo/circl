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