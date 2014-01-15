=begin
  CIRCL Directory
  Copyright (C) 2011 Complex IT sàrl

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU Affero General Public License as
  published by the Free Software Foundation, either version 3 of the
  License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Affero General Public License for more details.

  You should have received a copy of the GNU Affero General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end

# == Schema Information
#
# Table name: people
#
# *id*::                             <tt>integer, not null, primary key</tt>
# *job_id*::                         <tt>integer</tt>
# *location_id*::                    <tt>integer</tt>
# *main_communication_language_id*:: <tt>integer</tt>
# *is_an_organization*::             <tt>boolean, default(FALSE), not null</tt>
# *organization_name*::              <tt>string(255), default("")</tt>
# *title*::                          <tt>string(255), default("")</tt>
# *first_name*::                     <tt>string(255), default("")</tt>
# *last_name*::                      <tt>string(255), default("")</tt>
# *phone*::                          <tt>string(255), default("")</tt>
# *second_phone*::                   <tt>string(255), default("")</tt>
# *mobile*::                         <tt>string(255), default("")</tt>
# *email*::                          <tt>string(255), default(""), not null</tt>
# *second_email*::                   <tt>string(255), default("")</tt>
# *address*::                        <tt>text, default("")</tt>
# *birth_date*::                     <tt>date</tt>
# *nationality*::                    <tt>string(255), default("")</tt>
# *avs_number*::                     <tt>string(255), default("")</tt>
# *bank_informations*::              <tt>text, default("")</tt>
# *encrypted_password*::             <tt>string(128), default(""), not null</tt>
# *reset_password_token*::           <tt>string(255)</tt>
# *reset_password_sent_at*::         <tt>datetime</tt>
# *remember_created_at*::            <tt>datetime</tt>
# *sign_in_count*::                  <tt>integer, default(0)</tt>
# *current_sign_in_at*::             <tt>datetime</tt>
# *last_sign_in_at*::                <tt>datetime</tt>
# *current_sign_in_ip*::             <tt>string(255)</tt>
# *last_sign_in_ip*::                <tt>string(255)</tt>
# *password_salt*::                  <tt>string(255)</tt>
# *failed_attempts*::                <tt>integer, default(0)</tt>
# *unlock_token*::                   <tt>string(255)</tt>
# *locked_at*::                      <tt>datetime</tt>
# *authentication_token*::           <tt>string(255)</tt>
# *created_at*::                     <tt>datetime</tt>
# *updated_at*::                     <tt>datetime</tt>
# *hidden*::                         <tt>boolean, default(FALSE), not null</tt>
# *gender*::                         <tt>boolean</tt>
#--
# == Schema Information End
#++


class Person < ActiveRecord::Base

  ################
  ### INCLUDES ###
  ################

  # Inclusion order matter
  include ChangesTracker
  include Tire::Model::Callbacks
  include ElasticSearch::Mapping
  include ElasticSearch::Indexing

  attr_accessor :notices

  def initialize(params = nil)
    super(params)
    @notices = ActiveModel::Errors.new(self)
  end

  #################
  ### CALLBACKS ###
  #################

  # person
  before_destroy :do_not_destroy_if_has_invoices
  before_destroy :do_not_destroy_if_has_salaries
  before_destroy :do_not_destroy_if_first_admin
  # TODO remove password if removing last email.

  # employment_contracts
  before_destroy :do_not_destroy_if_has_running_contracts
  before_destroy :clear_affairs_as_buyer_and_affairs_as_receiver

  before_destroy do
    roles.clear
    communication_languages.clear
    private_tags.clear
    public_tags.clear
  end

  # API key
  before_validation :nilify_authentication_token_if_blank
  before_save :reset_authentication_token_if_requested, :verify_employee_information, :update_geographic_coordinates

  # LDAP
  if Rails.configuration.ldap_enabled
    after_save :ldap_update, :unless => "tracked_changes.empty?"
    before_destroy :ldap_remove
  end

  #################
  ### RELATIONS ###
  #################

  # Common
  belongs_to  :job
  belongs_to  :location
  belongs_to  :main_communication_language,
              :class_name => 'Language'

  has_many    :employment_contracts,
              :dependent => :destroy

  # logs what this "user" have done (to any entry)
  has_many    :activities,
              :order => 'created_at DESC',
              :limit => '100',
              :dependent => :destroy

  # logs what this person's entry have undergone
  has_many    :alterations,
              :class_name => 'Activity',
              :as => :resource,
              :order => 'created_at DESC',
              :limit => '100',
              :dependent => :destroy

  # comments made by this person
  has_many    :edited_comments,
              :class_name => 'Comment',
              :dependent => :destroy

  # comments made by someone else on this entry
  has_many    :comments_edited_by_others,
              :class_name => 'Comment',
              :as => :resource,
              :dependent => :destroy

  has_many  :translation_aptitudes,
            :dependent => :destroy
  accepts_nested_attributes_for :translation_aptitudes

  monitored_habtm :roles,
                  :after_add => :update_elasticsearch_index,
                  :after_remove => :update_elasticsearch_index
  has_many  :people_roles # for permissions

  has_many  :permissions,
            :through => :roles,
            :uniq => true

  monitored_habtm :public_tags,
                  :uniq => true,
                  :after_add => :update_elasticsearch_index,
                  :after_remove => :update_elasticsearch_index

  monitored_habtm :private_tags,
                  :uniq => true,
                  :after_add => :update_elasticsearch_index,
                  :after_remove => :update_elasticsearch_index

  has_many  :people_public_tags # for permissions
  has_many  :people_private_tags # for permissions

  # secondary communication languages
  monitored_habtm :communication_languages,
                  :class_name => 'Language',
                  :join_table => 'people_communication_languages',
                  :uniq => true,
                  :after_add => :update_elasticsearch_index,
                  :after_remove => :update_elasticsearch_index

  has_many  :people_communication_languages # for permissions

  # Financial
  has_many    :affairs,
              :foreign_key => :owner_id,
              :dependent => :destroy

  has_many    :affairs_as_buyer,
              :class_name => 'Affair',
              :foreign_key => :buyer_id

  has_many    :affairs_as_receiver,
              :class_name => 'Affair',
              :foreign_key => :receiver_id

  has_many    :invoices,
              :through => :affairs,
              :foreign_key => 'owner_id',
              :uniq => true

  has_many    :receipts,
              :through => :invoices,
              :uniq => true

  has_many    :subscriptions,
              :through => :affairs,
              :uniq => true

  # Salaries
  has_many    :salaries,
              :class_name => 'Salaries::Salary',
              :dependent => :destroy

  has_many    :background_tasks

  # tasks this person have edited
  has_many    :executed_tasks,
              :class_name => '::Task',
              :foreign_key => 'executer_id',
              :dependent => :destroy

  # tasks made for this person, the client
  has_many    :tasks,
              :through => :affairs

  has_many    :products_to_sell,  :class_name => 'Product',
                                  :foreign_key => :provider_id

  has_many    :products_to_maintain,  :class_name => 'Product',
                                      :foreign_key => :after_sale_id

  belongs_to  :task_rate


  ##################
  ### NAMESCOPES ###
  ##################

  scope :hidden, where(:hidden => true)
  scope :visible, where("hidden is NULL OR hidden IN ('false', 'f', '0')")

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :encryptable, :lockable,
         :recoverable, :rememberable, :trackable, :timeoutable, :token_authenticatable


  ###################
  ### VALIDATIONS ###
  ###################

  validates_with PresenceOfIdentifierValidator
  validates_with FullNameValidator
  validates_with DateValidator, :attribute => :birth_date

  validates_with PhoneValidator, :attribute => :phone
  validates_with PhoneValidator, :attribute => :second_phone
  validates_with PhoneValidator, :attribute => :mobile

  validate :cannot_use_same_first_name_and_last_name_unless_has_email

  validate :is_an_organization_is_ticked_if_has_name_and_no_person_info

  validate :do_not_remove_admin_role_for_first_admin

  validate :email_exists_if_it_has_a_second_email
  validate :email_required_if_it_is_loggable
  validate :cannot_use_existing_email
  validates_uniqueness_of :authentication_token, :allow_nil => true
  validates_uniqueness_of :email, :if => :has_email?
  validates_uniqueness_of :second_email, :if => :has_second_email?
  validates_format_of :email, :with => FormatValidations::EMAIL_REGEX, :if => :has_email?
  validates_format_of :second_email, :with => FormatValidations::EMAIL_REGEX, :if => :has_second_email?
  validate :avs_number_format
  validate :second_email_is_different, :if => lambda { has_email? && has_second_email? }
  validate :has_org_name_if_is_an_org_is_set
  validate :main_language_is_not_in_communication_languages
  validates_strength_of :password, :with => :email, :if => lambda { !password.blank? }
  validates_confirmation_of :password

  # Validate fields of type 'string' length
  validates_length_of :organization_name, :maximum => 255
  validates_length_of :title, :maximum => 255
  validates_length_of :first_name, :maximum => 255
  validates_length_of :last_name, :maximum => 255
  validates_length_of :phone, :maximum => 255
  validates_length_of :second_phone, :maximum => 255
  validates_length_of :mobile, :maximum => 255
  validates_length_of :email, :maximum => 255
  validates_length_of :second_email, :maximum => 255
  validates_length_of :nationality, :maximum => 255
  validates_length_of :avs_number, :maximum => 255

  # Validate fields of type 'text' length
  validates_length_of :address, :maximum => 65535
  validates_length_of :bank_informations, :maximum => 65535


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

    begin
      CSV.parse(data, :encoding => 'UTF-8')[1..-1].each_with_index do |row, i|
        if row.size < 25
          infos[:errors] << "#{I18n.t('person.import.line')} #{i+2}: #{I18n.t('person.import.invalid_line')}"
          next
        end

        row.map! { |s| (s || '').force_encoding('utf-8').strip }

        p = Person.new

        p.first_name         = row[0]
        p.last_name          = row[1]
        p.title              = row[2]
        p.is_an_organization = ['1', 'true'].include?(row[3])
        p.organization_name  = row[4]
        p.address            = row[5]
        p.phone              = row[8]
        p.second_phone       = row[9]
        p.mobile             = row[10]
        p.email              = row[11]
        p.second_email       = row[12]
        p.birth_date         = row[14]
        p.nationality        = row[15]
        p.avs_number         = row[16]
        p.bank_informations  = row[17]
        p.hidden             = ['1', 'true'].include?(row[24])

        p.valid?

        parser = PersonRelationsParser.new(p)
        parser.parse_location(row[6], row[7])
        parser.parse_job(row[13])
        parser.parse_roles(row[18])
        parser.parse_main_communication_language(row[19])
        parser.parse_communication_languages(row[20])
        parser.parse_translation_aptitudes(row[21])
        infos[:private_tags] << parser.parse_private_tags(row[22])
        infos[:public_tags]  << parser.parse_public_tags(row[23])

        infos[:people] << p
      end
    rescue Exception => e
      infos[:errors] << I18n.t('person.import.cannot_parse')
      infos[:errors] << e.inspect
    end

    infos[:private_tags].flatten!.uniq!
    infos[:public_tags].flatten!.uniq!

    infos

  end

  ############
  ### LDAP ###
  ############

  def ldap_remove
    ldap = Rails.configuration.ldap_admin

    ldap.delete(:dn => ldap_dn)
    return true if [0, 32].include?(ldap.get_operation_result.code)

    File.open("#{Rails.root.to_s}/log/ldap.log", 'a') do |f|
      f << Time.now.to_s + ": Cannot delete LDAP entry #{id}: error #{ldap.get_operation_result.code}, #{ldap.get_operation_result.message}"
    end
    false
  end

  def ldap_add
    ldap = Rails.configuration.ldap_admin

    return true if ldap.add(:dn => ldap_dn, :attributes => ldap_attributes)

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
      fake_user = OpenStruct.new(:permissions => role.permissions)
      a = Ability.new(fake_user)
      a.can? :read, self
    end

    roles.map(&:name)
  end

  # attributes overridden - JSON API
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

  # name return organization name, full_name of email in order of availability.
  def name
    return organization_name if is_an_organization
    return full_name unless full_name.blank?
    return email
  end

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

  def full_address
    full_address_helper.join("\n")
  end

  def full_address_inline
    full_address_helper.join(", ")
  end

  # organization_name plus person name if existing
  def address_name
    if is_an_organization
      names = [organization_name, full_name]
      names.delete("")
      names.join("\n")
    else
      full_name
    end
  end

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
      date.year - birth_date.year - (birth_date.to_date.change(:year => date.year) > date ? 1 : 0)
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
  attr_protected :authentication_token

  #######################
  ### PRIVATE METHODS ###
  #######################
  private

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
          arr << location.country.try(:name)
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
      reset_authentication_token # devise method
    end
  end

  def update_geographic_coordinates
    # FIXME remove this condition after 20131125214900_add_geolocalization migration
    if Person.columns.map(&:name).include?("latitude")
      if (address_changed? or location_id_changed?) or (address and location_id and latitude.nil?)
        loc = Geokit::Geocoders::OSMGeocoder.geocode full_address_inline
        if loc.success
          self.latitude = loc.lat
          self.longitude = loc.lng
        end
      end
    end
  end

  def cannot_use_same_first_name_and_last_name_unless_has_email
    if email.blank? &&
       organization_name.blank? &&
       !full_name.blank? &&
       Person.where(:first_name => first_name, :last_name => last_name)
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
    if communication_languages.index(main_communication_language)
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
    if id == 1 # FIXME don't hardcode this
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
        return false
      end
    end
  end

  def clear_affairs_as_buyer_and_affairs_as_receiver
    self.affairs_as_receiver.each do |a|
      a.update_attributes(:receiver_id => a.owner_id)
    end
    self.affairs_as_buyer.each do |a|
      a.update_attributes(:buyer_id => a.owner_id)
    end
  end

  def verify_employee_information
    if salaries.size > 0 and missing_employee_information.size > 0
      missing_employee_information.map do |f|
        field = I18n.t("activerecord.attributes.person." + f)
        errors.add(f.to_sym,
                    I18n.t('person.errors.the_required_information_about_this_employee_are_not_satisfied',
                      :field => field ))
      end

      false
    end
  end

end
