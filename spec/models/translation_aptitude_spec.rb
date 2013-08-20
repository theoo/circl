require 'spec_helper'

describe TranslationAptitude, "validations" do
  it 'should have a person_id' do
    subject.should have(1).error_on(:person_id)
  end

  it 'should have a from_language attribute' do
    subject.should have(1).error_on(:from_language)
  end

  it 'should have a to_language attribute' do
    subject.should have(1).error_on(:to_language)
  end

  it 'should not be possible to set a translation aptitude from and to the same language' do
    language = FactoryGirl.create(:language)

    subject.from_language = language
    subject.to_language = language

    subject.should have(1).error_on(:base)
  end

  it 'should have a uniq translation aptitude' do
    person = FactoryGirl.create(:person)

    from = FactoryGirl.create(:language)
    to   = FactoryGirl.create(:language)
    ta1 = TranslationAptitude.create(:from_language => from, :to_language => to, :person_id => person.id)
    ta2 = TranslationAptitude.create(:from_language => from, :to_language => to, :person_id => person.id)

    person.translation_aptitudes << ta1
    person.translation_aptitudes << ta2

    ta2.should have(1).error_on(:base)
  end
end
