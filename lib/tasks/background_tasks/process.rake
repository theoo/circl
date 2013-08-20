module TasksProcessor
  def log(str)
    puts("#{timestamp} #{str}")
  end

  def timestamp
    Time.now.strftime('[%d/%m/%Y %T]')
  end
end

namespace :background_tasks do
  desc 'process tasks'
  task :process => :environment do
    include TasksProcessor

    # Redirect stdout & stderr to our logfile, so we capture output from other tasks
    $stdout.reopen("#{Rails.root.to_s}/log/background_tasks.log", 'a')
    $stdout.sync = true
    $stderr.reopen($stdout)

    log 'initializing'
    while BackgroundTask.count > 0
      begin
        task = BackgroundTask.order(:created_at).first
        task.update_attribute(:status, 'running')
        log "processing #{task.inspect}"
        task.process!
      rescue => e
        messages = [ "[exception] #{e}" ]
        log messages.first
        messages << "\n[task] #{task.inspect}"
        e.backtrace.each do |s|
          tmp = "[backtrace] #{s}"
          log tmp
          messages << "\n#{tmp}"
        end
        PersonMailer.send_background_task_error_report(Rails.configuration.settings['mailers'][Rails.env]['default']['from'], messages).deliver
      end
      task.destroy
    end
    log 'done'

    BackgroundTask.unlock!
    puts '--------------------------------------------'
  end
end
