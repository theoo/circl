class RenameElasticSearchAttribute < ActiveRecord::Migration
  def change
    rename_table :elastic_search_attributes, :search_attributes
  end
end
