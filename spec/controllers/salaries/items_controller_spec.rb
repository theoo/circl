require 'spec_helper'

=begin
describe Salaries::ItemsController do

  login_admin

  describe 'item collection' do
    let(:item) { FactoryGirl.create(:salary_item, :salaire, :salary => FactoryGirl.create(:salary), :position => 0) }

    it 'can fetch items' do
      get :index, :salary_id => item.salary.id
      assigns(:items).should eq([item])
    end
  end

  describe 'item creation' do
    let(:salary) { FactoryGirl.create(:salary) }

    it 'can create an item' do
      attributes = {
        :salary_id => salary.id,
        :item => {
          :title => 'test',
          :value => 200,
          :position => 0
        }
      }
      expect {
        post :create, attributes
      }.to change{ Salaries::Item.count }.by(1)
    end

    let(:tax) { FactoryGirl.create(:salary_tax, :avs) }

    it 'can create an item with taxes' do
      attributes = {
        :salary_id => salary.id,
        :item => {
          :title => 'test',
          :value => 200,
          :position => 0,
          :tax_ids => [tax.id]
        }
      }
      expect {
        post :create, attributes
      }.to change{ Salaries::Item.count }.by(1)
    end
  end

  describe 'item update' do
    let(:item) { FactoryGirl.create(:salary_item, :salaire, :salary => FactoryGirl.create(:salary), :position => 0) }

    it 'can update the item' do
      attributes = {
        :id => item.id,
        :item => {
          :title => 'test'
        }
      }
      put :update, attributes
      item.reload.title.should == 'test'
    end

    it 'does not change the count of items' do
      attributes = {
        :id => item.id,
        :item => {
          :title => 'test'
        }
      }
      expect {
        put :update, attributes
      }.to change{ Salaries::Item.count }.by(0)
    end
  end

  describe 'item destruction' do
    let(:item) { FactoryGirl.create(:salary_item, :salaire, :salary => FactoryGirl.create(:salary), :position => 0) }

    it 'destroy the item' do
      attributes = {
        :id => item.id
      }
      expect {
        delete :destroy, attributes
      }.to change{ Salaries::Item.count }.by(-1)
    end
  end

end
=end
