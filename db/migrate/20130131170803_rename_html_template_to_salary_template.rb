class RenameHtmlTemplateToSalaryTemplate < ActiveRecord::Migration
  def change
    rename_table :salaries_html_templates, :salaries_salary_templates
    rename_column :salaries, :html_template_id, :salary_template_id
  end
end
