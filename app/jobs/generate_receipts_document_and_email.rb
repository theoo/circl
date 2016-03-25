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
# == Schema Information
#
# Table name: background_tasks
#
# *id*::         <tt>integer, not null, primary key</tt>
# *type*::       <tt>string(255)</tt>
# *options*::    <tt>text</tt>
# *created_at*:: <tt>datetime</tt>
# *updated_at*:: <tt>datetime</tt>
#--
# == Schema Information End
#++

# Options are: :subscription_id, :person, :query
class GenerateReceiptsDocumentAndEmail

  # options => :people_ids, :person, :from, :to, :generic_template_id, :unit_value, :global_value, :unit_overpaid, :global_overpaid
  def self.perform(people_ids)

    if options[:format] == 'pdf'
      files = []
    else
      lines = []
    end

    # for each person
    people_ids.each do |pid|
      person = Person.find pid

      receipts = person.receipts.order(:invoice_id, :value_date)

      if options[:subscriptions_filter]
        begin # Postgresql may trow an error if regexp is not correct
          receipts = receipts.joins(:subscriptions).where("subscriptions.title ~ ?", options[:subscriptions_filter])
        end
      end

      if options[:from] and options[:to]
        from = options[:from].is_a?(Date) ? options[:from] : Date.parse(options[:from])
        to = options[:to].is_a?(Date) ? options[:to] : Date.parse(options[:to])
        receipts = receipts.where("value_date BETWEEN ? AND ?", from, to)
      end

      # exclude receipts for which value is below unit threshold
      if options[:unit_value]
        receipts = receipts.reject{|a| a.value < options[:unit_value]}
      end

      if options[:global_value]
        total_value = receipts.map(&:value).sum
        receipts = [] if total_value < options[:global_value].to_i
      end

      # exclude receipts for which overpaid value is below unit threshold
      if options[:unit_overpaid]
        receipts = receipts.reject{|a| a.overpaid_value < options[:unit_overpaid]}
      end

      if options[:global_overpaid]
        total_overpaid_value = receipts.map(&:overpaid_value).sum
        receipts = [] if total_overpaid_value < options[:global_overpaid].to_i
      end

      receipts.uniq!

      if receipts.size > 0
        # compile the file and add its file path to a hash

        ######### RENDER ############
        if options[:format] == 'pdf'
          # build generator using selected generic template
          fake_object = OpenStruct.new
          fake_object.template = GenericTemplate.find options[:generic_template_id]
          fake_object.person = person
          fake_object.receipts = receipts

          generator = AttachmentGenerator.new(fake_object, nil)

          # Fake tmpfile
          filename = Dir::Tmpname.make_tmpname(["tmp/admin_receipts_file", '.pdf'], nil)
          tmpfile = File.new(filename, 'w')
          tmpfile.write generator.pdf
          tmpfile.close
          files << tmpfile
        else
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
      end
    end

    # merge files in one file
    if options[:format] == 'pdf'
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
    else
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
    cd = CachedDocument.create!(document: document)
    document.unlink

    # send an email to the file
    PersonMailer.send_receipts_document_link(options[:person], cd).deliver
  end
end
