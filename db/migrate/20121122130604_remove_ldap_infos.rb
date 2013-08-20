class RemoveLdapInfos < ActiveRecord::Migration
  def up
    %w{ldap_attr_mappings ldap_entry_objclasses ldap_oc_mappings}.each do |table|
      drop_table table if table_exists?(table)
    end

    remove_column :roles, :ldap_query
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
