class CreateRoles < ActiveRecord::Migration
  def self.up
    create_table(:roles) do |t|
      t.string  :name, :null => false
      t.text    :description
      t.timestamps
    end

    create_table(:permissions) do |t|
      t.integer :role_id, :null => false
      t.string  :action
      t.string  :subject
      t.text    :hash_conditions
    end

    # htbm table for people-roles relationship
    create_table(:people_roles, :id => false) do |t|
      t.integer :person_id
      t.integer :role_id
    end

    # Max speed is required on Roles and Permissions
    # and data volume is low.
    add_index :roles, :name
    add_index :permissions, :role_id
    add_index :permissions, :action
    add_index :permissions, :subject

    add_index :people_roles, [:person_id, :role_id], :uniq => true
    add_index :people_roles, :person_id
    add_index :people_roles, :role_id

  end

  def self.down
    drop_table :roles
    drop_table :permissions
    drop_table :people_roles
  end

end
