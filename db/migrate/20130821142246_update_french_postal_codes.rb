class UpdateFrenchPostalCodes < ActiveRecord::Migration
  def change
  	france = Location.where(:name => "France").first

    if france
      locations_count = france.children
			                    .where("locations.postal_code_prefix ~ '^.{4}$' ").count

  		puts "Updating #{locations_count} locations."
      @bar = RakeProgressbar.new(locations_count)
    	(1..9).each do |num|
    		Location.where(:name => "France")
    			.first
    			.children
    			.where("locations.postal_code_prefix ~ '^#{num}.{3}$' ").each do |departement|
    				departement.update_attribute :postal_code_prefix, "0" + departement.postal_code_prefix
    				@bar.inc
    			end
    	end
    	@bar.finished
    end
  end
end
