class PrintBvrWithoutValue < ActiveRecord::Migration
  def change
    rename_column :invoice_templates, :print_bvr, :with_bvr
    add_column    :invoice_templates, :show_invoice_value, :boolean, :default => true
  end
end
