class DontUseNull < ActiveRecord::Migration
  def up
    change_column :affairs, :title, :string, :default => ''
    change_column :affairs, :description, :text, :default => ''

    change_column :application_settings, :key, :string, :default => ''
    change_column :application_settings, :value, :string, :default => ''

    change_column :comments, :title, :string, :default => ''
    change_column :comments, :description, :text, :default => ''

    change_column :employment_contracts, :description, :text, :default => ''

    change_column :invoices, :title, :string, :default => ''
    change_column :invoices, :description, :text, :default => ''
    change_column :invoices, :printed_address, :text, :default => ''

    change_column :invoice_templates, :title, :string, :default => ''
    change_column :invoice_templates, :bvr_account, :string, :default => ''
    change_column :invoice_templates, :html, :text, :default => ''
    change_column :invoice_templates, :bvr_address, :text, :default => ''

    change_column :jobs, :name, :string, :default => ''
    change_column :jobs, :description, :text, :default => ''

    change_column :languages, :name, :string, :default => ''
    change_column :languages, :code, :string, :default => ''

    change_column :locations, :name, :string, :default => ''
    change_column :locations, :iso_code_a2, :string, :default => ''
    change_column :locations, :iso_code_a3, :string, :default => ''
    change_column :locations, :iso_code_num, :string, :default => ''
    change_column :locations, :postal_code_prefix, :string, :default => ''
    change_column :locations, :phone_prefix, :string, :default => ''

    change_column :permissions, :action, :string, :default => ''
    change_column :permissions, :subject, :string, :default => ''

    change_column :people, :organization_name, :string, :default => ''
    change_column :people, :title, :string, :default => ''
    change_column :people, :first_name, :string, :default => ''
    change_column :people, :last_name, :string, :default => ''
    change_column :people, :phone, :string, :default => ''
    change_column :people, :second_phone, :string, :default => ''
    change_column :people, :mobile, :string, :default => ''
    change_column :people, :email, :string, :default => ''
    change_column :people, :second_email, :string, :default => ''
    change_column :people, :nationality, :string, :default => ''
    change_column :people, :avs_number, :string, :default => ''
    change_column :people, :address, :text, :default => ''
    change_column :people, :bank_informations, :text, :default => ''

    change_column :private_tags, :name, :string, :default => ''

    change_column :public_tags, :name, :string, :default => ''

    change_column :query_presets, :name, :string, :default => ''
    change_column :query_presets, :query, :text, :default => ''

    change_column :receipts, :means_of_payment, :string, :default => ''

    change_column :roles, :name, :string, :default => ''
    change_column :roles, :description, :text, :default => ''

    change_column :search_attributes, :model, :string, :default => ''
    change_column :search_attributes, :name, :string, :default => ''
    change_column :search_attributes, :indexing, :string, :default => ''
    change_column :search_attributes, :mapping, :string, :default => ''
    change_column :search_attributes, :group, :string, :default => ''

    change_column :subscriptions, :title, :string, :default => ''
    change_column :subscriptions, :description, :text, :default => ''

    change_column :tasks, :description, :text, :default => ''

    change_column :task_presets, :title, :string, :default => ''
    change_column :task_presets, :description, :text, :default => ''

    change_column :task_types, :title, :string, :default => ''
    change_column :task_types, :description, :text, :default => ''
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
