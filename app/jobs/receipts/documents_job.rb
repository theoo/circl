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

class Receipts::DocumentsJob < ApplicationJob

  queue_as :documents

  def perform(params = nil)

    # Resque::Plugins::Status options
    params ||= options
    # i18n-tasks-use I18n.t("receipts.jobs.documents.title")
    # set_status(translation_options: ["receipts.jobs.documents.title"])

    required = %i(query user_id from to format generic_template_id)
    # optional_params = %i(subscriptions_filter unit_value global_value unit_overpaid global_overpaid)
    validates(params, required)

    people_ids = ElasticSearch.search(
      @query[:search_string],
      @query[:selected_attributes],
      @query[:attributes_order] )
      .map(&:id)

    if @format == 'pdf'

      files = []
      collect_receipts_of(people_ids) do |person, receipts|
        # build generator using selected generic template
        fake_object = OpenStruct.new
        fake_object.template = GenericTemplate.find @generic_template_id
        fake_object.person = person
        fake_object.receipts = receipts

        generator = AttachmentGenerator.new(fake_object, nil)

        # Fake tmpfile
        filename = Dir::Tmpname.make_tmpname(["tmp/admin_receipts_file", '.pdf'], nil)
        tmpfile = File.new(filename, 'w')
        tmpfile.write generator.pdf
        tmpfile.close
        files << tmpfile
      end

      unless files.empty?
        document = Tempfile.new(["admin_receipts_file", '.pdf'], encoding: 'ascii-8bit')
        script = Tempfile.new(['script', '.sh'], encoding: 'ascii-8bit')
        script.write("#!/bin/bash\n")
        script.write("pdftk #{files.map(&:path).join(' ')} cat output #{document.path}")
        script.flush

        system "chmod +x #{script.path}"
        system "bash #{script.path}"

        script.unlink

        # Remove previously created fake tempfile
        files.each {|f| File.delete(f) }
      end

    else

      lines = []
      collect_receipts_of(people_ids) do |person, receipts|
        lines << [person.id,
          person.first_name,
          person.last_name,
          person.organization_name,
          person.full_address,
          person.location.try(:country).try(:name),
          person.email,
          person.phone,
          person.main_communication_language.try(:name),
          receipts.count,
          receipts.map(&:value).sum,
          receipts.map(&:overpaid_value).sum]
      end

      document = Tempfile.new(["admin_receipts_file", '.csv'], encoding: 'ascii-8bit')
      content = CSV.generate(encoding: 'UTF-8') do |csv|
        csv << ["person_id",
          "person_first_name",
          "person_last_name",
          "person_organization_name",
          "person_full_address",
          "person_country",
          "person_email",
          "person_phone",
          "person_main_communication_language",
          "receipts_count",
          "receipts_value",
          "receipts_overpaid_value"]

        lines.each {|l| csv << l}
      end

      document.write content
      document.flush

    end

    # Store document in cache_documents table
    if document and document.size > 0
      cd = CachedDocument.create!(document: document)
      document.unlink if document

      # send an email to the file
      PersonMailer.send_receipts_document_link(@user_id, cd).deliver
    else
      PersonMailer.send_receipts_document_link(@user_id, nil).deliver
    end

  # rescue Exception => e
  #   msg = "An error occured while running #{self.class}:"
  #   Rails.logger.warn [msg, e.to_s, e.backtrace].flatten.join("\n")
  #   raise e
  end

  private

    def collect_receipts_of(people_ids, &block)

      people_ids.each do |pid|

        person = Person.find pid

        receipts = filter_receipts(person)

        block.call(person, receipts) if receipts.size > 0

      end

    end

    def filter_receipts(person)

      receipts = person.receipts.order(:invoice_id, :value_date)

      if @from and @to
        @from = @from.is_a?(Date) ? @from : Date.parse(@from)
        @to = @to.is_a?(Date) ? @to : Date.parse(@to)
        receipts = receipts.where("value_date BETWEEN ? AND ?", @from, @to)
      end

      if @subscriptions_filter
        begin # Postgresql may trow an error if regexp is not correct
          receipts = receipts.joins(:subscriptions).where("subscriptions.title ~ ?", @subscriptions_filter)
        end
      end

      # exclude receipts for which value is below unit threshold
      if @unit_value
        receipts = receipts.reject{|a| a.value < @unit_value}
      end

      if @global_value
        total_value = receipts.map(&:value).sum
        receipts = [] if total_value < @global_value.to_i
      end

      # exclude receipts for which overpaid value is below unit threshold
      if @unit_overpaid
        receipts = receipts.reject{|a| a.overpaid_value < @unit_overpaid}
      end

      if @global_overpaid
        total_overpaid_value = receipts.map(&:overpaid_value).sum
        receipts = [] if total_overpaid_value < @global_overpaid.to_i
      end

      receipts.uniq!
      receipts

    end

end
