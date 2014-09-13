class VatAsFloat < ActiveRecord::Migration
  def change
    change_column :invoices, :vat_percentage, :float
    change_column :extras, :vat_percentage, :float
  end
end
