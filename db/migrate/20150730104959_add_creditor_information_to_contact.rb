class AddCreditorInformationToContact < ActiveRecord::Migration
  def change
    add_column :people, :creditor_account, :string
  end
end
