class AddSalariesHtmlTemplates < ActiveRecord::Migration
  def change
    create_table(:salaries_html_templates) do |t|
      t.string     :title, :null => false
      t.text       :html, :null => false
      t.attachment :snapshot
      t.timestamps
    end

    add_column :salaries, :html_template_id, :integer, :null => false
    add_attachment :salaries, :pdf
  end
end
