class AddMissingIndices < ActiveRecord::Migration
  def up
    add_index :affairs, :value_in_cents
    add_index :affairs, :value_currency
    add_index :affairs, :created_at
    add_index :affairs, :updated_at

    add_index :background_tasks, :created_at
    add_index :background_tasks, :updated_at

    add_index :comments, :is_closed
    add_index :comments, :created_at
    add_index :comments, :updated_at

    add_index :employment_contracts, :interval_starts_on
    add_index :employment_contracts, :interval_ends_on
    add_index :employment_contracts, :created_at
    add_index :employment_contracts, :updated_at

    add_index :invoices, :value_in_cents
    add_index :invoices, :value_currency
    add_index :invoices, :is_closed
    add_index :invoices, :affair_id
    add_index :invoices, :created_at
    add_index :invoices, :updated_at
    add_index :invoices, :pdf_updated_at

    add_index :jobs, :name

    add_index :languages, :name
    add_index :languages, :code

    add_index :ldap_attributes, :name

    add_index :logs, :created_at
    add_index :logs, :updated_at

    add_index :people, :is_an_organization
    add_index :people, :organization_name
    add_index :people, :first_name
    add_index :people, :last_name
    add_index :people, :second_email
    add_index :people, :created_at
    add_index :people, :updated_at

    add_index :private_tags, :name

    add_index :public_tags, :name

    add_index :receipts, :invoice_id
    add_index :receipts, :value_in_cents
    add_index :receipts, :value_currency
    add_index :receipts, :value_date
    add_index :receipts, :means_of_payment
    add_index :receipts, :created_at
    add_index :receipts, :updated_at

    add_index :search_attributes, :model
    add_index :search_attributes, :name
    add_index :search_attributes, :group

    add_index :subscriptions, :interval_starts_on
    add_index :subscriptions, :interval_ends_on
    add_index :subscriptions, :value_in_cents
    add_index :subscriptions, :value_currency
    add_index :subscriptions, :created_at
    add_index :subscriptions, :updated_at
    add_index :subscriptions, :pdf_updated_at

    add_index :task_presets, :title
    add_index :task_presets, :value_in_cents
    add_index :task_presets, :value_currency

    add_index :task_types, :title

    add_index :tasks, :date
    add_index :tasks, :value_in_cents
    add_index :tasks, :value_currency

  end

  def down
    remove_index :affairs, :value_in_cents
    remove_index :affairs, :value_currency
    remove_index :affairs, :created_at
    remove_index :affairs, :updated_at

    remove_index :background_tasks, :created_at
    remove_index :background_tasks, :updated_at

    remove_index :comments, :is_closed
    remove_index :comments, :created_at
    remove_index :comments, :updated_at

    remove_index :employment_contracts, :interval_starts_on
    remove_index :employment_contracts, :interval_ends_on
    remove_index :employment_contracts, :created_at
    remove_index :employment_contracts, :updated_at

    remove_index :invoices, :value_in_cents
    remove_index :invoices, :value_currency
    remove_index :invoices, :is_closed
    remove_index :invoices, :affair_id
    remove_index :invoices, :created_at
    remove_index :invoices, :updated_at
    remove_index :invoices, :pdf_updated_at

    remove_index :jobs, :name

    remove_index :languages, :name
    remove_index :languages, :code

    remove_index :ldap_attributes, :name

    remove_index :logs, :created_at
    remove_index :logs, :updated_at

    remove_index :people, :is_an_organization
    remove_index :people, :organization_name
    remove_index :people, :first_name
    remove_index :people, :last_name
    remove_index :people, :second_email
    remove_index :people, :created_at
    remove_index :people, :updated_at

    remove_index :private_tags, :name

    remove_index :public_tags, :name

    remove_index :receipts, :invoice_id
    remove_index :receipts, :value_in_cents
    remove_index :receipts, :value_currency
    remove_index :receipts, :value_date
    remove_index :receipts, :means_of_payment
    remove_index :receipts, :created_at
    remove_index :receipts, :updated_at

    remove_index :search_attributes, :model
    remove_index :search_attributes, :name
    remove_index :search_attributes, :group

    remove_index :subscriptions, :interval_starts_on
    remove_index :subscriptions, :interval_ends_on
    remove_index :subscriptions, :value_in_cents
    remove_index :subscriptions, :value_currency
    remove_index :subscriptions, :created_at
    remove_index :subscriptions, :updated_at
    remove_index :subscriptions, :pdf_updated_at

    remove_index :task_presets, :title
    remove_index :task_presets, :value_in_cents
    remove_index :task_presets, :value_currency

    remove_index :task_types, :title

    remove_index :tasks, :date
    remove_index :tasks, :affair_id
    remove_index :tasks, :value_in_cents
    remove_index :tasks, :value_currency
  end
end
