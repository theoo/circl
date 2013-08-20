# Allow any class to inherit the status manipulation methods.
# Requires a 'status' attribute as unsigned int(16)
module StatusExtention

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    # Required method on extended class. Should return an array of symbols.
    def available_statuses
      raise NotImplementedError, 'you need to subclass & overload this method'
    end

    # Returns bit position (index) of each status in words.
    def statuses_value_for(*words)
      words = [words].flatten

      bit_weight = 0

      words.each do |word|
        bit = available_statuses.index(word.to_sym)
        if bit.nil? or word.nil?
          raise ArgumentError, "Undefined status, available status are #{available_statuses.inspect}"
        end
        # set the 'bit' position to 1
        bit_weight |= 1 << bit
      end

      bit_weight
    end

    # Returns status name(s) as an array of symbol for the given value(s).
    def status_names_for(integer)
      current_statuses = []
      16.times do |i|
        # if the bit position (1 << i) is set in
        # the variable status it returns its position value.
        # So if the value returned is greater than zero, the bit is set.
        if (integer & 1 << i) > 0
          current_statuses << available_statuses[i]
        end
      end
      current_statuses
    end
  end

  ########################
  ### INSTANCE METHODS ###
  ########################

  # Gets statuses as an array of sym (words).
  def get_statuses
    self.class.status_names_for(status)
  end

  # Sets statuses by passing it a word or an array of words.
  def set_statuses(*words)
    self.status |= self.class.statuses_value_for(words)
  end

  # Set statuses as described in set_statuses and update database right away.
  def set_statuses!(*words)
    self.update_attribute(:status, (status | self.class.statuses_value_for(words)))
  end

  # Replace statuses by the given words or array of words.
  # If no word given, all statuses are erased.
  def reset_statuses(*words)
    self.status = self.class.statuses_value_for(words)
  end

  # Reset statuses as described in reset_statuses and update database right away.
  def reset_statuses!(*words)
    self.update_attribute(:status, self.class.statuses_value_for(words))
  end

  def has_status?(status)
    status = status.to_sym
    get_statuses.index(status) ? true : false
  end

end