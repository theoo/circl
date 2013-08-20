=begin
  CIRCL Directory
  Copyright (C) 2011 Complex IT sàrl

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU Affero General Public License as
  published by the Free Software Foundation, either version 3 of the
  License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Affero General Public License for more details.

  You should have received a copy of the GNU Affero General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end

# == Schema Information
#
# Table name: background_tasks
#
# *id*::         <tt>integer, not null, primary key</tt>
# *type*::       <tt>string(255)</tt>
# *options*::    <tt>text</tt>
# *created_at*:: <tt>datetime</tt>
# *updated_at*:: <tt>datetime</tt>
#--
# == Schema Information End
#++

class BackgroundTask < ActiveRecord::Base

  #################
  ### CALLBACKS ###
  #################

  before_create do
    # define a default status
    self.status = 'pending' if self.status.blank?
  end

  #################
  ### RELATIONS ###
  #################

  belongs_to  :person
  serialize :options

  #################
  ### VALIDATIONS #
  #################

  validate :person, :presence => true,
                    :numericality => true

  validate :title,  :presence => true,
                    :length => {:maximum => 255}

  validate :options, :presence => true

  validate :status, :length => {:maximum => 255}

  #####################
  ### CLASS METHODS ###
  #####################

  LOCK_FILE = File.join(Rails.root.to_s, 'tmp', 'background_task_process.lock')

  class << self
    def process!(options = nil)
      new(:options => options).process!
    end

    def schedule(options = nil)
      raise RuntimeError, 'call this method from the derived classes' if self == BackgroundTask

      existing_task = where(:options => YAML.dump(options)).first
      if existing_task
        logger.debug("task '#{existing_task.inspect}' is already scheduled")
      else
        if options[:person]
          person = options[:person]
        else
          person = Person.find(ApplicationSetting.value(:me)) # Admin
        end
        create!(:options => options, :person => options[:person], :title => generate_title(options))
      end

      run_if_needed

      existing_task.nil?
    end

    def run_if_needed
      unless BackgroundTask.running?
        # we lock here because rake takes a while to load, and thus multiple rake task could spawn
        # The rake task processes as many tasks as possible then unlocks when it is done
        lock!
        RakeUtils::call_rake('background_tasks:process')
      end
    end

    def running?
      File.file?(LOCK_FILE)
    end

    def lock!
      FileUtils.touch(LOCK_FILE)
    end

    def unlock!
      FileUtils.rm(LOCK_FILE) if running?
    end

    def current_task
      order(:created_at).first
    end

    def generate_title(options)
      raise NotImplementedError, 'you need to subclass & overload this method'
    end
  end

  # attributes overridden - JSON API
  def as_json(options = nil)
    h = super(options)

    h.delete(:api_trigger)

    h[:person_name] = person.name if person
    h
  end

  ########################
  ### INSTANCE METHODS ###
  ########################

  def process!
    raise NotImplementedError, 'you need to subclass & overload this method'
  end

end
