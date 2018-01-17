namespace :attachments do

  desc "Clean attachments older than 2 years"

  task :cleanup => :environment do
    delay = 2.years.ago
    Invoice.where("pdf_updated_at < ?", delay).each { |i| i.pdf.clear; i.save }
    Subscription.where("pdf_updated_at < ?", delay).each { |i| i.pdf.clear; i.save }
    CachedDocument.where("document_updated_at < ?", delay).each { |i| i.pdf.clear; i.save }
    Salaries::Salary.where("pdf_updated_at < ?", delay).each { |i| i.pdf.clear; i.save }
  end
end
