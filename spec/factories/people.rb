# == Schema Information
#
# Table name: people
#
#  id                             :integer          not null, primary key
#  job_id                         :integer
#  location_id                    :integer
#  main_communication_language_id :integer
#  is_an_organization             :boolean          default(FALSE), not null
#  organization_name              :string(255)      default("")
#  title                          :string(255)      default("")
#  first_name                     :string(255)      default("")
#  last_name                      :string(255)      default("")
#  phone                          :string(255)      default("")
#  second_phone                   :string(255)      default("")
#  mobile                         :string(255)      default("")
#  email                          :string(255)      default(""), not null
#  second_email                   :string(255)      default("")
#  address                        :text             default("")
#  birth_date                     :date
#  nationality                    :string(255)      default("")
#  avs_number                     :string(255)      default("")
#  bank_informations              :text             default("")
#  encrypted_password             :string(128)      default(""), not null
#  reset_password_token           :string(255)
#  reset_password_sent_at         :datetime
#  remember_created_at            :datetime
#  sign_in_count                  :integer          default(0)
#  current_sign_in_at             :datetime
#  last_sign_in_at                :datetime
#  current_sign_in_ip             :string(255)
#  last_sign_in_ip                :string(255)
#  password_salt                  :string(255)
#  failed_attempts                :integer          default(0)
#  unlock_token                   :string(255)
#  locked_at                      :datetime
#  authentication_token           :string(255)
#  created_at                     :datetime
#  updated_at                     :datetime
#  hidden                         :boolean          default(FALSE), not null
#  gender                         :boolean
#  task_rate_id                   :integer
#  latitude                       :float
#  longitude                      :float
#  website                        :string(255)
#  alias_name                     :string(255)      default("")
#  fax_number                     :string(255)      default("")
#  creditor_account               :string(255)
#  creditor_transitional_account  :string(255)
#  creditor_vat_account           :string(255)
#  creditor_vat_discount_account  :string(255)
#  creditor_discount_account      :string(255)
#

FactoryGirl.define do
  FAKE_NAMES = [ %w(Lannie Brautigam), %w(Eugenio Buterbaugh), %w(Nana Guillermo), %w(Sunshine Buteau), %w(Assunta Straker),
    %w(Miles Ranallo), %w(Venice Nembhard), %w(Ronny Elsey), %w(Tanner Garret), %w(Karleen Hollister), %w(Ivory Tustin),
    %w(Nga Goldstein), %w(Sarah Neece), %w(Eladia Lindquist), %w(Grover Conaway), %w(Jae Asher), %w(Vernell Grave),
    %w(Margarito Marker), %w(Alita Sinkler), %w(Shayne Eddington), %w(Erline Groth), %w(Kerry Castilleja), %w(Lucinda Lipari),
    %w(Hang Anderson), %w(Dortha Yarborough), %w(Kayleigh Gerard), %w(Krishna Wetzler), %w(Leia Booher), %w(Chad Langdon),
    %w(Adelina Davey), %w(Cherly Pasek), %w(Sonny Jacquez), %w(Cira Condron), %w(Tereasa Estelle), %w(Lindsey Willett),
    %w(Lamont Chao), %w(Verlie Pantoja), %w(Marvin Coulson), %w(Hellen Kerfoot), %w(Reid Juarbe), %w(Charity Perla),
    %w(Agustin Stefanik), %w(Laurie Rocco), %w(Marquita Matsuda), %w(Joselyn Couch), %w(Magen Hage), %w(Elicia Beville),
    %w(Jaymie Cavanagh), %w(Lucius Haddad), %w(Marilou Paek), %w(Somer Backlund), %w(Sylvie Kall), %w(Taisha Huyser),
    %w(Khalilah Tarin), %w(Lashawna Bloomfield), %w(Keeley Palomares), %w(Rose Rain), %w(Sunday Erne), %w(Angie Bermudez),
    %w(Takako Feuerstein), %w(Emmy Vanwagner), %w(Willodean Helvey), %w(Libbie Mcmasters), %w(Marianne Rhoda), %w(Sidney Denning),
    %w(Alena Guo), %w(Kecia Pai), %w(Mabel Kittle), %w(Sandee Grubbs), %w(Glenn Morrow), %w(Randell Valentine), %w(Mira Alper),
    %w(Geralyn Lightsey), %w(Lanell Limberg), %w(Sarah Singletary), %w(Kirsten Rather), %w(Britni Bartz), %w(Gearldine Mollett),
    %w(Napoleon Dunford), %w(Kristeen Killough), %w(Fe Hoyos), %w(Domenic Odwyer), %w(Edmundo Moffat), %w(Lai Penniman),
    %w(Lakita Martinelli), %w(Christia Kerman), %w(Hye Ruple), %w(Yesenia Wykoff), %w(Esther Darland), %w(Anneliese Beams),
    %w(Iesha Alkire), %w(Ramon Poch), %w(Cheyenne Zaldivar), %w(Caprice Dickson), %w(Monserrate Pattison), %w(Freeman Anderson),
    %w(Merle Biggerstaff), %w(Wayne Ronald), %w(Julio Cieslak), %w(Janean June) ]

  TITLES = %w(Mme M Dr Prof)

  factory :person do
    # job
    # location
    main_communication_language factory: :language
    task_rate

    is_an_organization false
    organization_name { rand(2) }
    title TITLES.sample
    first_name FAKE_NAMES.sample[0]
    last_name FAKE_NAMES.sample[1]
    phone { "+" + (1..15).map{ rand(10).to_s }.join }
    second_phone { "+" + (1..15).map{ rand(10).to_s }.join }
    mobile { "+" + (1..15).map{ rand(10).to_s }.join }
    sequence(:email) { |n| "#{first_name}.#{last_name}#{n}@circl.ch" }
    sequence(:second_email) { |n| "#{first_name}-#{last_name}#{n}@example.com"}
    address "Any location on earth 1"
    # birth_date
    # nationality
    # avs_number
    # bank_informations
    # encrypted_password
    # reset_password_token
    # reset_password_sent_at
    # remember_created_at
    # sign_in_count
    # current_sign_in_at
    # last_sign_in_at
    # current_sign_in_ip
    # last_sign_in_ip
    # password_salt
    # failed_attempts
    # unlock_token
    # locked_at
    # authentication_token
    hidden false
    # gender
    # latitude
    # longitude
    # website
    # alias_name
    # fax_number
    # creditor_account
    # creditor_transitional_account
    # creditor_vat_account
    # creditor_vat_discount_account
    # creditor_discount_account
  end

  factory :user, parent: :person do

    # Add trait to define role, yet is only admin
    roles { Role.all }
    association :task_rate

  end

end
