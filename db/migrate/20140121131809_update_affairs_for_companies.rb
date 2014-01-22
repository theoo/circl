class UpdateAffairsForCompanies < ActiveRecord::Migration
  def change
    me = ApplicationSetting.value("me")
    add_column :affairs, :estimate, :bool, :null => false, :default => false
    add_column :affairs, :parent_id, :integer
    add_column :affairs, :footer, :text
    add_column :affairs, :seller_id, :integer, :null => false, :default => me

    add_column :invoices, :conditions, :text
  end
end
