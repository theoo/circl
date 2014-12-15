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

class ProductProgram < ActiveRecord::Base

  ################
  ### INCLUDES ###
  ################

  # include ChangesTracker
  include ElasticSearch::Mapping
  include ElasticSearch::Indexing
  extend  MoneyComposer

  # Used for import
  attr_accessor :notices

  #################
  ### CALLBACKS ###
  #################

  # TODO prevent destroy if has product
  after_initialize do
    @notices = ActiveModel::Errors.new(self)
  end

  #################
  ### RELATIONS ###
  #################

  has_many :product_items, class_name: 'AffairsProductsProgram',
   foreign_key: 'program_id',
   dependent: :destroy
  has_many :products, through: :product_items
  has_many :affairs,  through: :product_items

  scope :actives,  -> { where(archive: false)}
  scope :archived, -> { where(archive: true)}

  ###################
  ### VALIDATIONS ###
  ###################

  validates :key, presence: true,
    length: { maximum: 255 },
    uniqueness: true
  validates :program_group, presence: true,
    length: { maximum: 255 }

  ########################
  #### CLASS METHODS #####
  ########################

  def self.parse_csv(file, lines = [], skip_columns = [], do_record = false)
    programs = []
    # in case argument nil is sent
    lines ||= []
    skip_columns ||= []

    # Expected file structure
    columns_list = [
      :key,
      :title,
      :description,
      :program_group,
      :archive ]

    begin
      ProductProgram.transaction do

        csvStruct = Struct.send(:new, *columns_list)

        CSV.parse(file, encoding: 'UTF-8')[1..-1].each_with_index do |row, row_index|
          next if lines.size > 0 and ! lines.index((row_index + 1).to_s)

          row.map!{ |s| (s || '').force_encoding('utf-8').strip }

          p = csvStruct.new(*row)

          if row.size != columns_list.size
            programs << "#{I18n.t('product.errors.line')} #{i+2}: #{I18n.t('product.errors.invalid_line')}"
            next
          end

          if ProductProgram.exists?(key: p.key, program_group: p.program_group)
            # Update
            prog = ProductProgram.where(key: p.key).first

            %w(key title description program_group archive).each do |a|
              next if skip_columns.index(a)
              prog.send(a + "=", p.send(a)) if prog.send(a) != p.send(a) and p.send(a)
            end

            if prog.changed?
              msg = I18n.t("product.notices.the_following_attributes_will_be_updated")
              msg += ": "
              msg += prog.changed.join(", ")
              prog.notices.add :base, msg
            end
          else
            # Create
            attributes = {}
            %w(key title description program_group archive).each do |a|
              next if skip_columns.index(a)
              attributes[a] = p.send(a) if p.send(a)
            end
            prog = ProductProgram.new(attributes)
          end

          prog.save # trig validation
          programs << prog
        end # csv

        raise ActiveRecord::Rollback unless do_record

      end # transaction

    rescue ActiveRecord::Rollback
      # continu e

    rescue Exception => e
      raise e
      programs = I18n.t("product.errors.unable_to_parse_file")
    end

    [programs, columns_list]
  end

  ########################
  ### INSTANCE METHODS ###
  ########################

end
