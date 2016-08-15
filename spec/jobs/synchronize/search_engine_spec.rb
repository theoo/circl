require 'spec_helper'

describe Synchronize::SearchEngine do

  it "Changing person should update cache" do
    original_name = 'original_name'
    person = FactoryGirl.create(:person, first_name: original_name)
    expect(ES.search(person).first_name).be eq(original_name)
    a_new_name = 'a_new_name'
    person.update_attributes first_name: a_new_name
    expect(ES.search(person).first_name).be eq(a_new_name)
  end

end
