class AddBvrAddressAndAccountToInvoiceTemplate < ActiveRecord::Migration
  def change
    add_column  :invoice_templates,  :print_bvr,   :boolean, :default => false
    add_column  :invoice_templates,  :bvr_address, :text
    add_column  :invoice_templates,  :bvr_account, :string
    add_attachment  :invoice_templates, :snapshot
  end
end
