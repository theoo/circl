class AddStatusToInvoicesAndAffairs < ActiveRecord::Migration
  def change
    add_column :invoices, :status,
              						:integer,
              						:limit => 4,
              						:default => 0,
              						:null => false # postgres doesn't have unsigned integers.
    add_index :invoices, :status

    add_column :affairs,  :status,
              						:integer,
              						:limit => 4,
              						:default => 0,
              						:null => false # postgres doesn't have unsigned integers.
    add_index :affairs, :status

    # remove is_closed and add cancelled and offered booleans
    remove_column :invoices, :is_closed

    add_column    :invoices, :cancelled,  :boolean, :null => false, :default => false
    add_column    :invoices, :offered,    :boolean, :null => false, :default => false
  end
end
