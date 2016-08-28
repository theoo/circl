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
    # main_communication_language
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

  end

end
