class AddTagColors < ActiveRecord::Migration
  def change
    add_column :private_tags, :color, :string, null: true
    add_column :public_tags,  :color, :string, null: true
  end
end
