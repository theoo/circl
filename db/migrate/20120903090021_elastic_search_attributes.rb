class ElasticSearchAttributes < ActiveRecord::Migration
  def change
    create_table(:elastic_search_attributes) do |t|
      t.string :model,    :null => false
      t.string :name,     :null => false
      t.string :indexing
      t.string :mapping
      t.string :group
    end
  end
end
