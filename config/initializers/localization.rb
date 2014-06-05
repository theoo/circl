Date::DATE_FORMATS[:default] = '%d-%m-%Y'
Time::DATE_FORMATS[:default] = '%d-%m-%Y %H:%M'

class ActiveSupport::TimeWithZone
  def as_json(options = {})
    strftime(Time::DATE_FORMATS[:default])
  end
end

class Date
  def as_json(options = {})
    strftime(Date::DATE_FORMATS[:default])
  end
end

# NOTE Turn off deprecation message
I18n.enforce_available_locales = false