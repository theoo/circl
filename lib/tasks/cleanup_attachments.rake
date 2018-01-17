namespace :attachments do

  desc "Clean attachments older than 2 years"

  task :cleanup => :environment do
    Invoice.where("pdf_updated_at < ?", 2.years.ago).each do |i|
      i.pdf.clear
      i.save
    end
  end
end
