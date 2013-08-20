class CreatePeople < ActiveRecord::Migration
  def self.up
    create_table(:people) do |t|

      # Relationships
      t.integer :job_id
      t.integer :location_id
      t.integer :main_communication_language_id

      # Common
      t.boolean :is_an_organization, :null => false, :default => false
      t.string  :organization_name
      t.string  :title
      t.string  :first_name
      t.string  :last_name
      t.string  :phone
      t.string  :second_phone
      t.string  :mobile
      t.string  :email
      t.string  :second_email
      t.text    :address
      t.boolean :hidden, :null => false, :default => false

      # Personal
      t.date    :birth_date
      t.string  :nationality
      t.string  :avs_number
      t.text    :bank_informations

      # Devise
      ## Database authenticatable
      t.string :encrypted_password

      ## Encryptable
      t.string :password_salt

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, :default => 0
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      ## Lockable
      t.integer  :failed_attempts, :default => 0 # Only if lock strategy is :failed_attempts
      t.string   :unlock_token # Only if unlock strategy is :email or :both
      t.datetime :locked_at

      ## Token authenticatable
      t.string :authentication_token

      t.timestamps
    end

    # relationships
    add_index :people, :job_id
    add_index :people, :location_id
    add_index :people, :main_communication_language_id
    add_index :people, :hidden

    # Devise
    add_index :people, :email # cannot set this to uniq
    add_index :people, :reset_password_token, :unique => true
    add_index :people, :unlock_token,         :unique => true
    add_index :people, :authentication_token, :unique => true

    # LDAP
    add_index :people, [:first_name, :last_name]
  end

  def self.down
    drop_table :people
  end
end
