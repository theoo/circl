
Currency.all.each do |curr|
  h = curr.attributes.symbolize_keys
  h.delete(:id)
  # h.symbol = "" # Workaround to remove currency symbol in to_view
  Money::Currency.register(h)
end

Money.default_currency = Money::Currency.new(ApplicationSetting.value("default_currency"))

module MoneyClassExtention
  def to_view
    default_currency = Currency.where(:iso_code => ApplicationSetting.value("default_currency")).first
    format(:thousands_separator => default_currency.separator,
      :decimal_mark => default_currency.delimiter,
      :with_currency => false)
  end
end

class Money
  include MoneyClassExtention
end