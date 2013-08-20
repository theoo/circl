class CreateDirectoryAttributes < ActiveRecord::Migration
  def self.up
    create_table :jobs do |t|
      t.string  :name
      t.text    :description
    end

    create_table :translation_aptitudes do |t|
      t.integer :person_id, :null => false
      t.integer :from_language_id, :null => false
      t.integer :to_language_id, :null => false
    end

    create_table :languages do |t|
      t.string    :name
      t.string    :code
    end

    create_table(:people_communication_languages, :id => false) do |t|
      t.integer :person_id
      t.integer :language_id
    end

    create_table :locations do |t|
      t.integer :parent_id
      t.string  :name
      t.string  :iso_code_a2
      t.string  :iso_code_a3
      t.string  :iso_code_num
      t.string  :postal_code_prefix
      t.string  :phone_prefix
    end

    create_table :subscriptions do |t|
      t.integer  :subscription_group_id
      t.string   :name
      t.text     :description
    end

    create_table :subscription_groups do |t|
      t.string  :name
    end

    create_table :people_subscriptions, :id => false do |t|
      t.integer   :subscription_id
      t.integer   :person_id
    end

    # indices
    add_index :translation_aptitudes, :person_id
    add_index :translation_aptitudes, :from_language_id
    add_index :translation_aptitudes, :to_language_id

    add_index :people_communication_languages, :person_id,
              :name => 'people_person_id_index'
    add_index :people_communication_languages, :language_id,
              :name => 'people_language_id_index'
    add_index :people_communication_languages, [:person_id, :language_id],
              :uniq => true, :name => 'people_communication_languages_index'

    add_index :locations, :parent_id
    add_index :locations, :name
    add_index :locations, :iso_code_a2
    add_index :locations, :iso_code_a3
    add_index :locations, :postal_code_prefix

    add_index :subscriptions, :subscription_group_id
    add_index :people_subscriptions, [:subscription_id, :person_id]

  end

  def self.down
    drop_table :jobs
    drop_table :translation_aptitudes
    drop_table :languages
    drop_table :people_communication_languages
    drop_table :locations
    drop_table :subscriptions
    drop_table :subscription_groups
    drop_table :people_subscriptions
  end
end
