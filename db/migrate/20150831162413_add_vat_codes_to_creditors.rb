class AddTvaCodesToCreditors < ActiveRecord::Migration
  def change
    add_column :people, :creditor_vat_account, :string
    add_column :people, :creditor_vat_discount_account, :string
  end
end
