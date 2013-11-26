class UpdateSearchAttributesValuesLength < ActiveRecord::Migration
  def change
    change_column :search_attributes, :indexing, :text, :null => false
    change_column :search_attributes, :mapping, :text, :null => false
  end
end
