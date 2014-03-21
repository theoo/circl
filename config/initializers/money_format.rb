class Money
  module Bank
    class InvalidCache < StandardError ; end

    class CurrenciesConverter < Money::Bank::VariableExchange

      def update_rates
        Object::Currency.all.each do |c|
          next unless Money::Currency.find(c.iso_code)
          Object::Currency.where("iso_code != ?", c.iso_code).each do |o|
            next unless Money::Currency.find(o.iso_code)
            rate = CurrencyRate.where(:from_currency_id => c.id, :to_currency_id => o.id).first
            set_rate(c.iso_code, o.iso_code, rate.rate) if rate
          end
        end
      end

      def save_rates
      end

      def exchange(cents, from_currency, to_currency)
        exchange_with(Money.new(cents, from_currency), to_currency)
      end

      def exchange_with(from, to_currency)
        return from if same_currency?(from.currency, to_currency)

        rate = get_rate(from.currency, to_currency)

        unless rate
          raise(Money::Bank::UnknownRateFormat, "No conversion rate known for '#{from.currency.iso_code}' -> '#{to_currency}'")
        end

        Money.new(((Money::Currency.wrap(to_currency).subunit_to_unit.to_f / from.currency.subunit_to_unit.to_f) * from.cents * rate).round, to_currency)

      end

    end
  end
end

if ActiveRecord::Base.connection.table_exists? 'currencies'

  # Load Currencies

  Currency.all.each do |curr|
    h = curr.attributes.symbolize_keys
    h.delete(:id)
    h[:decimal_mark] = curr.delimiter
    h[:thousands_separator] = curr.separator
    Money::Currency.register(h)
  end

  Money.default_currency = Money::Currency.new(ApplicationSetting.value("default_currency"))

  module MoneyClassExtention
    def to_view
      #default_currency = Money.default_currency
      #format(:thousands_separator => default_currency.separator,
      #  :decimal_mark => default_currency.delimiter,
      #  :with_currency => false)
      format
    end

    # Force currency to default currency
    def to_doc
      m = exchange_to(Money.default_currency.iso_code)

      format(:thousands_separator => Money.default_currency.delimiter,
        :decimal_mark => Money.default_currency.separator,
        :symbol => '')
    end
  end

  class Money
    include MoneyClassExtention
  end

  # Currencies conversion

  bank = Money::Bank::CurrenciesConverter.new
  bank.update_rates
  Money.default_bank = bank

else
  puts "Missing Currency object, please run 'rake db:upgrade'"
end
