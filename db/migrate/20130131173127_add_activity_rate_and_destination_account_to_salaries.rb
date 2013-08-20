class AddActivityRateAndDestinationAccountToSalaries < ActiveRecord::Migration
  def change
    add_column :salaries, :activity_rate, :integer
    add_column :salaries_taxes, :destination_account, :string
  end
end
