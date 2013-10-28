namespace :db do
  desc "Keep only the last 100 logs of person's activity"
  task :purge_activities => :environment do
    # Fetch people who have activities
    Person.joins(:activities).group('people.id').each do |p|

      log_100 = p.activities.limit(1).offset(100).first

      if log_100  # there is more than 100 items

        # Using a join instead of "person.activities" because the latter is limited to 100 items.
        Activity.joins(:person)
                .where(:person_id => p.id)
                .where('logs.created_at < ?', log_100.created_at)
                .destroy_all
        # NOTE destroy_all will destroy each item without calling callbacks (no :dependent, etc.), and it's faster.

      end

    end
  end
end
