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

# Options are: :invoice_id, :person
class BackgroundTasks::GenerateInvoicePdf < BackgroundTask

  include Rails.application.routes.url_helpers

  def self.generate_title(options)
    I18n.t("background_task.tasks.generate_invoice_pdf",
      :invoice_id => options[:invoice_id],
      :invoice_title => Invoice.find(options[:invoice_id]).title)
  end

  def process!
    invoice = Invoice.find(options[:invoice_id])
    affair  = invoice.affair
    person  = invoice.owner

    controller = People::Affairs::InvoicesController.new
    html = controller.render_to_string( :inline => controller.build_from_template(invoice),
                                        :layout => 'pdf.html.haml')
    html.assets_to_full_path!

    file = Tempfile.new(['invoice', '.pdf'], :encoding => 'ascii-8bit')
    file.binmode

    token = Person.find(ApplicationSetting.value(:me)).authentication_token

    options = {}

    if invoice.invoice_template.header
      options[:header_html] =
        Rails.configuration.settings['directory_url'] +
          header_person_affair_invoice_path(person, affair, invoice, :auth_token => token)
    end

    if invoice.invoice_template.footer
      options[:footer_html] =
        Rails.configuration.settings['directory_url'] +
          footer_person_affair_invoice_path(person, affair, invoice, :auth_token => token)
    end

    # Using path instead of url so it works in dev mode too.
    kit = PDFKit.new(html, options)

    file.write(kit.to_pdf)
    file.flush
    invoice.pdf = file
    invoice.save

    # this won't touch updated_at column
    invoice.update_column(:pdf_updated_at, Time.now)

    file.unlink
  end
end
