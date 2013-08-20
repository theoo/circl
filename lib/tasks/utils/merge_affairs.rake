namespace :utils do
  desc 'merge affairs with the same title'
  task :merge_affairs => :environment do

    # Disable SearchAttribute callbacks so it's faster
    %w{Person TranslationAptitude Affair Subscription Invoice Task EmploymentContract Receipt}.each do |model|
      model = model.constantize
      model.reset_callbacks(:save)
      model.reset_callbacks(:commit)
    end

    Person.transaction do
      progress = RakeProgressbar.new(Person.count)
      Person.all.each do |p|
        progress.inc

        affairs = p.affairs.order(:title)
        next unless affairs.size > 1

        # Loop over affairs and move invoices of affairs
        # with the same title to the first affair with this title
        last = affairs.first
        affairs[1..-1].each do |a|
          if a.title == last.title
            # Move invoices over
            a.invoices.each do |i|
              i.affair_id = last.id
              i.save
            end

            # Move subscriptions over
            last.subscription_ids += a.subscription_ids

            a.reload
            puts "Cannot destroy #{a.id}" unless a.destroy
            next
          end
          last = a
        end
      end
      progress.finished
    end

  end
end
