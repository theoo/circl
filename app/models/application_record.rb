class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  EMAIL_REGEX = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i

end