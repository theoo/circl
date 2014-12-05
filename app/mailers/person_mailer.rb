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

# TODO is this the right place to set this ?
ActionMailer::Base.class_eval do
  def mail_with_prefix(headers={}, &block)
    headers[:subject] = "CIRCL: " + (headers[:subject] || '')
    mail_without_prefix(headers, &block)
  end

  alias_method_chain :mail, :prefix
end

class PersonMailer < ActionMailer::Base

  add_template_helper(ApplicationHelper)

  layout 'mail'

  def send_mailchimp_sync_report(person, report)
    I18n.locale = person.main_communication_language.symbol
    @report = report
    mail( to: person.email,
          subject: I18n.t('person.mail.mailchimp_synchronisation_report'))
  end

  def send_background_task_error_report(email, messages)
    # No locale is set as there is no user involved, only email address from configuration.yml
    @messages = messages
    mail( to: email,
          subject: I18n.t('person.mail.background_task_error_report'))
  end

  def send_receipts_import_report(person, receipts = [], errors = [])
    I18n.locale = person.main_communication_language.symbol
    @receipts = receipts
    @errors   = errors
    mail( to: person.email,
          subject: I18n.t('person.mail.receipts_import_report'))
  end

  def send_people_import_report(person, people)
    I18n.locale = person.main_communication_language.symbol
    @valid_people = []
    @invalid_people = []
    people.each{|p| (p.errors.empty? ? @valid_people : @invalid_people) << p }
    mail( to: person.email,
          subject: I18n.t('person.mail.people_import_report'))
  end

  def send_subscription_pdf_link(person, subscription_id)
    I18n.locale = person.main_communication_language.symbol
    @subscription = Subscription.find(subscription_id)
    mail( to: person.email,
          subject: I18n.t('person.mail.pdf_for_subscription',
          title: @subscription.title))
  end

  def send_members_added_to_subscription(person, subscription_id, new_people_ids, existing_people_ids)
    I18n.locale = person.main_communication_language.symbol
    @new_people = new_people_ids.map{ |id| Person.find(id) }
    @existing_people = existing_people_ids.map{ |id| Person.find(id) }
    @subscription = Subscription.find(subscription_id)
    mail( to: person.email,
          subject: I18n.t('person.mail.members_were_added_to_subscription',
          title: @subscription.title))
  end

  def send_subscriptions_merged(person, destination_subscription_id)
    I18n.locale = person.main_communication_language.symbol
    @destination_subscription = Subscription.find(destination_subscription_id)
    mail( to: person.email,
          subject: I18n.t('person.mail.subscription_were_merged',
          title: @destination_subscription.title))
  end

  def send_subscription_invoices_updated(person, subscription_id)
    I18n.locale = person.main_communication_language.symbol
    @subscription = Subscription.find subscription_id
    mail( to: person.email,
          subject: I18n.t('person.mail.subscription_were_updated',
          title: @subscription.title))
  end

  def send_receipts_document_link(person, cached_doc)
    @document = cached_doc
    I18n.locale = person.main_communication_language.symbol
    mail(to: person.email,
      subject: I18n.t('person.mail.admin_receipts_were_generated'))
  end

  def send_report_error_to_admin(current_person, exception)
    # No locale is set as there is no user involved, only email address from configuration.yml
    @exception = exception
    @current_person = current_person
    mail( to: Rails.configuration.settings['directory_admin_email'],
          subject: I18n.t("person.mail.report_error_subject"),
          layout: false)
  end

  def send_products_import_report(person, products, columns)
    @products = products
    @columns = columns
    I18n.locale = person.main_communication_language.symbol
    mail( to: person.email,
          subject: I18n.t('person.mail.products_import_report'))
  end

end
