namespace :utils do
  desc 'Correct receipts with an improbable value date'
  task :correct_receipts_date => :environment do

    # Disable SearchAttribute callbacks so it's faster
    %w{Person TranslationAptitude Affair Subscription Invoice Task EmploymentContract Receipt}.each do |model|
      model = model.constantize
      model.reset_callbacks(:save)
      model.reset_callbacks(:commit)
    end

    Receipt.transaction do
      progress = RakeProgressbar.new(Receipt.count)
      Subscription.all.each do |s|
        s.receipts.each do |r|
          title_year = s.title[/\d+/]
          if title_year && (r.value_date.year.to_s != title_year)
            r.value_date = Date.new(title_year.to_i, 1, 1)
            r.save!
          end
          progress.inc
        end
      end
      progress.finished
    end

  end
end
