class UpdateInvoiceCreatedAtFromDateToDatetime < ActiveRecord::Migration
  def up
    change_column :invoices, :created_at, :datetime
    change_column :invoices, :updated_at, :datetime
    change_column :receipts, :created_at, :datetime
    change_column :receipts, :updated_at, :datetime
  end

  def down
    change_column :invoices, :created_at, :date
    change_column :invoices, :updated_at, :date
    change_column :receipts, :created_at, :date
    change_column :receipts, :updated_at, :date
  end
end
