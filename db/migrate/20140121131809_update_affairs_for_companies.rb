class UpdateAffairsForCompanies < ActiveRecord::Migration
  def change
    me = ApplicationSetting.value("me")
    add_column :affairs, :estimate, :bool, :null => false, :default => false
    add_column :affairs, :parent_id, :integer
    add_column :affairs, :footer, :text
    add_column :affairs, :conditions, :text
    add_column :affairs, :seller_id, :integer, :null => false, :default => me

    add_index :affairs, :estimate
    add_index :affairs, :parent_id
    add_index :affairs, :seller_id

    add_column :invoices, :conditions, :text
  end
end
