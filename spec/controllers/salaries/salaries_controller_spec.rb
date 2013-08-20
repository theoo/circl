require 'spec_helper'

describe Salaries::SalariesController do

  login_admin

  describe 'salary collection' do
    let(:salary) { FactoryGirl.create(:salary, :retraite) }

    it 'can fetch salaries' do
      get :index, :person_id => salary.person.id
      assigns(:salaries).should eq([salary])
    end
  end

  describe 'salary creation' do
    let(:person) { FactoryGirl.create(:person) }

    context 'can create a valid salary' do
      let(:attributes) do
        {
          :person_id => person.id,
          :salary =>
          {
            :year => 2013,
            :title => 'Foo',
            :is_template => false
          }
        }
      end

      it 'updates the count of salaries' do
        expect {
          post :create, attributes
        }.to change{ Salaries::Salary.count }.by(1)
      end

      it 'with valid values' do
        post :create, attributes
        Salaries::Salary.last.person_id.should == person.id
        Salaries::Salary.last.title.should == 'Foo'
        Salaries::Salary.last.is_template.should.be_false
      end
    end
  end

  describe 'salary update' do
    let(:salary) { FactoryGirl.create(:salary, :retraite) }

    it 'can update the salary' do
      attributes = {
        :id => salary.id,
        :salary => {
          :title => 'Bar'
        }
      }
      put :update, attributes
      salary.reload.title.should == 'Bar'
    end

    it 'does not change the count of salaries' do
      attributes = {
        :id => salary.id,
        :salary => {
          :title => 'Bar'
        }
      }
      expect {
        put :update, attributes
      }.to change{ Salaries::Salary.count }.by(0)
    end
  end

  describe 'salary destruction' do
    let(:salary) { FactoryGirl.create(:salary, :retraite) }

    it 'destroy the salary' do
      attributes = {
        :id => salary.id
      }
      expect {
        delete :destroy, attributes
      }.to change{ Salaries::Salary.count }.by(-1)
    end
  end

end
