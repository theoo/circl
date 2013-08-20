module ControllerMacros
  def login_admin
    before(:each) do
      @request.env['HTTP_USER_AGENT'] = 'chrome/'
      @request.env['devise.mapping'] = Devise.mappings[:admin]
      sign_in Person.find_by_email('admin@circl.ch') || FactoryGirl.create(:person, :admin)
    end
  end
end

RSpec.configure do |config|
  config.include Devise::TestHelpers, :type => :controller
  config.extend ControllerMacros, :type => :controller
end
