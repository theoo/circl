
FactoryGirl.define do

  app_models = Module.constants.select do |constant_name|
    constant = eval(constant_name.to_s)
    if not constant.nil? and constant.is_a? Class and constant.superclass == ActiveRecord::Base
      constant
    end
  end

  factory :generic_template do
    language

    sequence(:title) { |n| "generic template #{n} - #{SecureRandom.hex}" }
    # snapshot # Paperclip
    # odt      # Paperclip
    class_name app_models.sample
    plural false

  end

  factory :invoice_template do
    language

    sequence(:title) { |n| "invoice template #{n} - #{SecureRandom.hex}" }
    sequence(:html)  { |n| "html #{n}" }

    with_bvr true
    bvr_address "Random address"
    bvr_account "12-123455-2"
    show_invoice_value true
    account_identification { (1..6).map{ rand(10).to_s }.join  }

  end

end
