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
# Table name: salaries_templates
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

class GenericTemplate < ActiveRecord::Base

  # templates table name is a reserved words
  self.table_name = :generic_templates

  ###################
  ### CALLBACKS #####
  ###################

  before_destroy :ensure_template_has_no_salaries

  ################
  ### INCLUDES ###
  ################

  # include ChangesTracker
  include ElasticSearch::Mapping
  include ElasticSearch::Indexing

  #################
  ### RELATIONS ###
  #################

  belongs_to :language
  has_many :salaries,
           class_name: 'Salaries::Salary'

  has_attached_file :odt,
                    default_url: '/assets/generic_template.odt',
                    use_timestamp: true

  has_attached_file :snapshot,
                    default_url: '/images/missing_thumbnail.png',
                    default_style: :thumb,
                    use_timestamp: true,
                    styles: {medium: ["420x594>", :png], thumb: ["105x147>", :png]}

  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :title, :class_name, :language_id
  validates_uniqueness_of :title

  # Validate fields of type 'string' length
  validates_length_of :title, maximum: 255

  validates_attachment :odt,
    content_type: { content_type: /^application\// }

  validates_attachment :snapshot,
    content_type: { content_type: [ /^image\//, "application/pdf" ] }


  ########################
  ### INSTANCE METHODS ###
  ########################

  def thumb_url
    snapshot.url(:thumb) if snapshot_file_name
  end

  def take_snapshot
    # TODO move to AttachmentGenerator
    # Convert to PDF in the same dir
    if odt.try(:path)
      system("lowriter --headless --convert-to pdf \"#{odt.path}\" --outdir \"#{odt.path.gsub(/([^\/]+.odt)$/, "")}\"")

      # Open new file
      pdf_path = odt.path.gsub(/\.odt$/,".pdf")
      pdf_file = File.open(pdf_path, "r")

      # will be converted in png when calling :thumb
      self.snapshot = pdf_file
      self.save
    end
  end

  def as_json(options = nil)
    h = super(options)

    h[:thumb_url] = thumb_url
    h[:odt_url] = odt.url

    assoc = class_name.split("::").last.downcase.pluralize
    if self.respond_to? assoc
      h[:association_count] = self.send(assoc).count
    else
      h[:association_count] = I18n.t("common.none")
    end

    h[:errors] = errors

    h
  end

  private

  def ensure_template_has_no_salaries
    if salaries.count > 0
      errors.add(:base,
                 I18n.t('template.errors.unable_to_destroy_a_template_which_has_salaries'))
      false
    end
  end

end
