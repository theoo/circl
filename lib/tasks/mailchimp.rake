namespace :mailchimp do
  desc 'start mailchimp synchronisation process'
  task :sync => :environment do
    logger_file = File.join(Rails.root.to_s, 'log', 'mailchimp_sync.log')
    Mailchimp::Synchronizer.start(Logger.new(logger_file), ENV['PERSON_ID'])
  end
end
