class CreateInvoiceTemplates < ActiveRecord::Migration
  def change
    create_table(:invoice_templates) do |t|
      t.string  :title, :null => false
      t.text    :html, :null => false
      t.timestamps
    end

    add_column :invoices, :invoice_template_id, :integer, :null => false, :default => 1
    add_index  :invoices, :invoice_template_id
  end
end
