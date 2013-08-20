class CreateSalariesTables < ActiveRecord::Migration
  def up
    ############
    # SALARIES #
    ############
    create_table :salaries do |t|
      t.integer :parent_id
      t.integer :person_id, :null => false
      t.date    :from
      t.date    :to
      t.string  :title, :null => false
      t.boolean :is_template, :null => false, :default => false
      t.boolean :married, :null => false, :default => false
      t.integer :children_count, :null => false, :default => 0
      t.integer :yearly_salary_in_cents
      t.integer :yearly_salary_count
      t.timestamps
    end
    add_index :salaries, :parent_id
    add_index :salaries, :person_id
    add_index :salaries, :is_template

    create_table :salaries_items do |t|
      t.integer :parent_id
      t.integer :salary_id, :null => false
      t.integer :position, :null => false
      t.string  :title, :null => false
      t.integer :value_in_cents, :null => false
      t.string  :category
      t.timestamps
    end
    add_index :salaries_items, :salary_id

    create_table(:salaries_items_taxes, :id => false) do |t|
      t.integer :item_id, :null => false
      t.integer :tax_id, :null => false
    end
    add_index :salaries_items_taxes, :item_id
    add_index :salaries_items_taxes, :tax_id

    create_table :salaries_taxes do |t|
      t.string  :title, :null => false
      t.string  :model, :null => false
      t.timestamps
    end

    create_table :salaries_tax_data do |t|
      t.integer :salary_id, :null => false
      t.integer :tax_id, :null => false
      t.integer :position, :null => false
      t.integer :employer_value_in_cents, :null => false
      t.decimal :employer_percent, :null => false, :precision => 6, :scale => 3
      t.boolean :employer_use_percent, :null => false
      t.integer :employee_value_in_cents, :null => false
      t.decimal :employee_percent, :null => false, :precision => 6, :scale => 3
      t.boolean :employee_use_percent, :null => false
      t.timestamps
    end
    add_index :salaries_tax_data, :salary_id
    add_index :salaries_tax_data, :tax_id

    add_column :tasks, :salary_id, :integer
    add_index  :tasks, :salary_id


    #########
    # TAXES #
    #########
    create_table :salaries_taxes_generic do |t|
      t.integer :tax_id, :null => false
      t.integer :year, :null => false
      t.integer :salary_from_in_cents
      t.integer :salary_to_in_cents
      t.integer :employer_value_in_cents, :null => false
      t.decimal :employer_percent, :null => false, :precision => 6, :scale => 3
      t.boolean :employer_use_percent, :null => false
      t.integer :employee_value_in_cents, :null => false
      t.decimal :employee_percent, :null => false, :precision => 6, :scale => 3
      t.boolean :employee_use_percent, :null => false
      t.timestamps
    end
    add_index :salaries_taxes_generic, :tax_id
    add_index :salaries_taxes_generic, :year

    # IS
    create_table :salaries_taxes_is do |t|
      t.integer :tax_id, :null => false
      t.integer :year, :null => false
      t.integer :yearly_from_in_cents,  :null => false
      t.integer :yearly_to_in_cents,    :null => false
      t.integer :monthly_from_in_cents, :null => false
      t.integer :monthly_to_in_cents,   :null => false
      t.integer :hourly_from_in_cents,  :null => false
      t.integer :hourly_to_in_cents,    :null => false
      t.decimal :percent_alone,      :precision => 7, :scale => 2
      t.decimal :percent_married,    :precision => 7, :scale => 2
      t.decimal :percent_children_1, :precision => 7, :scale => 2
      t.decimal :percent_children_2, :precision => 7, :scale => 2
      t.decimal :percent_children_3, :precision => 7, :scale => 2
      t.decimal :percent_children_4, :precision => 7, :scale => 2
      t.decimal :percent_children_5, :precision => 7, :scale => 2
      t.timestamps
    end
    add_index :salaries_taxes_is, :tax_id
    add_index :salaries_taxes_is, :year

    # LPP
    create_table :salaries_taxes_age do |t|
      t.integer :tax_id, :null => false
      t.integer :year, :null => false
      t.integer :men_from, :null => false
      t.integer :men_to, :null => false
      t.integer :women_from, :null => false
      t.integer :women_to, :null => false
      t.decimal :employer_percent, :null => false, :precision => 6, :scale => 3
      t.decimal :employee_percent, :null => false, :precision => 6, :scale => 3
      t.timestamps
    end
    add_index :salaries_taxes_age, :tax_id
    add_index :salaries_taxes_age, :year
  end

  def down
    ############
    # SALARIES #
    ############
    remove_index :salaries, :person_id
    drop_table   :salaries

    remove_index :salaries_items, :salary_id
    drop_table   :salaries_items

    remove_index :salaries_items_taxes, :item_id
    remove_index :salaries_items_taxes, :tax_id
    drop_table   :salaries_items_taxes

    drop_table   :salaries_taxes

    remove_index :salaries_tax_data, :salary_id
    remove_index :salaries_tax_data, :tax_id
    drop_table   :salaries_tax_data

    remove_index  :tasks, :salary_id
    remove_column :tasks, :salary_id


    #########
    # TAXES #
    #########
    remove_index :salaries_taxes_generic, :tax_id
    remove_index :salaries_taxes_generic, :year
    drop_table   :salaries_taxes_generic

    remove_index :salaries_taxes_is, :tax_id
    remove_index :salaries_taxes_is, :year
    drop_table   :salaries_taxes_is

    remove_index :salaries_taxes_age, :tax_id
    remove_index :salaries_taxes_age, :year
    drop_table   :salaries_taxes_age

  end
end
