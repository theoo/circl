class BankImportHistory < ApplicationRecord
  # This class should stay simple, no relations, just a backup/log of
  # previoulsy imported files/lines

  validates :file_name, presence: true
  validates :reference_line, uniqueness: true, presence: true
  validates :media_date, presence: true
  validates_with Validators::Date, attribute: :media_date

  def decoded_line
    BankImporter::Postfinance.parse_receipt(self.reference_line)
  end

  def as_json
    h = super(options)

    # add relation description to save a request
    # h[:invoice_id] = invoice_id
    # h[:invoice_value] = invoice.try(:value).try(:to_f)
    # h[:invoice_title] = invoice.try(:title)

  end

end
