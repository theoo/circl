class AddInvoiceTemplateToSubscription < ActiveRecord::Migration
  def change
    add_column :subscriptions, :invoice_template_id, :integer
  end
end
