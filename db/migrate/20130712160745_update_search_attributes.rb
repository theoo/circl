class UpdateSearchAttributes < ActiveRecord::Migration
  def change
    # Remove obsolete attributes
    sa = SearchAttribute.where(:name => 'is_closed')
    sa.each do |e|
      e.destroy
      raise ArgumentError, "Unable to destroy " + e.inspect unless e.destroyed?
    end

    puts "You may need to re-run rake db:migrate if the next migration fails."
  end
end
