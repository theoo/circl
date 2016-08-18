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

class Subscriptions::PreparePdfsAndEmail

  @queue = :processing

  include ResqueHelper

  def perform(params = nil)
    # Resque::Plugins::Status options
    params ||= options
    # i18n-tasks-use I18n.t("subscriptions.background_tasks.prepare_pdf_and_email.title")
    set_status(translation_options: ["subscriptions.background_tasks.prepare_pdf_and_email.title"])

    required = %i(subscription_id query user_id status)
    validates(params, required)

    people_ids = ElasticSearch.search(
      @query[:search_string],
      @query[:selected_attributes],
      @query[:attributes_order])
      .map(&:id)

    # Compute invoice_ids and generate PDF if necessary
    # We do a manual loop because using #map and #select blew the RAM
    invoices_ids = []
    total = people_ids.size
    people_ids.each_with_index do |id, index|
      at(index + 1, total, I18n.t("backgroun_tasks.progress", index: index + 1, total: total))

      Person.find(id).invoices.each do |i|
        next unless i.affair.subscription_ids.include?(@subscription_id)
        invoices_ids << i.id
        if i.pdf_up_to_date?
          logger.info "PDF for invoice #{i.id} is up to date, skipping..."
        else
          logger.info "PDF for invoice #{i.id} is not up to date, generating..."
          Invoices::Pdf.perform(nil, invoice_id: i.id)
        end
      end
    end

    completed(message: ["subscriptions.background_tasks.prepare_pdf_and_email.invoices_generation_succeed"])

    Subscriptions::ConcatAndEmailPdf.perform(nil,
      subscription_id: @subscription_id,
      query: @query,
      invoice_ids: invoices_ids,
      user_id: @user_id,
      current_locale: @current_locale)

  end
end
