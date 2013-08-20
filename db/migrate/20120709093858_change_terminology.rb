class ChangeTerminology < ActiveRecord::Migration
  # This automatically generates the up/down method
  def change
    rename_column   :affairs, :billing_id, :buyer_id
    rename_index    :affairs, 'index_affairs_on_billing_id', 'index_affairs_on_buyer_id'

    rename_column   :affairs, :delivery_id, :receiver_id
    rename_index    :affairs, 'index_affairs_on_delivery_id', 'index_affairs_on_receiver_id'

    rename_column   :tasks, :owner_id, :executer_id
    rename_index    :tasks, 'index_tasks_on_owner_id', 'index_tasks_on_executer_id'
  end
end
