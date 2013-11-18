class CreateExtras < ActiveRecord::Migration
  def up
    create_table :extras do |t|
      t.integer :affair_id
      t.string  :title
      t.text    :description
      t.integer :value_in_cents
      t.string  :value_currency
      t.integer :quantity
      t.integer :position

      t.timestamps
    end
    add_index :extras, :affair_id
    add_index :extras, :value_in_cents
    add_index :extras, :quantity
    add_index :extras, :position

  end

  def down
    drop_table :extras
  end
end
