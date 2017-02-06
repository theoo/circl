# == Schema Information
#
# Table name: affairs_products_categories
#
#  id        :integer          not null, primary key
#  affair_id :integer          not null
#  title     :string(255)
#  position  :integer          not null
#

require 'rails_helper'

RSpec.describe AffairsProductsCategory, :type => :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
