class Ability

  ################
  ### INCLUDES ###
  ################

  include CanCan::Ability


  ########################
  ### INSTANCE METHODS ###
  ########################

  def initialize(user)
    user.permissions.each do |permission|
      can permission.action.to_sym, permission.cancan_subject, eval(permission.hash_conditions || '')
    end
  end

end
