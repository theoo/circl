class StorePdfs < ActiveRecord::Migration
  def up
    create_table(:background_tasks) do |t|
      t.string :type
      t.text   :options
    end

    add_attachment :invoices, :pdf
  end

  def down
    drop_table :background_tasks
    remove_attachment :invoices, :pdf
  end
end
