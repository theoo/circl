require 'spec_helper'

describe Person do

  describe 'it should have at least an organization_name, a full_name or an email' do
    it 'has no attributes it should not be valid' do
      subject.should have(1).error_on(:base)
    end
    it 'has empty attributes it should not be valid' do
      subject.organization_name = ''
      subject.should have(1).error_on(:base)
    end
  end

  describe 'validate full name' do

    it 'should have a last name if there is a first name' do
      subject.first_name = "bob"
      subject.should have(1).error_on(:last_name)
    end

    it 'should not accept an empty string for the last_name' do
      subject.first_name = "bob"
      subject.last_name = ""
      subject.should have(1).error_on(:last_name)
    end

    it 'should have a first name if there is a last name and' do
      subject.last_name = "marley"
      subject.should have(1).error_on(:first_name)
    end

    it 'should not accept an empty string for the first_name' do
      subject.last_name = "marley"
      subject.first_name = ""
      subject.should have(1).error_on(:first_name)
    end

    it 'should have no errors if both first_name and last_name are provided' do
      subject.first_name = 'bob'
      subject.last_name = 'marley'
      subject.should have(0).error_on(:first_name)
      subject.should have(0).error_on(:last_name)
    end
  end

  describe 'validations' do
    it 'should not be able to set second_email if email is null' do
      subject.second_email = "bob@bob.ch"
      subject.should have(1).error_on(:second_email)
    end

    it 'should have a uniq email if it has an email' do
      person1 = Person.create(:email => "bob@bob.ch")
      person2 = Person.create(:email => "bob@bob.ch")
      person2.should have(1).error_on(:email)
    end

    it 'should have an email if this person is loggable (and have a password)' do
      person = Person.create(:first_name => "Bob", :last_name => "Robert",
                             :password => "1234", :password_confirmation => "1234")
      person.should have(1).error_on(:email)
    end

    it 'has a valid email if there is an email' do
      subject.email = "not_an_email"
      subject.should have(1).error_on(:email)
    end

    it 'has a valid second email if there is a second email' do
      subject.email = "bob@bob.ch"
      subject.second_email = "not_an_email"
      subject.should have(1).error_on(:second_email)
    end

    it 'if it has a phone number, it should conform to valid international format' do
      # No need to be paranoiac here
      # the Regex is in lib/phone_validator.rb

      # GOOD
      subject.phone = "+41223216274"
      subject.second_phone = "0223216272"
      subject.mobile = "0041791234567"
      subject.phone.should =~ /^\+?[\d\s]{7,18}$/
      subject.second_phone.should =~ /^\+?[\d\s]{7,18}$/
      subject.mobile.should =~ /^\+?[\d\s]{7,18}$/

      subject.phone = "+41 22 321 62 74"
      subject.phone.should =~ /^\+?[\d\s]{7,18}$/

      subject.phone = "tel +41223216274"
      subject.second_phone = "72"
      subject.mobile = "+41.79.123.45.67"

      # BAD
      subject.phone.should_not =~ /^\+?[\d\s]{7,18}$/
      subject.second_phone.should_not =~ /^\+?[\d\s]{7,18}$/
      subject.mobile.should_not =~ /^\+?[\d\s]{7,18}$/

      subject.mobile = "+41/79/123/45/67"
      subject.mobile.should_not =~ /^\+?[\d\s]{7,18}$/
    end

    it 'allows second_email to be nil' do
      subject.should have(0).errors_on(:second_email)
    end

    it 'must have an organization name if it is an organization' do
      subject.organization_name = nil
      subject.is_an_organization = true
      subject.should have(1).error_on(:is_an_organization)
    end

    it 'should not be possible to select the main language in the second languages list' do
      Language.create!(:name => "test")
      lang = Language.where(:name => 'test').first
      subject.main_communication_language = lang
      subject.communication_languages << lang
      subject.should have(1).error_on(:main_communication_language)
      Language.where(:name => "test").first.destroy
    end

    generate_length_tests_for :organization_name, :title, :first_name, :last_name, :phone, :second_phone,
                              :mobile, :email, :second_email, :nationality, :avs_number,
                              :maximum => 255

    generate_length_tests_for :address, :bank_informations, :maximum => 65536

  end

  describe 'callbacks' do
    describe 'should not be deletable if' do

      let(:invoice) { FactoryGirl.create(:invoice) }
      let(:salary) do
        ref = FactoryGirl.create(:reference_salary, :default)
        FactoryGirl.create(:salary, :reference => ref)
      end

      let(:employment_contract) { FactoryGirl.create(:employment_contract, :current) }

      it 'has any invoices' do
        invoice.reload # person is created when loading
        expect{ invoice.owner.destroy }.to change{Person.count}.by(0)
      end

      it 'has any salaries' do
        salary.reload # person is created when loading
        expect{ salary.person.destroy }.to change{Person.count}.by(0)
      end

      it 'it has still running employment contract' do
        employment_contract.reload # person is created when loading
        expect{ employment_contract.person.destroy }.to change{Person.count}.by(0)
      end

    end

    describe 'on destroy, it should' do
      let(:comment) { FactoryGirl.create(:comment) }

      it 'removes comment made by this person' do
        comment.person.destroy
        Comment.all.should_not include(comment)
      end

      it 'removes comment made on this person' do
        comment.resource.destroy
        Comment.all.should_not include(comment)
      end

      it 'clear what this person have made' do
        p = FactoryGirl.create(:person)
        a = Activity.create(:person => p,
                            :resource => p,
                            :action => 'update',
                            :data => {:first_name => {"Test" => "Test2"}})
        # Using FactoryGirl, activities are not updated... !?!
        p.activities.reload

        p.activities.size.should == 1
        p.destroy
        Activity.where(:person_id => p).count.should eq(0)
      end

      it 'removes what this person have undergone' do
        m = FactoryGirl.create(:person)
        p = FactoryGirl.create(:person)
        a = Activity.create(:person => m,
                            :resource => p,
                            :action => 'update',
                            :data => {:first_name => {"Test" => "Test2"}})
        # Using FactoryGirl, activities are not updated... !?!
        p.alterations.reload

        p.alterations.size.should == 1
        p.destroy
        Activity.where(:resource_type => "Person", :resource_id => p).count.should eq(0)
      end
    end
  end
end
