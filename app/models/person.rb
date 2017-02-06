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

class Person < ApplicationRecord

  ################
  ### INCLUDES ###
  ################

  include SearchEngineConcern

  attr_accessor :notices
  attr_accessor :template

  def initialize(*params)
    super(*params)
    @notices = ActiveModel::Errors.new(self)
  end

  #################
  ### CALLBACKS ###
  #################

  before_validation :nilify_authentication_token_if_blank

  before_save :reset_authentication_token_if_requested, :verify_employee_information, :update_geographic_coordinates
  after_save do
    update_search_engine
  end

  before_destroy :do_not_destroy_if_has_invoices
  before_destroy :do_not_destroy_if_has_salaries
  before_destroy :do_not_destroy_if_first_admin
  before_destroy :do_not_destroy_if_has_running_contracts
  before_destroy :do_not_destroy_if_linked_to_products
  before_destroy :clear_affairs_as_buyer_and_affairs_as_receiver
  before_destroy do
    roles.clear
    communication_languages.clear
    private_tags.clear
    public_tags.clear
  end
  # TODO remove password if removing last email.

  after_destroy do
    update_search_engine
  end

  # LDAP
  if Rails.configuration.ldap_enabled
    after_save :ldap_update, unless: "self.changes.empty?"
    before_destroy :ldap_remove
  end

  #################
  ### RELATIONS ###
  #################

  # Common
  belongs_to  :job
  belongs_to  :location
  belongs_to  :task_rate
  belongs_to  :main_communication_language,
              class_name: 'Language'

  has_many    :employment_contracts,
              dependent: :destroy

  # comments made by this person
  has_many    :edited_comments,
              class_name: 'Comment',
              dependent: :destroy

  # comments made by someone else on this entry
  has_many    :comments_edited_by_others,
              class_name: 'Comment',
              as: :resource,
              dependent: :destroy

  # monitored_habtm :roles,
  has_many  :people_roles # for permissions
  has_many  :roles,
            -> { distinct },
            class_name: 'Role',
            through: :people_roles,
            after_add: :update_search_engine,
            after_remove: :update_search_engine

  has_many  :permissions,
            -> { distinct },
            through: :roles

  has_many  :people_public_tags # for permissions
  has_many  :people_private_tags # for permissions

  # monitored_habtm :public_tags,
  has_many  :public_tags,
            -> { distinct },
            class_name: 'PublicTag',
            through: :people_public_tags,
            after_add: [:update_search_engine, :select_parents],
            after_remove: :update_search_engine

  # monitored_habtm :private_tags,
  has_many  :private_tags,
            -> { distinct },
            class_name: 'PrivateTag',
            through: :people_private_tags,
            after_add: [:update_search_engine, :select_parents],
            after_remove: :update_search_engine

  # secondary communication languages
  has_many  :people_communication_languages # for permissions

  # monitored_habtm :communication_languages,
  has_many  :communication_languages,
            -> { distinct },
            class_name: 'Language',
            through: :people_communication_languages,
            source: :language,
            after_add: :update_search_engine,
            after_remove: :update_search_engine

  # Financial
  has_many  :affairs,
            foreign_key: :owner_id,
            dependent: :destroy

  has_many  :affairs_as_buyer,
            class_name: 'Affair',
            foreign_key: :buyer_id

  has_many  :affairs_as_receiver,
            class_name: 'Affair',
            foreign_key: :receiver_id

  has_many  :affairs_stakeholders
  has_many  :affairs_as_stakeholder,
            -> { distinct },
            through: :affairs_stakeholders,
            source: :affair

  has_many  :invoices,
            -> { distinct },
            through: :affairs,
            foreign_key: 'owner_id'

  has_many  :receipts,
            -> { distinct },
            through: :invoices

  has_many  :subscriptions,
            -> { distinct },
            through: :affairs


  # Salaries
  has_many  :salaries,
            class_name: 'Salaries::Salary',
            dependent: :destroy

  # tasks this person have edited
  has_many  :executed_tasks,
            class_name: '::Task',
            foreign_key: 'executer_id',
            dependent: :destroy

  has_many  :created_tasks,
            class_name: '::Task',
            foreign_key: 'creator_id'

  # tasks made for this person, the client
  has_many  :tasks,
            through: :affairs

  has_many  :products_to_sell,
            class_name: 'Product',
            foreign_key: :provider_id

  has_many  :products_to_maintain,
            class_name: 'Product',
            foreign_key: :after_sale_id

  has_many  :credits,
            class_name: 'Creditor',
            foreign_key: :creditor_id


  ##################
  ### SCOPES ###
  ##################

  scope :hidden,  -> { where(hidden: true) }
  scope :visible, -> { where("hidden is NULL OR hidden IN ('false', 'f', '0')") }

  scope :duplicates, -> { find_by_sql("SELECT id\
    FROM (SELECT *, row_number() over (partition BY first_name, last_name ORDER BY first_name)\
      AS rnum FROM people) t\
    WHERE t.rnum > 1 AND first_name != ''") }

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :encryptable, :lockable,
         :recoverable, :rememberable, :trackable, :timeoutable


  ###################
  ### VALIDATIONS ###
  ###################

  validates_with Validators::PresenceOfIdentifier
  validates_with Validators::FullName
  validates_with Validators::Date, attribute: :birth_date

  validates_with Validators::Phone, attribute: :phone
  validates_with Validators::Phone, attribute: :second_phone
  validates_with Validators::Phone, attribute: :mobile
  validates_with Validators::Phone, attribute: :fax_number

  validate :cannot_use_same_first_name_and_last_name_unless_has_email

  validate :is_an_organization_is_ticked_if_has_name_and_no_person_info

  validate :do_not_remove_admin_role_for_first_admin

  validate :email_exists_if_it_has_a_second_email
  validate :email_required_if_it_is_loggable
  validate :cannot_use_existing_email
  validates_uniqueness_of :id, allow_nil: true # Funny no ? It's to allow override when importing from CSV.
  validates_uniqueness_of :authentication_token, allow_nil: true
  validates_uniqueness_of :email, if: :has_email?
  validates_uniqueness_of :second_email, if: :has_second_email?
  validates_format_of :email, with: EMAIL_REGEX, if: :has_email?
  validates_format_of :second_email, with: EMAIL_REGEX, if: :has_second_email?
  validates :website, format: URI::regexp(%w(http https)), unless: 'website.blank?'
  validate :avs_number_format
  validate :second_email_is_different, if: lambda { has_email? && has_second_email? }
  validate :has_org_name_if_is_an_org_is_set
  validate :main_language_is_not_in_communication_languages
  validates_strength_of :password, with: :email, if: lambda { !password.blank? }
  validates_confirmation_of :password

  validates :latitude, :inclusion => 0..90, :if => 'latitude'
  validates :longitude, :inclusion => -180..180, :if => 'longitude'


  # Validate fields of type 'string' length
  validates_length_of :organization_name, maximum: 255
  validates_length_of :title, maximum: 255
  validates_length_of :first_name, maximum: 255
  validates_length_of :last_name, maximum: 255
  validates_length_of :phone, maximum: 255
  validates_length_of :second_phone, maximum: 255
  validates_length_of :mobile, maximum: 255
  validates_length_of :fax_number, maximum: 255
  validates_length_of :email, maximum: 255
  validates_length_of :second_email, maximum: 255
  validates_length_of :nationality, maximum: 255
  validates_length_of :avs_number, maximum: 255
  validates_length_of :creditor_transitional_account, maximum: 255
  validates_length_of :creditor_account, maximum: 255
  validates_length_of :creditor_discount_account, maximum: 255
  validates_length_of :creditor_vat_account, maximum: 255
  validates_length_of :creditor_vat_discount_account, maximum: 255

  validates :alias_name,
    format: { with: /\A[a-zA-Z\-_\d]+\z/, message: I18n.t("person.errors.only_letters")},
    length: { maximum: 25 },
    unless: 'alias_name.blank?'

  # Validate fields of type 'text' length
  validates_length_of :address, maximum: 65535
  validates_length_of :bank_informations, maximum: 65535


  #####################
  ### CLASS METHODS ###
  #####################

  # Setup accessible (or protected) attributes for your model
  # FIXME: unable to record other attributes (first_name) with
  # create method.
  #attr_accessible :email, :password, :password_confirmation, :remember_me
  PROTECTED_ATTRIBUTES = %w{ encrypted_password reset_password_token
    reset_password_sent_at remember_created_at sign_in_count current_sign_in_at
    last_sign_in_at current_sign_in_ip last_sign_in_ip password_salt
    failed_attempts unlock_token locked_at authentication_token }

  RESTRICTED_ATTRIBUTES = %w{ bank_informations avs_number  }


  # TODO redo this in a lib with:
  # - process tracking
  # - reindexation after insertion
  # - create all missing attributes around person, more than just private/public tags
  # - compare double entries within the file
  # - merge data with existing entries

  def self.parse_people(data)
    infos = Hash.new { |h,k| h[k]=[] }

    infos[:private_tags] = []
    infos[:public_tags]  = []
    infos[:jobs]         = []

    columns = [:id,
      :first_name,
      :last_name,
      :alias_name,
      :title,
      :is_an_organization,
      :organization_name,
      :address,
      :postal_code_prefix,
      :location,
      :phone,
      :second_phone,
      :mobile,
      :fax_number,
      :email,
      :second_email,
      :job,
      :birth_date,
      :nationality,
      :avs_number,
      :gender,
      :bank_informations,
      :roles,
      :main_communication_language,
      :communication_languages,
      :private_tags,
      :public_tags,
      :hidden,
      :comments]

    csvStruct = Struct.send(:new, *columns)

    begin
      CSV.parse(data, encoding: 'UTF-8')[1..-1].each_with_index do |row, i|

        row.map! { |s| (s || '').force_encoding('utf-8').strip }

        r = csvStruct.new(*row)

        if row.size != columns.size
          infos[:errors] << "#{I18n.t('person.import.line')} #{i+2}: #{I18n.t('person.import.invalid_line')}"
          next
        end

        p = Person.new

        col_id = r.id.try(:to_i)
        col_id = nil if col_id == 0

        p.id                 = col_id
        p.first_name         = r.first_name
        p.last_name          = r.last_name
        p.alias_name         = r.alias_name
        p.title              = r.title
        p.is_an_organization = ['1', 'true', 'True', 'TRUE', 'T'].include?(r.is_an_organization)
        p.organization_name  = r.organization_name
        p.address            = r.address
        p.phone              = r.phone
        p.second_phone       = r.second_phone
        p.mobile             = r.mobile
        p.fax_number         = r.fax_number
        p.email              = r.email
        p.second_email       = r.second_email
        p.birth_date         = r.birth_date
        p.nationality        = r.nationality
        p.avs_number         = r.avs_number
        p.gender             = !!['m', 'man', 'male', 'true', 't', 'True', 'T' '1'].index(r.gender)
        p.bank_informations  = r.bank_informations
        p.hidden             = !!['1', 'true', 'True', 't', 'T', 'yes'].include?(r.hidden)

        p.valid?

        parser = PersonRelationsParser.new(p)
        p.comments_edited_by_others << parser.parse_comments(r.comments)

        job = parser.parse_job(r.job)
        infos[:jobs] << job if job

        parser.parse_location(r.postal_code_prefix, r.location)
        parser.parse_roles(r.roles)
        parser.parse_main_communication_language(r.main_communication_language)
        parser.parse_communication_languages(r.communication_languages)

        private_tags = parser.parse_private_tags(r.private_tags)
        infos[:private_tags] << private_tags unless private_tags.empty?

        public_tags = parser.parse_public_tags(r.public_tags)
        infos[:public_tags]  << public_tags unless public_tags.empty?

        infos[:people] << p
      end
    rescue Exception => e
      infos[:errors] << I18n.t('person.import.cannot_parse')
      infos[:errors] << e.inspect
    end

    infos[:private_tags] = infos[:private_tags].flatten.uniq
    infos[:public_tags] = infos[:public_tags].flatten.uniq
    infos[:jobs].uniq!

    infos

  end

  ############
  ### LDAP ###
  ############

  # TODO if ldap_remove fails, raise an explicit error.
  def ldap_remove
    ldap = Rails.configuration.ldap_admin

    ldap.delete(dn: ldap_dn)
    return true if [0, 32].include?(ldap.get_operation_result.code)

    File.open("#{Rails.root.to_s}/log/ldap.log", 'a') do |f|
      f << Time.now.to_s + ": Cannot delete LDAP entry #{id}: error #{ldap.get_operation_result.code}, #{ldap.get_operation_result.message}"
    end
    false
  end

  def ldap_add
    ldap = Rails.configuration.ldap_admin

    return true if ldap.add(dn: ldap_dn, attributes: ldap_attributes)

    File.open("#{Rails.root.to_s}/log/ldap.log", 'a') do |f|
      f << Time.now.to_s + ": Cannot add LDAP entry #{id}: error #{ldap.get_operation_result.code}, #{ldap.get_operation_result.message}"
    end
    false
  end

  def ldap_update
    ldap_remove
    ldap_add
  end

  def ldap_attributes
    LdapAttribute.all.each_with_object({}) do |attr, h|
      key = attr.name.to_sym
      value = eval(attr.mapping)
      if value.is_a?(Array)
        value.reject!{ |s| s.blank? }
        h[key] = value unless value.empty?
      else
        h[key] = value unless value.blank?
      end
    end
  end

  def ldap_sn
    cn = last_name
    return cn unless cn.blank?
    return email unless email.blank?
    organization_name
  end

  def ldap_cn
    cn = "#{first_name} #{last_name}"
    return cn unless cn.blank?
    return email unless email.blank?
    organization_name
  end

  def ldap_dn
    "uid=#{ldap_attributes[:uid]},#{Rails.configuration.settings['ldap']['admin']['base']}"
  end


  ########################
  ### INSTANCE METHODS ###
  ########################

  def accessible_by
    roles = Role.all.select do |role|
      fake_user = OpenStruct.new(permissions: role.permissions)
      a = Ability.new(fake_user)
      a.can? :read, self
    end

    roles.map(&:name)
  end

  # attributes overridden - JSON API
  # FIXME: Move this to JBUILDER, extended attributes should only be used in views.
  def as_json(options = {})
    h = super({except: PROTECTED_ATTRIBUTES}.update(options || {}))

    if options
      unless options[:restricted_attributes]
        RESTRICTED_ATTRIBUTES.each { |s| h.delete(s) }
      end

      if options[:authenticate_using_token]
        h[:authentication_token] = authentication_token
      end
    end

    # add relation description to save a request
    h[:name] = name
    h[:location_name] = location.try(:full_name)
    h[:job_name] = job.try(:name)
    h[:address_for_bvr] = address_for_bvr
    h[:communication_language_ids] = communication_language_ids
    h[:errors] = errors
    h[:missing_employee_information] = missing_employee_information
    h[:geographic_coordinates] = geographic_coordinates
    h
  end

  # Returns organization name, full_name of email in order of availability.
  def name
    return organization_name if is_an_organization
    return full_name unless full_name.blank?
    return email
  end

  # Returns first name followed by last name separated by a space.
  def full_name
    [first_name, last_name].join(' ').strip
  end

  def has_password?
    !encrypted_password.blank?
  end

  def has_email?
    email != 'none' && !email.blank?
  end

  def has_no_email?
    !has_email?
  end

  def has_second_email?
    !second_email.blank?
  end

  # Return the address, postal code + location and country if not the same as this directory's owner.
  # Fields are separated by carriage returns.
  def full_address
    full_address_helper.join("\n")
  end

  # Like full_address except that fields are separated by comma ", " instead of carriage returns.
  def full_address_inline
    full_address_helper.join(", ")
  end

  # Returns organization_name + person name if existing.
  def address_name
    if is_an_organization
      names = [organization_name, full_name]
      names.delete("")
      names.join("\n")
    else
      full_name
    end
  end

  # Returns organization_name + person name with title if existing.
  def address_name_with_title
    if is_an_organization
      names = [organization_name]
      names << [title, full_name].join(' ').strip unless full_name.blank?
      names.join("\n")
    else
      [title, full_name].join(' ').strip
    end
  end

  # Returns address_name and full_address separated with carriage returns.
  def address_for_bvr
    [address_name, full_address].join("\n")
  end

  def geographic_coordinates
    [latitude, longitude].join(", ")
  end

  # affairs
  def paid_affairs
    get_affairs_from_status_names(:paid)
  end

  def unpaid_affairs
    get_affairs_from_status_names(:open)
  end

  def get_affairs_from_status_values(mask)
    affairs.where("(affairs.status::bit(16) & ?::bit(16))::int = ?", mask, mask)
  end

  def get_affairs_from_status_names(statuses)
    mask = Affair.statuses_value_for(statuses)
    get_affairs_from_status_values(mask)
  end

  def get_invoices_from_status_values(mask)
    invoices.where("(invoices.status::bit(16) & ?::bit(16))::int = ?", mask, mask)
  end

  def get_invoices_from_status_names(statuses)
    mask = Invoice.statuses_value_for(statuses)
    get_invoices_from_status_values(statuses)
  end

  # subscriptions
  def paid_subscriptions
    mask = Affair.statuses_value_for(:paid)
    subscriptions.joins(:affairs)
      .where("(affairs.status::bit(16) & ?::bit(16))::int = ?", mask, mask)
  end

  def unpaid_subscriptions
    mask = Affair.statuses_value_for(:open)
    subscriptions.joins(:affairs)
      .where("(affairs.status::bit(16) & ?::bit(16))::int = ?", mask, mask)
  end

  def subscriptions_as_buyer
    # affairs_as_buyer.select{|a| a.subscriptions}.flatten.uniq
    Subscription.joins(:affairs)
                .where('affairs.buyer_id = ?', self.id)
                .select("DISTINCT subscriptions.*")
  end

  def subscriptions_as_receiver
    # affairs_as_receiver.select{|a| a.subscriptions}.flatten.uniq
    Subscription.joins(:affairs)
                .where('affairs.receiver_id = ?', self.id)
                .select("DISTINCT subscriptions.*")
  end

  def age_at(date)
    # date should be UTC Date
    if birth_date.is_a? Date
      date.year - birth_date.year - (birth_date.to_date.change(year: date.year) > date ? 1 : 0)
    else
      nil
    end
  end

  def age
    age_at(Time.now.to_date)
  end

  def male?
    # this is unfair but not beeing a male means beeing a female in this world.
    # database allow undefined gender
    gender == true
  end

  # Returns a list of required fields which dependencies are not satisfied to act
  # as an employee
  def missing_employee_information
    required_fields = %w(first_name last_name address nationality avs_number bank_informations birth_date)

    required_fields.select do |rf|
      send(rf).blank?
    end
  end

  def can_have_salaries?
    missing_employee_information.size == 0
  end


  #######################
  ### API key renewal ###
  #######################

  attr_accessor :renew_authentication_token
  # FIXME This belongs to old protected_attributes, should be handled by strong attributes yet.
  # attr_protected :authentication_token

  #######################
  ### PRIVATE METHODS ###
  #######################
  private

  # Returns the address block with location and country if not the same as directory's owner.
  def full_address_helper
    arr = []
    arr << address unless address.blank?
    if location
      if location.postal_code_prefix
        arr << "#{location.postal_code_prefix} #{location.name}"
      else
        arr << location.name
      end
      country = location.country.try(:name)
      me = Person.find(ApplicationSetting.value("me"))
      if me.location
        if me.location.country.try(:name) != country and !location.is_country?
          arr << location.country.try(:name).try(:upcase)
        end
      end
    end
    arr
  end

  # API key renewal

  def nilify_authentication_token_if_blank
    authentication_token = nil if authentication_token.blank?
  end

  def reset_authentication_token_if_requested
    if new_record?
      authentication_token = nil
    else
      authentication_token = authentication_token_was
    end

    if renew_authentication_token == true
      self.authentication_token = generate_authentication_token
    end
  end

  def generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless Person.where(authentication_token: token).first
    end
  end

  def update_geographic_coordinates
    begin
      # FIXME remove this condition after 20131125214900_add_geolocalization migration
      if Person.columns.map(&:name).include?("latitude") \
        and Rails.configuration.settings['maps']['enable_geolocalization']
        if (address_changed? or location_id_changed?) or (address and location_id and latitude.nil?)
          loc = Geokit::Geocoders::OSMGeocoder.geocode full_address_inline
          if loc.success
            self.latitude = loc.lat
            self.longitude = loc.lng
          end
        end
      end
    rescue
      # NOTE do not fail, on network failure for instance
    end
  end

  def cannot_use_same_first_name_and_last_name_unless_has_email
    if email.blank? &&
       organization_name.blank? &&
       !full_name.blank? &&
       Person.where(first_name: first_name, last_name: last_name)
             .where(Person.arel_table[:id].not_eq(id)).size > 0
      errors.add(:base, I18n.t('person.errors.combination_of_first_name_and_last_name_already_taken'))
      false
    end
  end

  def is_an_organization_is_ticked_if_has_name_and_no_person_info
    if full_name.blank? && !organization_name.blank? && !is_an_organization
      errors.add(:is_an_organization,
                 I18n.t('person.errors.organization_not_ticked_but_no_person_info'))
      false
    end
  end

  def do_not_remove_admin_role_for_first_admin
    if id == ApplicationSetting.value(:me) and roles.find{|r| r.name == 'admin' }.nil?
      errors.add(:role,
                 I18n.t('person.errors.cannot_remove_admin_role_for_first_user'))
      false
    end
  end

  def avs_number_format
    # AVS number is encoded with EAN-13
    # http://en.wikipedia.org/wiki/International_Article_Number_(EAN)
    if !avs_number.blank?
      if avs_number.match /^756\.[0-9]{4}\.[0-9]{4}\.[0-9]{2}$/
        # 756.4914.4096.30
        unique_code = avs_number.split(".").join[0..-2]

        # not very optimized, but who cares for a time-to-time validation ?
        odds = evens = 0
        index = 1
        unique_code.each_char do |c|
          if index.even? # index % 2 == 0
            evens += c.to_i
          else
            odds += c.to_i
          end
          index += 1
        end

        key = (evens * 3 + odds) % 10

        if avs_number[-1].to_i != (10 - key) % 10
          errors.add(:avs_number,
            I18n.t("person.errors.avs_number_control_key_is_invalid"))
          false
        end
      else
        errors.add(:avs_number,
          I18n.t("person.errors.avs_number_is_invalid"))
        false
      end
    end
  end

  # we only accept second email if principal email exists
  def email_exists_if_it_has_a_second_email
    unless second_email.blank?
      unless has_email?
        errors.add(:second_email,
                   I18n.t('person.errors.no_second_email_if_no_primary_email'))
        false
      end
    end
  end

  # email is required if this person is loggable (has a password)
  def email_required_if_it_is_loggable
    unless encrypted_password.blank?
      unless has_email?
        errors.add(:email,
                   I18n.t('person.errors.an_email_is_required_if_it_is_loggable'))
        false
      end
    end
  end

  def cannot_use_existing_email
    if !email.blank? && Person.find_by_second_email(email)
      errors.add(:email, I18n.t('activerecord.errors.messages.taken'))
      false
    end
    if !second_email.blank? && Person.find_by_email(second_email)
      errors.add(:second_email, I18n.t('activerecord.errors.messages.taken'))
      false
    end
  end

  def second_email_is_different
    if email == second_email
      errors.add(:second_email, I18n.t('person.errors.second_email_should_be_different'))
      false
    end
  end

  def has_org_name_if_is_an_org_is_set
    if is_an_organization == true and organization_name.blank?
      errors.add(:is_an_organization,
                 I18n.t('person.errors.cant_be_org_without_org_name'))
      false
    end
  end

  def main_language_is_not_in_communication_languages
    if communication_languages.to_a.index(main_communication_language)
      errors.add(:main_communication_language,
                 I18n.t('person.errors.main_language_already_in_communication_languages'))
      return false
    end
  end

  def do_not_destroy_if_has_invoices
    unless invoices.empty?
      errors.add(:base,
                 I18n.t('person.errors.cant_delete_person_who_has_invoices'))
      false
    end
  end

  def do_not_destroy_if_has_salaries
    unless salaries.empty?
      errors.add(:base,
                 I18n.t('person.errors.cant_delete_person_who_has_salaries'))
      false
    end
  end

  def do_not_destroy_if_first_admin
    if id == ApplicationSetting.value("me").to_i
      errors.add(:base,
                 I18n.t('person.errors.cant_delete_first_admin'))
      false
    end
  end

  def do_not_destroy_if_has_running_contracts
    employment_contracts.each do |ec|
      if ec.is_running?
        errors.add(:base,
                  I18n.t('person.errors.cant_delete_person_who_has_running_contract'))
        false
      end
    end
  end

  def do_not_destroy_if_linked_to_products
    if products_to_sell.count > 0 or products_to_maintain.count > 0
      errors.add(:base,
        I18n.t('person.errors.cant_delete_person_who_is_linked_to_products'))
      false
    end
  end

  def clear_affairs_as_buyer_and_affairs_as_receiver
    self.affairs_as_receiver.each do |a|
      a.update_attributes(receiver_id: a.owner_id)
    end
    self.affairs_as_buyer.each do |a|
      a.update_attributes(buyer_id: a.owner_id)
    end
  end

  def verify_employee_information
    if salaries.size > 0 and missing_employee_information.size > 0
      missing_employee_information.map do |f|
        field = I18n.t("activerecord.attributes.person." + f)
        errors.add(f.to_sym,
                    I18n.t('person.errors.the_required_information_about_this_employee_are_not_satisfied',
                      field: field ))
      end

      false
    end
  end

  # Recursive!
  def select_parents(tag)
    rel = tag.class.to_s.underscore.pluralize
    self.send(rel).push tag.parent if tag.parent
  end

end
