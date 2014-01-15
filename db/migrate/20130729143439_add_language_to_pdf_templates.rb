class AddLanguageToPdfTemplates < ActiveRecord::Migration
  def change
  	add_column :invoice_templates, 					:language_id, :integer
  	add_column :salaries_salary_templates, 	:language_id, :integer

  	add_index :invoice_templates, 				:language_id
  	add_index :salaries_salary_templates,	:language_id

  	first_language = Language.first
  	InvoiceTemplate.all.each do |it|
  		it.update_attribute :language_id, first_language.id
  	end

  	change_column :invoice_templates, :language_id, :integer, :null => false
  	change_column :salaries_salary_templates, :language_id, :integer, :null => false
  end
end
