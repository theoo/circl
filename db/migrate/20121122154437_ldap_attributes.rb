class LdapAttributes < ActiveRecord::Migration
  def up
    create_table :ldap_attributes do |t|
      t.string  :name, :null => false
      t.string  :mapping, :null => false
      t.timestamps
    end
  end

  def down
    drop_table :ldap_attributes
  end
end
