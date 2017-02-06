# == Schema Information
#
# Table name: products
#
#  id                 :integer          not null, primary key
#  provider_id        :integer
#  after_sale_id      :integer
#  key                :string(255)      not null
#  title              :string(255)
#  category           :string(255)
#  description        :text
#  has_accessories    :boolean          default(FALSE), not null
#  archive            :boolean          default(FALSE), not null
#  created_at         :datetime
#  updated_at         :datetime
#  unit_symbol        :string(255)
#  price_to_unit_rate :integer
#  width              :integer
#  height             :integer
#  depth              :integer
#  volume             :integer
#  weight             :integer
#

FactoryGirl.define do

  factory :product do
    # provider
    # after_sale
    sequence(:key) { |n| "key #{SecureRandom.hex}"}
    sequence(:title) { |n| "product #{n}"}
    sequence(:category) { |n| "category #{n}"}
    description "Temporary description"
    has_accessories false
    archive false
    unit_symbol I18n.t("product.units").keys.sample
    price_to_unit_rate 1
    # width
    # height
    # depth
    # volume
    # weight
  end

  factory :product_item do
    # parent
    affair
    product
    association :program, factory: :product_program
    association :category, factory: :affairs_products_category

    sequence(:position) {|n| n}
    quantity { rand(10) }
    bid_percentage { rand(50) }
    value { rand(100) }
    # comment
    # ordered_at
    # confirmed_at
    # delivery_at
    # warranty_begin
    # warranty_end
  end

  factory :product_program do
    sequence(:key) { |n| "pg #{n} "}
    sequence(:program_group) { |n| "product group #{n} "}
    sequence(:title) { |n| "product program #{n} "}
    description "Temporary description"
    archive false
  end

  factory :product_variant do
    product

    program_group { ProductProgram.select("DISTINCT product_programs.program_group").map(&:program_group).sample }
    sequence(:title) { |n| "product variant #{n} "}
    buying_price { rand(100) }
    selling_price { rand(100) }
    art { rand(10) }
  end

end
