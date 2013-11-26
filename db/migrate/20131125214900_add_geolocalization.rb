class AddGeolocalization < ActiveRecord::Migration
  def change
    add_column :people, :latitude, :float
    add_column :people, :longitude, :float
  end
end
