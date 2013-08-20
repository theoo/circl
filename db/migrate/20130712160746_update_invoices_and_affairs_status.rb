class UpdateInvoicesAndAffairsStatus < ActiveRecord::Migration
  def change
    # reindex status on the whole database
    Invoice.after_commit.clear # elasticsearch
    Receipt.after_commit.clear # elasticsearch
    Subscription.after_save.clear # automatic elasticsearch
    Affair.after_save.clear # elasticsearch
    Person.after_save.clear # automatic elasticsearch

    puts "Search for orphan invoices."
    @bar = RakeProgressbar.new(Invoice.count)
    ids = Invoice.all.select do |i|
      i.affair.nil?
      @bar.inc
    end.map(&:id)
    @bar.finished

    puts "Destroy orphan invoices."
    @bar = RakeProgressbar.new(Invoice.count)
    Invoice.find(ids).each do |i|
      i.receipts.destroy_all
      i.destroy
      @bar.inc
    end
    @bar.finished

    # This will disable autoindexing.
    # 'rake elasticsearch:sync' is required after this migration
    Rails.configuration.settings['elasticsearch']['enable_indexing'] = false

    puts "Update invoice statuses."
    @bar = RakeProgressbar.new(Invoice.count)
    Invoice.all.each { |i| i.save; @bar.inc }
    @bar.finished
    puts "Done."
  end
end
