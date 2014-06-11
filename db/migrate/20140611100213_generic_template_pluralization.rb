class GenericTemplatePluralization < ActiveRecord::Migration
  def change
    add_column :generic_templates, :plural, :boolean, default: false, null: false
  end
end
