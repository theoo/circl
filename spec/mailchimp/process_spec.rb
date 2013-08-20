require 'spec_helper'

describe Mailchimp::Process do
  let(:logger) { double("Logger").as_null_object }

  after(:each) do
    system("rm #{Mailchimp::LOCK_FILE}") if File.exists?(Mailchimp::LOCK_FILE)
  end

  it 'should log an error if process already running' do
    File.stub(:file? => true) # this will make Mailchimp::Process believe the file exists
    logger.should_receive(:warn).with("Mailchimp Synchronization already started")
    Mailchimp::Process.new(logger)
  end

  it 'should create a lock file if process is not running' do
    FileUtils.should_receive(:touch).with(Mailchimp::LOCK_FILE)
    Mailchimp::Process.new(logger) {}
  end

  it 'should remove the lock at the end of the job' do
    FileUtils.should_receive(:rm).with(Mailchimp::LOCK_FILE)
    Mailchimp::Process.new(logger) {}
  end

  it 'should remove the lock if the block raises an error' do
    FileUtils.should_receive(:rm).with(Mailchimp::LOCK_FILE)
    Mailchimp::Process.new(logger) { raise StandardError }
  end
end
