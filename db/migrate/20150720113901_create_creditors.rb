class CreateCreditors < ActiveRecord::Migration
  def change

    create_table :creditors do |t|
      t.integer :creditor_id
      t.integer :affair_id
      t.string  :title
      t.text    :description
      t.integer :value_in_cents, default: 0, null: false
      t.string  :value_currency, default: "CHF", null: false
      t.integer :vat_in_cents, default: 0, null: false
      t.string  :vat_currency, default: "CHF", null: false
      t.string  :vat_percentage
      t.date    :invoice_received_on
      t.date    :invoice_ends_on
      t.date    :invoice_in_books_on
      t.float   :discount_percentage, default: 0
      t.date    :discount_ends_on
      t.date    :paid_on
      t.date    :payment_in_books_on

      t.timestamps
    end

    add_index :creditors, :creditor_id
    add_index :creditors, :affair_id

    add_index :creditors, :invoice_received_on
    add_index :creditors, :invoice_ends_on
    add_index :creditors, :discount_ends_on
    add_index :creditors, :invoice_in_books_on
    add_index :creditors, :paid_on
    add_index :creditors, :payment_in_books_on

  end
end
