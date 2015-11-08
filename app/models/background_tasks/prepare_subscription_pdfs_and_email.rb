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
class BackgroundTasks::PrepareSubscriptionPdfsAndEmail < BackgroundTask
  def self.generate_title(options)
    I18n.t("background_task.tasks.prepare_subscription_pdf_and_email",
      people_count: options[:people_ids].size,
      subscription_id: options[:subscription_id],
      subscription_title: Subscription.find(options[:subscription_id]).title)
  end

  def process!
    # Compute invoice_ids and generate PDF if necessary
    # We do a manual loop because using #map and #select blew the RAM
    invoices_ids = []
    options[:people_ids].each do |id|
      Person.find(id).invoices.each do |i|
        next unless i.affair.subscription_ids.include?(options[:subscription_id])
        invoices_ids << i.id
        if i.pdf_up_to_date?
          logger.info "PDF for invoice #{i.id} is up to date, skipping..."
        else
          logger.info "PDF for invoice #{i.id} is not up to date, generating..."
          BackgroundTasks::GenerateInvoicePdf.process!(invoice_id: i.id)
        end
      end
    end
    BackgroundTasks::ConcatAndEmailSubscriptionPdf.process!(subscription_id: options[:subscription_id],
                                                            invoices_ids: invoices_ids,
                                                            person: options[:person],
                                                            query: options[:query],
                                                            current_locale: options[:current_locale])
  end
end
