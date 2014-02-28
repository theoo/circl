class AddWebsiteUrlToPerson < ActiveRecord::Migration
  def change
    add_column :people, :website, :string, :null => true
  end
end
