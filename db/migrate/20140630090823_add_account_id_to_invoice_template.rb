class AddAccountIdToInvoiceTemplate < ActiveRecord::Migration
  def change
    add_column :invoice_templates, :account_identification, :string
  end
end
