class UpdateBackgroundTasks < ActiveRecord::Migration
  def change
  	add_column 	:background_tasks, :title, :string, :allow_null => false

  	add_column 	:background_tasks, :person_id, :integer, :allow_null => false
  	add_index		:background_tasks, :person_id

  	add_column 	:background_tasks, :ui_trigger, :string
  	add_column 	:background_tasks, :api_trigger, :string

  	add_column 	:background_tasks, :status, :string
  end
end
