require 'spec_helper'

describe PeopleController, "for first time user: password creation process" do

  #def valid_user_attributes
  #  {:first_name => "bob", :last_name => "marley", :email => "bob@bob.ch"}
  #end

  #describe "GET password_request" do
  #  it "should always be a success (accessible to everyone)" do
  #    get :password_request
  #    response.should be_success
  #  end
  #end

  #describe "POST create_password" do
  #  describe "with valid params" do

  #    it 'should generate a new password' do
  #      valid_user = Person.create!(valid_user_attributes)
  #      post :create_password, :email => valid_user_attributes[:email]
  #      valid_user.reload
  #      valid_user.has_password?.should be_true
  #    end

  #    it 'should redirect to root' do
  #      pending "discuss"
  #      #valid_user = Person.create(valid_user_attributes)
  #      #post :create_password, :email => valid_user_attributes[:email]
  #      #response.should redirect_to(root_url)
  #    end

  #    it 'should send a mail???' do
  #      pending "discuss"
  #    end

  #  end

  #  describe "with invalid params" do
  #    it 'should re-render the password_request page' do
  #      post :create_password, :email => ""
  #      response.should render_template(:password_request)
  #    end
  #  end

  #end

end
