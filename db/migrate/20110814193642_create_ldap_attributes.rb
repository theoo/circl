class CreateLdapAttributes < ActiveRecord::Migration
  def self.up

    create_table :ldap_attr_mappings do |t|
      t.integer :oc_map_id, :null => false
      t.string  :name, :null => false
      t.string  :sel_expr, :null => false
      t.string  :sel_expr_u
      t.string  :from_tbls, :null => false
      t.string  :join_where
      t.string  :add_proc
      t.string  :del_proc
      t.integer :param_order, :null => false
      t.integer :expect_return, :null => false
    end

    create_table :ldap_oc_mappings do |t|
      t.string  :name, :null => false
      t.string  :keytbl, :null => false
      t.string  :keycol, :null => false
      t.string  :create_proc
      t.string  :delete_proc
      t.string  :expect_return, :null => false
    end

  end

  def self.down
    drop_table :ldap_attr_mappings
    drop_table :ldap_oc_mappings
  end
end
