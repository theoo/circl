class CreateQueryPreset < ActiveRecord::Migration
  def change

    create_table :query_presets do |t|
      t.string :name
      t.text :query
    end

    add_index :query_presets, :name
    add_index :query_presets, :query

  end
end
