class AddUnbilledFlagToAffairs < ActiveRecord::Migration
  def change
    add_column :affairs, :unbillable, :boolean, default: false, null: false
  end
end
