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

# Options are: :invoice_id, :person
class Invoices::Pdf

  @queue = :documents

  include Rails.application.routes.url_helpers

  def self.perform(invoice_id)
    @invoice = Invoice.find(invoice_id)

    # GENERATE INVOICE FROM ODT TEMPLATE
    file = Tempfile.new(['invoice_body', '.pdf'], encoding: 'ascii-8bit')
    generator = AttachmentGenerator.new(@invoice)
    generator.pdf { |o,pdf| file.write pdf.read }
    file.flush

    if @invoice.invoice_template.with_bvr
      # GENERATE BVR
      controller = People::Affairs::InvoicesController.new
      html = controller.render_to_string( inline: controller.build_from_template(@invoice), layout: 'pdf.html.haml')
      html.assets_to_full_path!

      bvr = Tempfile.new(['invoice_bvr', '.pdf'], encoding: 'ascii-8bit')
      bvr.binmode

      # Using path instead of url so it works in dev mode too.
      # TODO limit page to one. if css describes it, it may be longer. Then reverse document and bg in pdftk, so
      # content never overlap the bvr
      kit = PDFKit.new(html)

      bvr.write(kit.to_pdf)
      bvr.flush

      # MERGE INVOICE AND BVR
      document = Tempfile.new(["invoice_document", '.pdf'], encoding: 'ascii-8bit')
      document.binmode

      script = Tempfile.new(['script', '.sh'], encoding: 'ascii-8bit')
      script.write("#!/bin/bash\n")
      script.write("pdftk #{file.path} background #{bvr.path} output #{document.path}\n")
      script.flush

      system "chmod +x #{script.path}"
      system "bash #{script.path}"

      script.unlink

      file = document
    end

    @invoice.pdf = file
    @invoice.save
    if @invoice.errors.size > 0
      raise ArgumentError, "Failed to save invoice #{@invoice.inspect}, #{@invoice.errors.inspect}"
    end

    # this won't touch updated_at column
    @invoice.update_column(:pdf_updated_at, Time.now)

    file.unlink
  end
end
