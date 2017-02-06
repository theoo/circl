# == Schema Information
#
# Table name: product_programs
#
#  id            :integer          not null, primary key
#  key           :string(255)      not null
#  program_group :string(255)      not null
#  title         :string(255)
#  description   :text
#  archive       :boolean          default(FALSE), not null
#  created_at    :datetime
#  updated_at    :datetime
#

class ProductProgram < ApplicationRecord

  ################
  ### INCLUDES ###
  ################

  include SearchEngineConcern
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

  has_many :product_items, class_name: 'ProductItem',
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
      # continue

    rescue Exception => e
      products = I18n.t("product.errors.unable_to_parse_file") + " (" + e.inspect + ")"
    end

    [programs, columns_list]
  end

  ########################
  ### INSTANCE METHODS ###
  ########################

end
