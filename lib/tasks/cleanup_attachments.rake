namespace :attachments do

  desc "Clean attachments older than 2 years"

  task :cleanup => :environment do
    delay = 2.years.ago

    Rails.configuration.settings['elasticsearch']['enable_index'] = false

    invoices = Invoice.where("pdf_updated_at < ?", delay)
    puts "Clear #{invoices.count} invoices without callbacks."
    rm_paths = invoices.map{|i| "rm #{i.pdf.path};" }.join
    system rm_paths
    puts %x( find #{[Rails.root, "public/system"].join('/')} -type d -empty -delete )

    # without callbacks
    invoices.update_all(
      pdf_file_name: nil,
      pdf_content_type: nil,
      pdf_file_size: nil,
      pdf_updated_at: nil
      )

    subscriptions = Subscription.where("pdf_updated_at < ?", delay)
    bar = RakeProgressbar.new(subscriptions.count)
    subscriptions.each { |i| i.pdf.clear; i.save; bar.inc }; bar.finished

    cached_documents = CachedDocument.where("document_updated_at < ?", delay)
    bar = RakeProgressbar.new(cached_documents.count)
    cached_documents.each { |i| i.document.clear; i.save; bar.inc }; bar.finished

    salaries = Salaries::Salary.where("pdf_updated_at < ?", delay)
    bar = RakeProgressbar.new(salaries.count)
    salaries.each { |i| i.pdf.clear; i.save; bar.inc }; bar.finished

    puts "done. Reindexing required."

    Rails.configuration.settings['elasticsearch']['enable_index'] = true

  end
end
