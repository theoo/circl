# encoding: utf-8
# == Schema Information
#
# Table name: salaries
#
#  id                                          :integer          not null, primary key
#  parent_id                                   :integer
#  person_id                                   :integer          not null
#  from                                        :date
#  to                                          :date
#  title                                       :string(255)      not null
#  is_reference                                :boolean          default(FALSE), not null
#  married                                     :boolean          default(FALSE), not null
#  children_count                              :integer          default(0), not null
#  yearly_salary_in_cents                      :integer
#  yearly_salary_count                         :integer
#  created_at                                  :datetime
#  updated_at                                  :datetime
#  generic_template_id                         :integer          not null
#  pdf_file_name                               :string(255)
#  pdf_content_type                            :string(255)
#  pdf_file_size                               :integer
#  pdf_updated_at                              :datetime
#  activity_rate                               :integer
#  paid                                        :boolean          default(FALSE)
#  brut_account                                :string(255)
#  net_account                                 :string(255)
#  cert_transport_in_cents                     :integer          default(0), not null
#  cert_transport_currency                     :string(255)      default("CHF"), not null
#  cert_food_in_cents                          :integer          default(0), not null
#  cert_food_currency                          :string(255)      default("CHF"), not null
#  cert_logding_in_cents                       :integer          default(0), not null
#  cert_logding_currency                       :string(255)      default("CHF"), not null
#  cert_misc_salary_car_in_cents               :integer          default(0), not null
#  cert_misc_salary_car_currency               :string(255)      default("CHF"), not null
#  cert_misc_salary_other_title                :string(255)      default(""), not null
#  cert_misc_salary_other_value_in_cents       :integer          default(0), not null
#  cert_misc_salary_other_value_currency       :string(255)      default("CHF"), not null
#  cert_non_periodic_title                     :string(255)      default(""), not null
#  cert_non_periodic_value_in_cents            :integer          default(0), not null
#  cert_non_periodic_value_currency            :string(255)      default("CHF"), not null
#  cert_capital_title                          :string(255)      default(""), not null
#  cert_capital_value_in_cents                 :integer          default(0), not null
#  cert_capital_value_currency                 :string(255)      default("CHF"), not null
#  cert_participation_in_cents                 :integer          default(0), not null
#  cert_participation_currency                 :string(255)      default("CHF"), not null
#  cert_compentation_admin_members_in_cents    :integer          default(0), not null
#  cert_compentation_admin_members_currency    :string(255)      default("CHF"), not null
#  cert_misc_other_title                       :string(255)      default(""), not null
#  cert_misc_other_value_in_cents              :integer          default(0), not null
#  cert_misc_other_value_currency              :string(255)      default("CHF"), not null
#  cert_avs_ac_aanp_in_cents                   :integer          default(0), not null
#  cert_avs_ac_aanp_currency                   :string(255)      default("CHF"), not null
#  cert_lpp_in_cents                           :integer          default(0), not null
#  cert_lpp_currency                           :string(255)      default("CHF"), not null
#  cert_buy_lpp_in_cents                       :integer          default(0), not null
#  cert_buy_lpp_currency                       :string(255)      default("CHF"), not null
#  cert_is_in_cents                            :integer          default(0), not null
#  cert_is_currency                            :string(255)      default("CHF"), not null
#  cert_alloc_traveling_in_cents               :integer          default(0), not null
#  cert_alloc_traveling_currency               :string(255)      default("CHF"), not null
#  cert_alloc_food_in_cents                    :integer          default(0), not null
#  cert_alloc_food_currency                    :string(255)      default("CHF"), not null
#  cert_alloc_other_actual_cost_title          :string(255)      default(""), not null
#  cert_alloc_other_actual_cost_value_in_cents :integer          default(0), not null
#  cert_alloc_other_actual_cost_value_currency :string(255)      default("CHF"), not null
#  cert_alloc_representation_in_cents          :integer          default(0), not null
#  cert_alloc_representation_currency          :string(255)      default("CHF"), not null
#  cert_alloc_car_in_cents                     :integer          default(0), not null
#  cert_alloc_car_currency                     :string(255)      default("CHF"), not null
#  cert_alloc_other_fixed_fees_title           :string(255)      default(""), not null
#  cert_alloc_other_fixed_fees_value_in_cents  :integer          default(0), not null
#  cert_alloc_other_fixed_fees_value_currency  :string(255)      default("CHF"), not null
#  cert_formation_in_cents                     :integer          default(0), not null
#  cert_formation_currency                     :string(255)      default("CHF"), not null
#  cert_others_title                           :string(255)      default(""), not null
#  cert_notes                                  :text             default(""), not null
#  employer_account                            :string(255)      default("")
#  comments                                    :text
#  yearly_salary_currency                      :string(255)      default("CHF"), not null
#


FactoryGirl.define do
  # factory :generic_template, :class => GenericTemplate do
  #   sequence(:title) { |n| "Title #{n}" }
  #   language_id 1
  # end

  # factory :salary_tax_generic, :class => Salaries::Taxes::Generic do
  #   trait :avs do
  #     year                     2013
  #     salary_from              0
  #     salary_to                0
  #     employer_value           0
  #     employer_percent         4.2
  #     employer_use_percent     true
  #     employee_value           0
  #     employee_percent         4.2
  #     employee_use_percent     true
  #   end
  #   trait :ac do
  #     year                     2013
  #     salary_from              0
  #     salary_to                126000
  #     employer_value           0
  #     employer_percent         1.1
  #     employer_use_percent     true
  #     employee_value           0
  #     employee_percent         1.1
  #     employee_use_percent     true
  #   end
  #   trait :ac_solid do
  #     year                     2013
  #     salary_from              126000.05
  #     salary_to                315000.00
  #     employer_value           0
  #     employer_percent         0.5
  #     employer_use_percent     true
  #     employee_value           0
  #     employee_percent         0.5
  #     employee_use_percent     true
  #   end
  #   trait :amat do
  #     year                     2013
  #     salary_from              0
  #     salary_to                0
  #     employer_value           0
  #     employer_percent         0.042
  #     employer_use_percent     true
  #     employee_value           0
  #     employee_percent         0.042
  #     employee_use_percent     true
  #   end
  # end

  # factory :salary_tax_is, :class => Salaries::Taxes::Generic do
  # end

  # factory :salary_tax_lpp, :class => Salaries::Taxes::Generic do
  # end

  # factory :salary_tax, :class => Salaries::Tax do
  #   trait :avs do
  #     title 'AVS'
  #     model 'Salaries::Taxes::Generic'
  #     after(:build) do |tax|
  #       tax.generic_taxes << FactoryGirl.create(:salary_tax_generic, :avs, :tax => tax)
  #     end
  #   end

  #   trait :ac do
  #     title 'AC'
  #     model 'Salaries::Taxes::Generic'
  #     after(:build) do |tax|
  #       tax.generic_taxes << FactoryGirl.create(:salary_tax_generic, :ac, :tax => tax)
  #     end
  #   end

  #   trait :ac_solid do
  #     title 'AC Solidarité'
  #     model 'Salaries::Taxes::Generic'
  #     after(:build) do |tax|
  #       tax.generic_taxes << FactoryGirl.create(:salary_tax_generic, :ac_solid, :tax => tax)
  #     end
  #   end

  #   trait :amat do
  #     title 'AMAT'
  #     model 'Salaries::Taxes::Generic'
  #     after(:build) do |tax|
  #       tax.generic_taxes << FactoryGirl.create(:salary_tax_generic, :amat, :tax => tax)
  #     end
  #   end

  #   trait :is do
  #     title 'IS'
  #     model 'Salaries::Taxes::Is'
  #     after(:create) do |tax|
  #       Salaries::Taxes::Is.create(:tax_id             => tax.id,
  #                                  :year               => 2013,
  #                                  :yearly_from        => 60000.0,
  #                                  :yearly_to          => 60600.0,
  #                                  :monthly_from       => 5000.05,
  #                                  :monthly_to         => 5050.0,
  #                                  :hourly_from        => 27.79,
  #                                  :hourly_to          => 28.06,
  #                                  :percent_alone      => 9.73,
  #                                  :percent_married    => 1.18,
  #                                  :percent_children_1 => nil,
  #                                  :percent_children_2 => nil,
  #                                  :percent_children_3 => nil,
  #                                  :percent_children_4 => nil,
  #                                  :percent_children_5 => nil)

  #       Salaries::Taxes::Is.create(:tax_id             => tax.id,
  #                                  :year               => 2013,
  #                                  :yearly_from        => 180000.0,
  #                                  :yearly_to          => 192000.0,
  #                                  :monthly_from       => 15000.0,
  #                                  :monthly_to         => 16000.0,
  #                                  :hourly_from        => 88.23,
  #                                  :hourly_to          => 94.11,
  #                                  :percent_alone      => 9.73,
  #                                  :percent_married    => 1.18,
  #                                  :percent_children_1 => nil,
  #                                  :percent_children_2 => nil,
  #                                  :percent_children_3 => nil,
  #                                  :percent_children_4 => nil,
  #                                  :percent_children_5 => nil)
  #     end
  #   end
  # end

  # factory :salary_item, :class => Salaries::Item do
  #   # Items
  #   trait :salaire do
  #     title 'salaire'
  #     value 4000 # 1000 are generated when creating salary
  #     category 'Revenus'
  #   end

  #   trait :bonus do
  #     title 'bonus'
  #     value 200
  #     category 'Revenus'
  #   end

  #   trait :retraite do
  #     title 'retraite'
  #     value -1400
  #   end

  #   trait :alloc do
  #     title 'allocations familliales'
  #     value 120
  #   end

  #   trait :armoire do
  #     title 'armoire cassée'
  #     value -200
  #     category 'Remboursements'
  #   end

  #   # Taxes
  #   trait :avs do
  #     after(:build) do |item|
  #       item.taxes << (Salaries::Tax.find_by_title('AVS') || FactoryGirl.create(:salary_tax, :avs))
  #     end
  #   end

  #   trait :ac do
  #     after(:build) do |item|
  #       item.taxes << (Salaries::Tax.find_by_title('AC') || FactoryGirl.create(:salary_tax, :ac))
  #     end
  #   end

  #   trait :ac_solid do
  #     after(:build) do |item|
  #       item.taxes << (Salaries::Tax.find_by_title('AC Solidarité') || FactoryGirl.create(:salary_tax, :ac_solid))
  #     end
  #   end

  #   trait :amat do
  #     after(:build) do |item|
  #       item.taxes << (Salaries::Tax.find_by_title('AMAT') || FactoryGirl.create(:salary_tax, :amat))
  #     end
  #   end

  #   trait :lpp do
  #     after(:build) do |item|
  #       item.taxes << (Salaries::Tax.find_by_title('LPP') || FactoryGirl.create(:salary_tax, :lpp))
  #     end
  #   end

  #   trait :is do
  #     after(:build) do |item|
  #       item.taxes << (Salaries::Tax.find_by_title('IS') || FactoryGirl.create(:salary_tax, :is))
  #     end
  #   end
  # end

  # factory :salary, :class => Salaries::Salary do |i|
  #   association :person, :factory => :person, :first_name => 'Something',
  #                                             :last_name => 'Something',
  #                                             :email => "test#{i.object_id}@circl.ch" ,
  #                                             :address => 'Something',
  #                                             :nationality => 'Something',
  #                                             :avs_number => '756.1234.1234.06',
  #                                             :bank_informations => 'Something',
  #                                             :birth_date => '01-01-2013'

  #   association :reference, :factory => :reference_salary

  #   sequence(:title) {|n| "Salary #{n}"}
  #   generic_template
  #   from Date.new(2013, 1, 1)
  #   to Date.new(2013, 1, 31)
  #   is_reference false

  #   married false
  #   children_count 0
  # end

  # factory :reference_salary, :class => Salaries::Salary do |i|
  #   association :person, :factory => :person, :first_name => 'Something',
  #                                             :last_name => 'Something',
  #                                             :email => "test#{i.object_id}@circl.ch" ,
  #                                             :address => 'Something',
  #                                             :nationality => 'Something',
  #                                             :avs_number => '756.1234.1234.06',
  #                                             :bank_informations => 'Something',
  #                                             :birth_date => '01-01-2013'

  #   sequence(:title) {|n| "Reference Salary #{n}"}
  #   generic_template
  #   from Date.new(2013, 1, 1)
  #   to Date.new(2013, 1, 31)
  #   is_reference true

  #   married false
  #   children_count 0

  #   trait :default do
  #     title 'default'
  #     yearly_salary 60000
  #     items do
  #       [
  #         FactoryGirl.build(:salary_item, :salaire, :avs, :ac, :amat, :position => 1),
  #         FactoryGirl.build(:salary_item, :bonus, :avs, :ac, :amat, :position => 2),
  #         FactoryGirl.build(:salary_item, :armoire, :position => 3)
  #       ]
  #     end
  #   end

  #   trait :retraite do
  #     title 'retraite'
  #     yearly_salary 60000 # This is the only one IS convertible value, this value doesn't change the test
  #     items do
  #       [
  #         FactoryGirl.build(:salary_item, :salaire, :avs, :ac, :amat, :position => 1),
  #         FactoryGirl.build(:salary_item, :bonus, :avs, :ac, :amat, :position => 2),
  #         FactoryGirl.build(:salary_item, :retraite, :avs, :position => 3),
  #         FactoryGirl.build(:salary_item, :armoire, :position => 4)
  #       ]
  #     end
  #   end

  #   trait :french do
  #     title 'french'
  #     yearly_salary 60000
  #     items do
  #       [
  #         FactoryGirl.build(:salary_item, :salaire, :avs, :is, :position => 1),
  #         FactoryGirl.build(:salary_item, :bonus, :avs, :is, :position => 2),
  #         FactoryGirl.build(:salary_item, :alloc, :is, :position => 3),
  #         FactoryGirl.build(:salary_item, :armoire, :position => 4)
  #       ]
  #     end
  #   end

  #   trait :rich do
  #     title 'rich'
  #     yearly_salary 180000
  #     items do
  #       [
  #         FactoryGirl.build(:salary_item, :salaire, :avs, :ac, :ac_solid, :amat, :position => 1, :value => 14000),
  #         FactoryGirl.build(:salary_item, :bonus, :avs, :ac, :ac_solid, :amat, :position => 2),
  #         FactoryGirl.build(:salary_item, :armoire, :position => 3)
  #       ]
  #     end
  #   end

  # end

  factory :emplyment_contract do
  end



end
