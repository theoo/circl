class AddCreditorInformationToContact < ActiveRecord::Migration
  def change
    add_column :people, :creditor_account, :string
    add_column :people, :creditor_transitional_account, :string
  end
end
