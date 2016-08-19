
FactoryGirl.define do

  app_models = Module.constants.select do |constant_name|
    constant = eval(constant_name.to_s)
    if not constant.nil? and constant.is_a? Class and constant.superclass == ActiveRecord::Base
      constant
    end
  end

  factory :comment do
    person
    association :resource, :factory => :person
    sequence(:title)       { |n| "comment #{n}" }
    sequence(:description) { |n| "Temporary description" }
    is_closed false
  end

  factory :job do
    sequence(:name)        { |n| "job #{n}" }
    sequence(:description) { |n| "Temporary description" }
  end

  factory :language do
    sequence(:name) { |n| "language #{n}" }
    code SecureRandom.hex(2)
  end

  factory :ldap_attribute do
    sequence(:name) { |n| "ldap attribute #{n}" }
    sequence(:mapping) { |n| "mapping #{n}" }
  end

  factory :location do
    parent_id 1
    sequence(:name) { |n| "location #{n}" }
    iso_code_a2 SecureRandom.hex(2)
    iso_code_a3 SecureRandom.hex(2)
    iso_code_num SecureRandom.hex(2)
    postal_code_prefix { (1..4).map{ rand(10).to_s }.join }
    phone_prefix { (1..4).map{ rand(10).to_s }.join }
  end

  factory :people_communication_language do
    person
    language
  end

  factory :people_private_tag do
    person
    private_tag
  end

  factory :people_public_tag do
    person
    public_tag
  end

  factory :private_tag do
    # parent
    sequence(:name) { |n| "private tag #{n}" }
    color "#" + SecureRandom.hex(3)
  end

  factory :public_tag do
    # parent
    sequence(:name) { |n| "public tag #{n}" }
    color "#" + SecureRandom.hex(3)
  end

  factory :query_preset do
    sequence(:name) { |n| "query preset #{n}" }
    sequence(:query) { |n| "private_tags.id:#{n}" }
  end

  factory :search_attribute do
    m = app_models.sample
    col = m.to_s.constantize.column_names.sample
    model m
    name col
    indexing col
    mapping { {type: 'integer', index: 'not_analyzed'} }
    group nil
  end

end
