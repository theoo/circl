class UpdateEmploymentContractPercentage < ActiveRecord::Migration
  def change
  	change_column :employment_contracts, :percentage, :float
  end
end
