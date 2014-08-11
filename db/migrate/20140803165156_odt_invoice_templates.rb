class OdtInvoiceTemplates < ActiveRecord::Migration
  def change
    add_column :invoice_templates, :odt_file_name, :string
    add_column :invoice_templates, :odt_content_type, :string
    add_column :invoice_templates, :odt_file_size, :integer
    add_column :invoice_templates, :odt_updated_at, :datetime

  end
end
