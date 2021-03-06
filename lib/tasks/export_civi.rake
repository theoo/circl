require "csv"

namespace :db do
  desc 'Create CSVs with exported data'
  task :export_csv => :environment do

    people_csv = [[Person.first.attributes.keys,
      %w(city npa country),
      %w(sum_invoices_2017 sum_receipts_2017 sum_invoices_2018 sum_receipts_2018),
      "paid_something_in_2017_or_2018",
      %w(first_receipt_date first_receipt_subscription first_receipt_value),
      %w(last_receipt_date last_receipt_subscription last_receipt_value),
      %w(last_paid_subscription_start_date),
      %w(private_tags public_tags),
      ].flatten]
    Person.all.each do |p|

      line = p.attributes.values

      line << p.location.try(:name)
      line << p.location.try(:postal_code_prefix)
      line << p.location.try(:country).try(:name)

      [2017, 2018].each do |y|
        from = Date.new(y,1,1)
        to = from.end_of_year
        line << p.invoices.where(created_at: from..to).map(&:value_with_taxes).sum.to_f
        line << p.receipts.where(created_at: from..to).map(&:value).sum.to_f
      end

      ivale = Date.new(2017,1,1)..Date.new(2018,12,31)
      line << (p.receipts.where( created_at: ivale ).count > 0)

      first_receipt = p.receipts.order(:created_at).first
      line << first_receipt.try(:created_at).try(:iso8601)
      line << first_receipt.try(:affair).try(:subscriptions).try(:first).try(:title)
      line << first_receipt.try(:value).try(:to_f)

      last_receipt = p.receipts.order(:created_at).last
      line << last_receipt.try(:created_at).try(:iso8601)
      line << last_receipt.try(:affair).try(:subscriptions).try(:first).try(:title)
      line << last_receipt.try(:value).try(:to_f)

      mask = Affair.statuses_value_for(:paid)
      last_sub = p.subscriptions
        .order("subscriptions.interval_ends_on")
        .where("(affairs.status::bit(16) & ?::bit(16))::int = ?", mask, mask)
      if ENV['SUBSCRIPTION_IDS']
        ids = ENV['SUBSCRIPTION_IDS'].split(",")
        last_sub = last_sub.where(subscriptions: {id: ids})
      end
      line << last_sub.last.try(:interval_starts_on).try(:iso8601)

      line << p.private_tags.map(&:name).try(:join, ",")
      line << p.public_tags.map(&:name).try(:join, ",")

      people_csv << line

    end

    CSV.open("people.csv", "wb") { |csv| people_csv.each { |i| csv << i } }

    # Tiers payant
    affairs_csv = [%w(affair_id subscription_id subscription_title owner_id receiver_id buyer_id created_at)]
    Affair.joins(:subscriptions).all.each do |a|
      line = []
      line << a.id
      line << a.subscriptions.first.id
      line << a.subscriptions.first.title
      line << a.owner_id
      line << a.receiver_id
      line << a.buyer_id
      line << a.created_at.iso8601
      affairs_csv << line
    end

    CSV.open("affairs.csv", "wb") { |csv| affairs_csv.each { |i| csv << i } }

    invoices_csv = [[Invoice.first.attributes.keys, %w{owner_id receiver_id buyer_id subscription_id}].flatten]
    Invoice.all.each do |i|
      line = i.attributes.values
      line << i.owner.try(:id)
      line << i.buyer.try(:id)
      line << i.receiver.try(:id)
      line << i.subscriptions.try(:first).try(:id)
      invoices_csv << line
    end
    CSV.open("invoices.csv", "wb") { |csv| invoices_csv.each { |i| csv << i } }

    receipts_csv = [[Receipt.first.attributes.keys,
      %w{owner_id owner_name receiver_id receiver_name buyer_id buyer_name subscription_id}].flatten]
    Receipt.all.each do |i|
      line = i.attributes.values
      line << i.owner.try(:id)
      line << i.owner.try(:full_name)
      line << i.buyer.try(:id)
      line << i.buyer.try(:full_name)
      line << i.receiver.try(:id)
      line << i.receiver.try(:full_name)
      line << i.subscriptions.try(:first).try(:id)

      receipts_csv << line
    end
    CSV.open("receipts.csv", "wb") { |csv| receipts_csv.each { |i| csv << i } }

    subscriptions_csv = [Invoice.first.attributes.keys]
    Subscription.all.each do |i|
      subscriptions_csv << i.attributes.values
    end
    CSV.open("subscriptions.csv", "wb") { |csv| subscriptions_csv.each { |i| csv << i } }

  end
end