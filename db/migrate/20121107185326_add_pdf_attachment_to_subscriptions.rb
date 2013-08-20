class AddPdfAttachmentToSubscriptions < ActiveRecord::Migration
  def change
    add_attachment :subscriptions, :pdf
    add_column     :subscriptions, :last_pdf_generation_query, :text
  end
end
