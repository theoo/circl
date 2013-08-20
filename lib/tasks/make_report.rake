namespace :spec do

  desc "generate html report from test run"

  task :report do
    `bundle exec rspec -f h -o doc/report.html  spec`
  end
end
