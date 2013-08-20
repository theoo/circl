Date::DATE_FORMATS[:default] = '%d-%m-%Y'
Time::DATE_FORMATS[:default] = '%d-%m-%Y %H:%M'

# Monkey patcher
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
