class AddSubscriptionValuesTable < ActiveRecord::Migration
  def change
    create_table :subscription_values do |t|
      t.integer :subscription_id, :null => false
      t.integer :invoice_template_id, :null => false
      t.integer :private_tag_id, :null => true
      t.integer :value_in_cents, :default => 0
      t.string  :value_currency, :default => 'CHF'
      t.integer :position, :null => false
    end

    add_index :subscription_values, :subscription_id
    add_index :subscription_values, :private_tag_id
    add_index :subscription_values, :value_in_cents
    add_index :subscription_values, :value_currency
    add_index :subscription_values, :position

    Subscription.all.each do |s|
      SubscriptionValue.create!(:invoice_template_id => s.invoice_template_id,
                                :value_in_cents => s.value_in_cents,
                                :value_currency => s.value_currency,
                                :position => 1,
                                :subscription => s)
    end

    remove_column :subscriptions, :invoice_template_id
    remove_column :subscriptions, :value_in_cents
    remove_column :subscriptions, :value_currency

  end
end
