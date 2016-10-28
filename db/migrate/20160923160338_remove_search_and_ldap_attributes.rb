class RemoveSearchAndLdapAttributes < ActiveRecord::Migration[5.0]
  def change
    drop_table :search_attributes
    drop_table :ldap_attributes
  end
end
