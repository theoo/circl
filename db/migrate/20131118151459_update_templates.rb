class UpdateTemplates < ActiveRecord::Migration
  def up
    add_column :salaries_salary_templates, :header, :text
    add_column :salaries_salary_templates, :footer, :text
    # Add polymorphic assoc
  end

  def down
    remove_column :salaries_salary_templates, :header
    remove_column :salaries_salary_templates, :footer
  end
end
