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

  def parse_comments(raw_comments)
    # Comments will be save on transaction commit
    raw_comments.split(",").map do |c|
      Comment.new(:title => 'import', :description => c.strip)
    end
  end

  def parse_location(postal_code_prefix, name)
    if postal_code_prefix
      if postal_code_prefix.to_s.match(/^([a-zA-Z]+)/)
        @person.errors.add(:location, I18n.t('person.import.invalid_location', :location => "#{postal_code_prefix}, #{name}"))
      end
      postal_code_prefix = parse_postal_code_prefix(postal_code_prefix.to_s)
    end

    l = Location.where(:postal_code_prefix => postal_code_prefix)
    if l.size == 1
      @person.location = l.first
    elsif name
      if l.size > 1
        regex = name.gsub(/\s/, ".+")
        l = Location.where("postal_code_prefix = '#{postal_code_prefix}' AND name ~* ?", regex).first
        @person.location = l
      else
        l = Location.where(:name => name).first
        @person.location = l
      end
    end
  end

  def parse_postal_code_prefix(string)
    ary = string.match(/^*\-?\s?+([0-9]+)\s?+$/)
    ary ? ary[1].strip : nil
  end

  def parse_job(raw_job_name)
    job_name = raw_job_name.strip[0..254].gsub(",", " ")
    return if job_name.blank?

    job = Job.where(:name => job_name).first
    if job
      @person.job = job
      job_name = nil
    else
      @person.notices.add(:job, I18n.t("person.import.not_existing_job", :job => job_name))
    end

    job_name
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
    # TODO fixme or remove me
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
    parse_multiple_tags(private_tags, PrivateTag)
  end

  def parse_public_tags(public_tags)
    parse_multiple_tags(public_tags, PublicTag)
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
        @person.send(name.pluralize) << model.find_by_name!(item.strip)
      rescue
        @person.errors.add(name.pluralize, I18n.t("person.import.invalid_#{name}", name.to_sym => item.strip))
      end
    end
  end

  def parse_multiple_tags(items, model)
    relation = model.to_s.underscore.pluralize

    new_tags = []

    items.split(/\s*,\s*/).each do |item|
      next if item.blank?
      tag_name = item.strip[0..254]
      tag = model.where(:name => tag_name)
      if tag.count > 0
        @person.send(relation) << tag.first
      else
        @person.notices.add(relation.to_sym, I18n.t("person.import.not_existing_" + relation.singularize, :tag => tag_name))
        new_tags << tag_name
      end
    end

    new_tags
  end

end
