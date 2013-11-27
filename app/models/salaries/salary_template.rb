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
# Table name: salaries_salary_templates
#
# *id*::                    <tt>integer, not null, primary key</tt>
# *title*::                 <tt>string(255), not null</tt>
# *html*::                  <tt>text, not null</tt>
# *snapshot_file_name*::    <tt>string(255)</tt>
# *snapshot_content_type*:: <tt>string(255)</tt>
# *snapshot_file_size*::    <tt>integer</tt>
# *snapshot_updated_at*::   <tt>datetime</tt>
# *created_at*::            <tt>datetime</tt>
# *updated_at*::            <tt>datetime</tt>
#--
# == Schema Information End
#++

class Salaries::SalaryTemplate < ActiveRecord::Base

  ###################
  ### CALLBACKS #####
  ###################

  before_destroy :ensure_template_has_no_salaries


  ################
  ### INCLUDES ###
  ################

  include ChangesTracker
  include ElasticSearch::Mapping
  include ElasticSearch::Indexing


  #################
  ### RELATIONS ###
  #################

  belongs_to :language
  has_many :salaries,
           :class_name => 'Salaries::Salary'

  has_attached_file :snapshot,
                    :default_url => '/images/missing_thumbnail.png',
                    :default_style => :thumb,
                    :use_timestamp => true,
                    :styles => {:medium => "420x594>",:thumb => "105x147>"}


  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :title, :html, :language_id
  validates_uniqueness_of :title

  # Validate fields of type 'string' length
  validates_length_of :title, :maximum => 255

  # Validate fields of type 'text' length
  validates_length_of :html, :maximum => 65536


  ########################
  ### INSTANCE METHODS ###
  ########################

  # Returns a list of all available placeholders for a salary.
  def placeholders
    # Stub
    s = Salaries::Salary.new( :salary_template => self,
                              :person => Person.new,
                              :from => Time.now.beginning_of_year,
                              :to => Time.now.end_of_year,
                              :created_at => Time.now)
    ph = s.placeholders
    h = {}
    %w(simples iterators).each { |i| h[i] = ph[i.to_sym].keys.sort }
    h
  end

  def thumb_url
    snapshot.url(:thumb) if snapshot_file_name
  end

  def take_snapshot(html)
    kit = IMGKit.new(html).to_jpg
    file = Tempfile.new(["snapshot_#{self.id.to_s}", 'jpg'], 'tmp', :encoding => 'ascii-8bit')
    file.binmode
    file.write(kit)
    file.flush
    self.snapshot = file
    self.save
    file.unlink
  end

  def as_json(options = nil)
    h = super(options)

    h[:thumb_url] = thumb_url
    h[:salaries_count] = salaries.count
    h[:placeholders] = placeholders
    h[:errors] = errors

    h
  end

  private

  def ensure_template_has_no_salaries
    if salaries.count > 0
      errors.add(:base,
                 I18n.t('salary_template.errors.unable_to_destroy_a_template_which_has_salaries'))
      false
    end
  end

end
