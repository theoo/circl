class ExtendBankHistoryReferenceLine < ActiveRecord::Migration
  def up

    change_column :bank_import_histories, :reference_line, :text
    add_column    :bank_import_histories, :account_servicer_reference, :text

  end

  def down

    change_column :bank_import_histories, :reference_line, :string
    remove_column :bank_import_histories, :account_servicer_reference, :text

  end
end
