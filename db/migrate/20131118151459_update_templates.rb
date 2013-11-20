class UpdateTemplates < ActiveRecord::Migration
  def up
    add_column :invoice_templates, :header, :text
    add_column :invoice_templates, :footer, :text
  end

  def down
    remove_column :invoice_templates, :header
    remove_column :invoice_templates, :footer
  end
end
