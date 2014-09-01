class AddAliasToPerson < ActiveRecord::Migration
  def change
    add_column :people, :alias_name, :string, default: ''
  end
end
