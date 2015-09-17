class AddDiscountAccountToPerson < ActiveRecord::Migration
  def change
    add_column :people, :creditor_discount_account, :string

    add_column :creditors, :discount_account, :string
    add_column :creditors, :vat_account, :string
    add_column :creditors, :vat_discount_account, :string
  end
end
