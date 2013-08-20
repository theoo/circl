class TempAffair < ActiveRecord::Base
  self.table_name = 'affairs'
end

class Invoice < ActiveRecord::Base
  belongs_to :person
end

class InvoicePool < ActiveRecord::Base
  has_many  :invoices
  has_many  :receipts, :through => :invoices
end

class AffairsBeta2 < ActiveRecord::Migration
  def up
    #################################################
    # Affairs
    #################################################
    #
    # create tables affairs, subscriptions, affairs_subscriptions,
    # task_types, task_presets

    if Task.count > 0
      raise 'There must be no tasks for this migration to succeed'
    end

    create_table :affairs do |t|
      t.integer :owner_id, :null => false
      t.integer :billing_id, :null => false
      t.integer :delivery_id, :null => false
      t.string  :title, :null => false
      t.text    :description
      t.integer :value_in_cents, :default => 0, :null => false
      t.string  :value_currency, :default => 'CHF', :null => false
      t.timestamps
    end
    add_index :affairs, :owner_id
    add_index :affairs, :billing_id
    add_index :affairs, :delivery_id

    create_table :subscriptions do |t|
      t.string  :title, :null => false
      t.text    :description
      t.date    :interval_starts_on, :null => false
      t.date    :interval_ends_on, :null => false
      t.integer :value_in_cents, :default => 0, :null => false
      t.string  :value_currency, :default => 'CHF', :null => false
    end

    create_table :affairs_subscriptions, :id => false do |t|
      t.integer :affair_id
      t.integer :subscription_id
    end
    add_index :affairs_subscriptions, :affair_id
    add_index :affairs_subscriptions, :subscription_id

    create_table :task_types do |t|
      t.string  :title, :null => false
      t.text    :description
      t.float   :ratio, :null => false
    end

    create_table :task_presets do |t|
      t.integer :task_type_id
      t.string  :title, :null => false
      t.text    :description
      t.float   :duration
      t.integer :value_in_cents
      t.string  :value_currency
    end
    add_index :task_presets, :task_type_id
    # nothing to migrate for tasks
    # person_id is the owner of the task, the one who did the work.
    remove_index  :tasks, :person_id
    rename_column :tasks, :person_id, :owner_id
    change_column :tasks, :owner_id, :integer, :null => false
    add_index     :tasks, :owner_id

    add_column :tasks, :affair_id, :integer, :null => false
    add_column :tasks, :task_type_id, :integer, :null => false
    add_column :tasks, :value_in_cents, :integer, :default => 0, :null => false
    add_column :tasks, :value_currency, :string, :default => 'CHF', :null => false
    add_index :tasks, :affair_id
    add_index :tasks, :task_type_id

    add_column :invoices, :affair_id, :integer
    add_column :invoices, :printed_address, :text

    # Must reset column information after former migration
    # for postgresql
    Subscription.reset_column_information
    Invoice.reset_column_information

    # migrate invoice_pools to affairs
    Invoice.where(:invoice_pool_id => nil).each do |i|
      ip = InvoicePool.where(:title => i.title).first
      if ip
        i.update_attributes(:invoice_pool_id => ip.id)
      else
        # Create a single affair for this person
        a = TempAffair.create!(:title => i.title,
                               :description => i.description,
                               :owner_id => i.person_id,
                               :billing_id => i.person_id,
                               :delivery_id => i.person_id,
                               :value_in_cents => i.value_in_cents,
                               :created_at => i.created_at,
                               :updated_at => i.updated_at)
        i.update_attributes(:printed_address => i.person.address_for_bvr, :affair_id => a.id)
      end
    end

    puts 'Migrating InvoicePools to Affairs'
    InvoicePool.all.each do |ip|
      s = Subscription.create!(:title => ip.title,
                               :interval_starts_on => ip.interval_starts_on,
                               :interval_ends_on => ip.interval_ends_on,
                               :value_in_cents => ip.value_in_cents)
      affair_ids = []
      ip.invoices.each do |i|
        a = TempAffair.create!(:title => i.title,
                               :description => i.description,
                               :owner_id => i.person_id,
                               :billing_id => i.person_id,
                               :delivery_id => i.person_id,
                               :value_in_cents => i.value_in_cents,
                               :created_at => i.created_at,
                               :updated_at => i.updated_at)

        i.update_attributes(:printed_address => i.person.address_for_bvr, :affair_id => a.id)
        affair_ids << a.id
      end
      s.affair_ids = affair_ids
    end
    remove_column :invoices, :person_id
    remove_column :invoices, :invoice_pool_id
    remove_column :receipts, :person_id

    drop_table :invoice_pools
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
