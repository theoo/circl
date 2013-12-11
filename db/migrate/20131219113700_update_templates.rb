class UpdateTemplates < ActiveRecord::Migration
  def change
    rename_table :salaries_salary_templates, :generic_templates

    add_column :generic_templates, :class_name, :string

    add_attachment :generic_templates, :odt
    add_index :generic_templates, :odt_updated_at

    remove_column :generic_templates, :html

    rename_column :salaries, :salary_template_id, :generic_template_id
    GenericTemplate.destroy_all # bye bye
  end
end
