module ResqueHelper

  def self.included(base)
    base.include(Resque::Plugins::Status)
  end

  #
  # Validate input Hash using required Array and load Hash's key as instance variable
  # @param params [Hash] a list of parameters
  # @param required [Array] a list of required keys in params Hash
  #
  # @return [Boolean] true if validation succeed
  def validates(params, required)
    params.symbolize_keys!

    raise ArgumentError, "Expecting a Hash with at least #{required.inspect} keys." unless params.is_a? Hash
    required.each do |r|
      raise ArgumentError, "#{r.inspect} parameter required." unless params.include?(r)
      instance_variable_set("@#{r}", params[r]) unless params[r].blank?
    end

  end

end