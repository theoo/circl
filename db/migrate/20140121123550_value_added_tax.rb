class ValueAddedTax < ActiveRecord::Migration
  def change
    add_column :invoices, :vat_in_cents, :integer, :null => false, :default => 0
    add_column :invoices, :vat_currency, :string
    add_column :invoices, :vat_perthousand, :integer

    add_column :extras, :vat_in_cents, :integer, :null => false, :default => 0
    add_column :extras, :vat_currency, :string
    add_column :extras, :vat_perthousand, :integer

    add_column :product_variants, :vat_in_cents, :integer, :null => false, :default => 0
    add_column :product_variants, :vat_currency, :string
    add_column :product_variants, :vat_perthousand, :integer
  end
end
