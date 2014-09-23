class AddVatPercentageToAffairs < ActiveRecord::Migration
  def change
    add_column :affairs, :vat_percentage, :float
    add_column :affairs, :vat_in_cents, :integer, :null => false, :default => 0
    add_column :affairs, :vat_currency, :string, :null => false, :default => "CHF"

    add_index :affairs, :vat_percentage
    add_index :affairs, :vat_in_cents
    add_index :affairs, :vat_currency
  end
end
