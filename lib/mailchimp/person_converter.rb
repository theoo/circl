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

require 'set'

module Mailchimp

  class PersonConverter
    attr_accessor :result

    def initialize(person, logger, report, groupings_on_mailchimp)
      @person = person
      @result = {}
      @logger = logger
      @report = report
      @groupings_on_mailchimp = groupings_on_mailchimp
    end

    def convert
      result['EMAIL'] = @person.email
      result['EMAIL_TYPE'] = 'html'

      add_merge_vars_to_result
      add_groupings_to_result

      result
    end


    private

    def log(str)
      @logger.info(str)
      @report.info(str)
    end

    def add_merge_vars_to_result
      add_if_present(@person.first_name, 'FNAME')
      add_if_present(@person.last_name, 'LNAME')
      add_if_present(@person.location, 'LOC')
      add_if_present(@person.job, 'JOB')
    end

    # for each grouping we want an id and a list of groups
    def add_groupings_to_result
      groupings = []

      SynchronizeGroupings::RAILS_GROUPINGS.each do |rails_grouping|
        person_attribute = rails_grouping[:person_attribute]
        grouping_name = rails_grouping[:grouping_name]

        unless grouping_names_on_mailchimp.include?(grouping_name)
          log("warning grouping '#{grouping_name}' does not exist on mailchimp")
          next
        end

        groups = groups_for_person_attribute(person_attribute, grouping_name)
        next if groups.empty?

        groups.each do |group|
          group.gsub!(/,/, '\,')
          groupings << { 'name' => grouping_name, 'groups' => group }
        end
      end

      result['GROUPINGS'] = groupings if groupings.size > 0
    end

    def groups_for_person_attribute(person_attribute, grouping_name)
      attribute_value = @person.send(person_attribute)
      return [] if attribute_value.nil?

      # make an array 'groups' from attribute_value
      if attribute_value.instance_of?(Array)
        groups = attribute_value.map { |element| element.name }.uniq
      else
        groups = Array(attribute_value.name)
      end

      # make sure groups in db also exist on mailchimp
      groups_on_mailchimp = @groupings_on_mailchimp.select { |grouping| grouping['name'] == grouping_name }.
                                                   first['groups'].
                                                   map { |group_hash| group_hash['name'] }

      partitioned_groups = groups.partition { |group| groups_on_mailchimp.include?(group) }

      partitioned_groups.first
    end

    def grouping_names_on_mailchimp
      @groupings_on_mailchimp.map { |grouping| grouping['name'] }
    end

    def add_if_present(person_attribute, mailchimp_tag)
      if person_attribute.respond_to?(:name) # we get an obj (location or job)
        result[mailchimp_tag] = person_attribute.name
      elsif person_attribute.present? # check if string present when first or last name
        result[mailchimp_tag] = person_attribute
      end
    end

  end
end
