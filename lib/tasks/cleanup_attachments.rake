namespace :attachments do

  desc "Clean attachments older than 2 years"

  task :cleanup => :environment do
    delay = 2.years.ago

    invoices = Invoice.where("pdf_updated_at < ?", delay)
    bar = RakeProgressbar.new(invoices.count)
    invoices.each do |i|
      bar.inc
      begin
        i.pdf.clear; i.save
      rescue
        puts "Failed to save invoice #{i.id}"
      end
    end
    bar.finished

    subscriptions = Subscription.where("pdf_updated_at < ?", delay)
    bar = RakeProgressbar.new(subscriptions.count)
    subscriptions.each { |i| i.pdf.clear; i.save; bar.inc }; bar.finished

    cached_documents = CachedDocument.where("document_updated_at < ?", delay)
    bar = RakeProgressbar.new(cached_documents.count)
    cached_documents.each { |i| i.document.clear; i.save; bar.inc }; bar.finished

    salaries = Salaries::Salary.where("pdf_updated_at < ?", delay)
    bar = RakeProgressbar.new(salaries.count)
    salaries.each { |i| i.pdf.clear; i.save; bar.inc }; bar.finished

    puts "done"

  end
end
