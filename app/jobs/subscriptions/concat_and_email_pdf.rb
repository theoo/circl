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

# Options are: :person, :people_ids
class Subscriptions::ConcatAndEmailPdf

  @queue = :notifications

  def self.perform(subscription_id)
    I18n.locale = options[:current_locale]
    subscription = Subscription.find subscription_id

    # GENERATE FRONTPAGE
    controller = Admin::SubscriptionsController.new
    html = controller.render_to_string( inline: controller.pdf_front_page(subscription, options[:query]))
    html.assets_to_full_path!

    front_page = Tempfile.new(["subscription#{subscription.id}_front_page", '.pdf'], encoding: 'ascii-8bit')
    front_page.binmode

    kit = PDFKit.new(html)

    front_page.write(kit.to_pdf)
    front_page.flush

    # MAP PDF URLS
    paths = options[:invoices_ids].map{ |id| Invoice.find(id).pdf.path }
    paths.insert(0, front_page.path)

    file = Tempfile.new(["subscription#{subscription.id}", ".pdf"], encoding: 'ascii-8bit')
    file.binmode
    script = Tempfile.new(['script', '.sh'], encoding: 'ascii-8bit')
    script.write("#!/bin/bash\n")
    script.write("pdftk #{paths.join(' ')} cat output #{file.path}")
    script.flush

    system "chmod +x #{script.path}"
    system "bash #{script.path}"

    subscription.pdf = file

    # append the query at the end, if everything succeed.
    # TODO: transaction, validation
    subscription.last_pdf_generation_query = options[:query].to_json
    subscription.save

    file.unlink
    script.unlink

    PersonMailer.send_subscription_pdf_link(options[:person], subscription.id).deliver
  end
end
