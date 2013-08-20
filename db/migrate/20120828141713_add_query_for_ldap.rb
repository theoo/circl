class AddQueryForLdap < ActiveRecord::Migration
  def change
    add_column :roles, :ldap_query, :text
  end
end
