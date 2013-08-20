class CorrectColumnsDefaults < ActiveRecord::Migration
  def up
    change_column_default(:invoices, :invoice_template_id, nil)

    Subscription.where(:invoice_template_id => nil).update_all(:invoice_template_id => InvoiceTemplate.order(:id).first.id)

    change_column :subscriptions, :invoice_template_id, :integer, :null => false
    add_index     :subscriptions, :invoice_template_id
  end

  def down
    change_column :invoices, :invoice_template_id, :integer, :default => 1, :null => false

    change_column :subscriptions, :invoice_template_id, :integer, :null => true
    remove_index  :subscriptions, :invoice_template_id
  end
end
