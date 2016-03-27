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

# Options are: :subscription_id, :person, :query, :current_locale
class Subscriptions::PreparePdfsAndEmail
  @queue = :prepare_pdfs_and_email

  def self.perform(subscription_id, people_ids, person, query, current_locale)
    # Compute invoice_ids and generate PDF if necessary
    # We do a manual loop because using #map and #select blew the RAM
    invoices_ids = []
    people_ids.each do |id|
      Person.find(id).invoices.each do |i|
        next unless i.affair.subscription_ids.include?(subscription_id)
        invoices_ids << i.id
        if i.pdf_up_to_date?
          logger.info "PDF for invoice #{i.id} is up to date, skipping..."
        else
          logger.info "PDF for invoice #{i.id} is not up to date, generating..."
          GenerateInvoicePdf.perform(invoice_id: i.id)
        end
      end
    end
    Subscriptions::ConcatAndEmailPdf.perform(subscription_id: subscription_id,
                                                            invoices_ids: invoices_ids,
                                                            person: person,
                                                            query: query,
                                                            current_locale: current_locale)
  end
end
