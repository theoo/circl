class PrepareTasksForUsage < ActiveRecord::Migration
  def up

    # Update tasks
    # No data should exists as at this time it's not implemented
    remove_column :tasks, :date
    add_column    :tasks, :start_date, :datetime
    add_index     :tasks, :start_date
    add_index     :tasks, :duration

    # Create rates table
    create_table(:task_rates) do |t|
      t.string      :title, :null => false
      t.text        :description
      t.integer     :value_in_cents, :null => false
      t.string      :value_currency, :default => 'CHF'
      t.boolean     :archive, :default => false
      t.timestamps
    end
    add_index   :task_rates, :value_in_cents
    add_index   :task_rates, :value_currency
    add_index   :task_rates, :archive

    # Update person
    add_column  :people, :task_rate_id, :integer
    add_index   :people, :task_rate_id

    # Update task_types
    change_column :task_types, :ratio, :null => true
    add_column  :task_types, :value_in_cents, :integer
    add_column  :task_types, :value_currency, :string, :default => 'CHF'
    add_column  :task_types, :archive, :boolean, :default => false
    add_index   :task_types, :value_in_cents
    add_index   :task_types, :value_currency
    add_index   :task_types, :archive

  end
end
