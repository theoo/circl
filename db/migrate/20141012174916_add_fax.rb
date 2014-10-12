class AddFax < ActiveRecord::Migration
  def change
    add_column :people, :fax_number, :string, default: ''
    add_index :people, :fax_number
  end
end
