class AddBankImportHistory < ActiveRecord::Migration
  def up
    create_table :bank_import_histories do |t|
      t.string    :file_name, :allow_nil => false, :allow_blank => false
      t.string    :reference_line, :allow_nil => false, :allow_blank => false
      t.datetime  :media_date, :allow_nil => false, :allow_blank => false
    end

    add_index :bank_import_histories, :media_date
  end

  def down
    drop_table :bank_import_histories
  end
end
