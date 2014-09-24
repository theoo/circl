class AddConditionsRelationshipToInvoices < ActiveRecord::Migration
  def change
    add_column :invoices, :condition_id, :integer
    add_index :invoices, :condition_id
  end
end
