class AddIs2014 < ActiveRecord::Migration
  def change
    create_table :salaries_taxes_is2014 do |t|
      t.integer :tax_id, :null => false
      t.integer :year, :null => false
      t.string  :tax_group, :null => false
      t.integer :children_count, :null => false
      t.string  :ecclesiastical, :null => false, :default => "N"
      t.integer :salary_from_in_cents, :null => false, :default => 0
      t.string  :salary_from_currency, :null => false, :default => "CHF"
      t.integer :salary_to_in_cents, :null => false, :default => 0
      t.string  :salary_to_currency, :null => false, :default => "CHF"
      t.integer :tax_value_in_cents, :null => false, :default => 0
      t.string  :tax_value_currency, :null => false, :default => "CHF"
      t.float   :tax_value_percentage, :null => false, :default => 0
      t.timestamps
    end
    add_index :salaries_taxes_is2014, :tax_id
    add_index :salaries_taxes_is2014, :year
  end
end
