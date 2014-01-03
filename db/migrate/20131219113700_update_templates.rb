class UpdateTemplates < ActiveRecord::Migration
  def change
    rename_table :salaries_salary_templates, :generic_templates

    add_column :generic_templates, :class_name, :string

    add_attachment :generic_templates, :odt
    add_index :generic_templates, :odt_updated_at

    remove_column :generic_templates, :html
    remove_column :generic_templates, :header
    remove_column :generic_templates, :footer

    rename_column :salaries, :salary_template_id, :generic_template_id
    GenericTemplate.all.each do |gt|
      gt.update_attributes(:class_name => 'Salaries::Salary')
    end
  end
end
