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

class ApplicationController < ActionController::Base

  # parameters validation
  class InvalidParameters < StandardError; end

  protect_from_forgery

  before_filter :authenticate_person_from_token!
  before_filter :authenticate_person!
  before_filter :set_locale
  before_filter :route_browser
  before_filter :cleanup_session

  protected

  TEMPLATES_PLACEHOLDER_OPTIONS_REGEX = "\{([a-zA-Z0-9,.\(\) |_]+)\}"

  def self.model
    name = to_s.sub('Controller', '').underscore.split('/').last.singularize.camelize
    begin
      name.constantize
    rescue
      name
    end
  end

  # alias current_user current_person
  def current_ability
    @current_ability ||= Ability.new(current_person)
  end

  # fail gracefully when error happen
  unless Rails.configuration.consider_all_requests_local
    # Order matter, StandardError must be first!

    # Simple method to collect error messages on email admin.
    # rescue_from StandardError do |exception|
    #   PersonMailer.send_report_error_to_admin(current_person, exception).deliver
    #   raise exception
    # end

    rescue_from CanCan::AccessDenied do |exception|
      respond_to do |format|
        format.html { render file: "#{Rails.root}/public/403.html.haml", layout: 'errors' } # status => 403 disabled
        format.json { render json: {base: [I18n.t("permission.errors.forbidden")]}, status: :forbidden }
      end
    end

    rescue_from ActiveRecord::RecordNotFound do |exception|
      respond_to do |format|
        format.html { render file: "#{Rails.root}/public/404_record_not_found.html.haml", layout: 'errors' }
        format.json { render json: {base: [I18n.t("permission.errors.record_not_found")]}, status: :not_found }
      end
    end

    rescue_from ApplicationSetting::MissingAttribute do |exception|
      @exception = exception
      respond_to do |format|
        format.html { render file: "#{Rails.root}/public/404_attribute_not_found.html.haml", layout: 'errors' }
        format.json { render json: "ApplicationSetting: " + @exception.to_s, status: :not_found }
      end
    end

    rescue_from ActionController::RoutingError do |exception|
      respond_to do |format|
        format.html { render file: "#{Rails.root}/public/404.html.haml", layout: 'errors' }
        format.json { render json: {base: [I18n.t("permission.errors.record_not_found")]}, status: :not_found }
      end
    end

    rescue_from ApplicationController::InvalidParameters do |exception|
      respond_to do |format|
        format.html { render file: "#{Rails.root}/public/400.html.haml", layout: 'errors' }
        format.json { render json: {base: [I18n.t("permission.errors.invalid_parameters")]}, status: :bad_request }
      end
    end
  end

  def default_locale
    current_person.try(:main_communication_language).try(:code).try(:downcase) ||
    extract_locale_from_accept_language_header ||
    ApplicationSetting.value(:default_locale)
  end

  def set_locale
    locale = params[:locale] if params[:locale]
    locale ||= default_locale
    I18n.locale = locale
  end

  def route_browser
    user_agent = request.env['HTTP_USER_AGENT'] ? request.env['HTTP_USER_AGENT'].downcase : 'nil'

    user_browser ||= begin
      if user_agent.index('msie') && !user_agent.index('opera') && !user_agent.index('webtv')
        'ie'+user_agent[user_agent.index('msie')+5].chr
      elsif user_agent.index('gecko/')
        'gecko'
      elsif user_agent.index('opera')
        'opera'
      elsif user_agent.index('konqueror')
        'konqueror'
      elsif user_agent.index('ipod')
        'ipod'
      elsif user_agent.index('ipad')
        'ipad'
      elsif user_agent.index('iphone')
        'iphone'
      elsif user_agent.index('chrome/')
        'chrome'
      elsif user_agent.index('applewebkit/')
        'safari'
      elsif user_agent.index('googlebot/')
        'googlebot'
      elsif user_agent.index('msnbot')
        'msnbot'
      elsif user_agent.index('yahoo! slurp')
        'yahoobot'
      #Everything thinks it's mozilla, so this goes last
      elsif user_agent.index('mozilla/')
        'gecko'
      else
        'unknown'
      end
    end

    unless %w(chrome gecko konqueror safari opera ipad iphone ipod unknown).index(user_browser)
      redirect_to requires_browser_update_settings_path
    end

  end

  # returns a CSV string when giving an ActiveRecord Object array
  # TODO move me into a lib/helper
  def csv_ify(ary, fields)
    CSV.generate(encoding: 'UTF-8') do |csv|
      # header
      # TODO: i18n?
      csv << fields.map{|e| e.to_s.humanize}

      # content
      ary.each do |object|
        line = []
        fields.each {|f| line << eval("object." + f.to_s) } # FIXME could be a security issue
        csv << line
      end
    end
  end

  def validate_date_format(date)
    date.match /^[0-3][0-9]-[0-1][0-9]-[0-9]{1,4}$/
  end

  def extract_locale_from_accept_language_header
    language = request.env['HTTP_ACCEPT_LANGUAGE']
    language.scan(/^[a-z]{2}/).first if language
  end

  # TODO: Re-enable monitor change and ChangesTracker with a version which allows rollback
  # Monitor changes disabled
  def self.monitor_changes(instance_name, options = { only: [:create, :update, :destroy] })
    return # disabled
  end

  # For every session variables, ensure it is removed if the context doesn't needs it anymore
  # TODO add all variable
  def cleanup_session
    session[:pagination] = {} unless request.path == paginate_people_path
  end

  private

  def validate_presence_of(required_elements, hash)
    required_elements.each do |re|
      if re.is_a? Hash
        re.each do |k,v|
          validate_presence_of v, hash[k]
        end
      else
        unless [Symbol, String].index(re.class)
          raise ArgumentError, 'invalid parameters list'
        end

        unless hash.keys.index(re)
          raise InvalidParameters, "Missing parameter: " + re.inspect
        end
      end
    end
  end


  # Token authentication replacement (Devise removed its support)
  def authenticate_person_from_token!
    person_email = params[:person_email].presence
    person       = person_email && Person.where(email: person_email).try(:first)

    # Notice how we use Devise.secure_compare to compare the token
    # in the database with the token given in the params, mitigating
    # timing attacks.
    if person && Devise.secure_compare(person.authentication_token, params[:person_token])
      sign_in person, store: false
    end
  end

end
