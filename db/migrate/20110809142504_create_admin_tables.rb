class CreateAdminTables < ActiveRecord::Migration
  def self.up
    create_table :application_settings do |t|
      t.string :key
      t.string :value
    end

    create_table :employment_contracts do |t|
      t.references :person, :null => false

      t.integer :percentage
      t.date :interval_starts_on
      t.date :interval_ends_on
      t.text :description

      t.timestamps
    end

    create_table :tasks do |t|
      t.references :person, :null => false

      t.date :date
      t.text :description
      t.integer :duration

      t.timestamps
    end

    create_table :logs do |t|
      t.references :person, :null => false

      t.references :resource, :polymorphic => true
      t.string :title
      t.text :description

      t.timestamps
    end

    create_table :comments do |t|
      t.references :person, :null => false
      t.references :resource, :polymorphic => true

      t.string :title
      t.text :description
      t.boolean :is_closed, :null => false, :default => false

      t.timestamps
    end

    create_table :invoice_pools do |t|
      t.string :title
      t.text  :description
      t.date :interval_starts_on
      t.date :interval_ends_on
      t.integer :value_in_cents
      t.string :value_currency

      t.timestamps
    end

    create_table :receipts do |t|
      t.references :person
      t.references :invoice, :null => false

      t.integer :value_in_cents
      t.string :value_currency
      t.date :value_date
      t.string :means_of_payment

      t.timestamps
    end

    create_table :invoices do |t|
      t.references :person, :null => false
      t.references :invoice_pool

      t.string :title
      t.text :description
      t.integer :value_in_cents
      t.string :value_currency
      t.boolean :is_closed, :null => false, :default => false

      t.timestamps
    end

    add_index :application_settings, :key
    add_index :employment_contracts, :person_id
    add_index :tasks, :person_id
    add_index :logs, :person_id
    add_index :logs, :resource_type
    add_index :logs, :resource_id
    add_index :comments, :person_id
    add_index :comments, :resource_type
    add_index :comments, :resource_id
    add_index :receipts, :person_id
    add_index :invoices, :person_id
  end

  def self.down
    drop_table :application_settings
    drop_table :employment_contracts
    drop_table :tasks
    drop_table :logs
    drop_table :comments
    drop_table :invoice_pools
    drop_table :receipts
    drop_table :invoices
  end
end
