=begin
  CIRCL Directory
  Copyright (C) 2011 Complex IT sàrl

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU Affero General Public License as
  published by the Free Software Foundation, either version 3 of the
  License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Affero General Public License for more details.

  You should have received a copy of the GNU Affero General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end

class PersonRelationsParser
  def initialize(person)
    @person = person
  end

  def parse_location(postal_code_prefix, name)
    return if postal_code_prefix.blank? || name.blank?
    @person.location = Location.find_by_postal_code_prefix_and_name(postal_code_prefix, name)
    @person.errors.add(:location, I18n.t('person.import.invalid_location', :location => "#{postal_code_prefix}, #{name}")) if @person.location.nil?
  end

  def parse_job(job)
    parse_single_item(job, Job)
  end

  def parse_roles(roles)
    parse_multiple_items(roles, Role)
  end

  def parse_main_communication_language(language)
    parse_single_item(language, Language, :main_communication_language)
  end

  def parse_communication_languages(languages)
    parse_multiple_items(languages, Language, :communication_language)
  end

  def parse_translation_aptitudes(aptitudes)
    aptitudes.split(/\s*,\s*/).each do |aptitude|
      begin
        from, to = aptitude.match(/\s*(\w+)\s*->\s*(\w+)\s*/).captures.map{ |l| Language.find_by_name!(l) }
        @person.translation_aptitudes.build(:from_language => from, :to_language => to)
      rescue
        @person.errors.add(:translation_aptitudes, I18n.t('person.import.invalid_translation_aptitude', :translation_aptitude => aptitude))
      end
    end
  end

  def parse_private_tags(private_tags)
    parse_multiple_items(private_tags, PrivateTag)
  end

  def parse_public_tags(public_tags)
    parse_multiple_items(public_tags, PublicTag)
  end


  protected

  def parse_single_item(item, model, name = model.to_s.underscore)
    name = name.to_s
    return if item.blank?
    @person.send("#{name}=", model.find_by_name(item))
    @person.errors.add(name, I18n.t("person.import.invalid_#{name}", name.to_sym => item)) if @person.send(name).nil?
  end

  def parse_multiple_items(items, model, name = model.to_s.underscore)
    name = name.to_s
    items.split(/\s*,\s*/).each do |item|
      begin
        @person.send(name.pluralize) << model.find_by_name!(item)
      rescue
        @person.errors.add(name.pluralize, I18n.t("person.import.invalid_#{name}", name.to_sym => item))
      end
    end
  end

end
