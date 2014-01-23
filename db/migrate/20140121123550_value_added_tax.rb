class ValueAddedTax < ActiveRecord::Migration
  def change
    add_column :invoices, :vat_in_cents, :integer, :null => false, :default => 0
    add_column :invoices, :vat_currency, :string
    add_column :invoices, :vat_percentage, :integer
    add_index :invoices, :vat_in_cents

    add_column :extras, :vat_in_cents, :integer, :null => false, :default => 0
    add_column :extras, :vat_currency, :string
    add_column :extras, :vat_percentage, :integer
    add_index :extras, :vat_in_cents

    add_column :product_variants, :vat_in_cents, :integer, :null => false, :default => 0
    add_column :product_variants, :vat_currency, :string
    add_column :product_variants, :vat_percentage, :integer
    add_index :product_variants, :vat_in_cents

    create_table :currencies do |c|
      c.integer :priority
      c.string  :iso_code, :null => false
      c.string  :iso_numeric
      c.string  :name
      c.string  :symbol
      c.string  :subunit
      c.integer :subunit_to_unit
      c.string  :separator
      c.string  :delimiter
    end
    add_index :currencies, :priority
    add_index :currencies, :iso_code

    create_table :currency_rates do |r|
      c.integer :from_currency_id, :null => false
      c.integer :to_currency_id, :null => false
      c.float   :rate, :null => false
      c.timestamps
    end
    add_index :currency_rates, :from_currency_id
    add_index :currency_rates, :to_currency_id
    add_index :currency_rates, :rate

  end
end
