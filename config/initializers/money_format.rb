
# TODO load config from application settings
curr = {
  :priority        => 1,
  :iso_code        => "CHF",
  :iso_numeric     => "756",
  :name            => "Swiss franc",
  :symbol          => "",
  :subunit         => "Centime",
  :subunit_to_unit => 100,
  :separator       => ".",
  :delimiter       => "'",
}

Money::Currency.register(curr)

Money.default_currency = Money::Currency.new("CHF")

module MoneyClassExtention
  def to_view
    # TODO load config from application settings
    format(:thousands_separator => "'", :decimal_mark => ".", :with_currency => false)
  end
end

class Money
  include MoneyClassExtention
end