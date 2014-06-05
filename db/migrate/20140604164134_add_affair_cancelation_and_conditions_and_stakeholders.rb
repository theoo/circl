class AddAffairCancelationAndConditionsAndStakeholders < ActiveRecord::Migration
  def change
    # Stakeholders
    create_table :affairs_stakeholders do |t|
      t.integer :person_id
      t.integer :affair_id
      t.string  :title
    end

    add_index :affairs_stakeholders, :person_id
    add_index :affairs_stakeholders, :affair_id

    # Affairs' conditions
    add_column :affairs, :condition_id, :integer
    add_index :affairs, :condition_id

    create_table :affairs_conditions do |c|
      c.string  :title
      c.text    :description
    end
  end
end
