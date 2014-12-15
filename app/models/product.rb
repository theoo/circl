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

class Product < ActiveRecord::Base

  ################
  ### INCLUDES ###
  ################

  # include ChangesTracker
  include ElasticSearch::Mapping
  include ElasticSearch::Indexing

  # Used for import
  attr_accessor :notices

  #################
  ### CALLBACKS ###
  #################

  before_validation do
    # Sanitarize booleans
    self.archive ||= false
    self.has_accessories ||= false

    self.price_to_unit_rate ||= 1
    self.unit_symbol ||= "pc" # units are defined in translations

    true
  end

  after_save do
    self.variants.create(selling_price: 0, program_group: 'UNIT') unless self.variants.count > 0
  end

  after_initialize do
    @notices = ActiveModel::Errors.new(self)
  end

  #################
  ### RELATIONS ###
  #################

  belongs_to :provider, class_name: 'Person'
  belongs_to :after_sale, class_name: 'Person'

  has_many :variants, class_name: 'ProductVariant',
                      dependent: :destroy

  has_many :product_items, class_name: 'AffairsProductsProgram',
                           dependent: :destroy

  has_many :programs, -> { uniq }, through: :product_items
  has_many :affairs, -> { uniq }, through: :product_items


  scope :actives,  -> { where(archive: false)}
  scope :archived, -> { where(archive: true)}


  ###################
  ### VALIDATIONS ###
  ###################

  validates :key, presence: true,
                  length: { maximum: 255 },
                  uniqueness: true
  validates :unit_symbol, presence: true,
                          length: { maximum: 255 }
  validates :price_to_unit_rate, presence: true

  ########################
  #### CLASS METHODS #####
  ########################

  # Attributes overridden - JSON API
  def as_json(options = nil)
    h = super(options)

    h[:provider_name]   = provider.try(:name)
    h[:after_sale_name] = after_sale.try(:name)

    h[:affairs_count] = affairs.count
    h[:variants_count] = variants.count

    h[:variants] = variants.map do |v|
      { id: v.id,
        product_id: v.product_id,
        program_group: v.program_group,
        title: v.title,
        buying_price: v.buying_price.to_f,
        buying_price_currency: v.buying_price_currency,
        selling_price: v.selling_price.to_f,
        selling_price_currency: v.selling_price_currency,
        art: v.art.to_f,
        art_currency: v.art_currency,
        created_at: v.created_at,
        updated_at: v.updated_at }
    end

    h[:errors]         = errors

    h
  end

  def available_programs
    # TODO opposit joins
    # Product.find(3).variants.joins("LEFT JOIN product_programs
    # ON product_variants.program_group = product_programs.program_group")
    program_groups = self.variants.map(&:program_group)
    ProductProgram.actives.where(program_group: program_groups)
  end

  def unit_symbol_translated
    I18n.t!("product.units." + self.unit_symbol + ".symbol")
  rescue
    self.unit_symbol
  end

  def self.parse_csv(file, lines = [], skip_columns = [], do_record = false)
    products = []
    # in case argument nil is sent
    lines ||= []
    skip_columns ||= []

    # Expected file structure
    columns_list = [
      :key,
      :title,
      :description,
      :width,
      :height,
      :depth,
      :volume,
      :weight,
      :unit_symbol,
      :price_to_unit_rate,
      :buying_price_1,
      :buying_price_2,
      :buying_price_3,
      :buying_price_4,
      :buying_price_5,
      :buying_price_6,
      :buying_price_7,
      :buying_price_8,
      :buying_price_9,
      :buying_price_10,
      :buying_price_11,
      :buying_price_12,
      :buying_price_13,
      :buying_price_14,
      :buying_price_15,
      :buying_price_16,
      :selling_price_1,
      :selling_price_2,
      :selling_price_3,
      :selling_price_4,
      :selling_price_5,
      :selling_price_6,
      :selling_price_7,
      :selling_price_8,
      :selling_price_9,
      :selling_price_10,
      :selling_price_11,
      :selling_price_12,
      :selling_price_13,
      :selling_price_14,
      :selling_price_15,
      :selling_price_16,
      :art_value_1,
      :art_value_2,
      :art_value_3,
      :art_value_4,
      :art_value_5,
      :art_value_6,
      :art_value_7,
      :art_value_8,
      :art_value_9,
      :art_value_10,
      :art_value_11,
      :art_value_12,
      :art_value_13,
      :art_value_14,
      :art_value_15,
      :art_value_16,
      :program_group_1,
      :program_group_2,
      :program_group_3,
      :program_group_4,
      :program_group_5,
      :program_group_6,
      :program_group_7,
      :program_group_8,
      :program_group_9,
      :program_group_10,
      :program_group_11,
      :program_group_12,
      :program_group_13,
      :program_group_14,
      :program_group_15,
      :program_group_16,
      :currency_symbol,
      :provider_id,
      :after_sale_id,
      :category,
      :has_accessories,
      :archive ]

    begin
      Product.transaction do

        csvStruct = Struct.send(:new, *columns_list)

        CSV.parse(file, encoding: 'UTF-8')[1..-1].each_with_index do |row, row_index|
          next if lines.size > 0 and ! lines.index((row_index + 1).to_s)

          row.map!{ |s| (s || '').force_encoding('utf-8').strip }

          p = csvStruct.new(*row)

          if row.size != columns_list.size
            products << "#{I18n.t('product.errors.line')} #{i+2}: #{I18n.t('product.errors.invalid_line')}"
            next
          end

          if Product.exists?(key: p.key)
            # Update
            prod = Product.where(key: p.key).first

            %w(key title description width height depth volume weight unit_symbol price_to_unit_rate provider_id
              after_sale_id category has_accessories archive).each do |a|
              next if skip_columns.index(a) and not prod.send(a).blank?
              prod.send(a + "=", p.send(a)) if prod.send(a) != p.send(a) and p.send(a)
            end

            if prod.changed?
              msg = I18n.t("product.notices.the_following_attributes_will_be_updated")
              msg += ": "
              msg += prod.changed.join(", ")
              prod.notices.add :base, msg
            end
          else
            # Create
            attributes = {}
            %w(key title description width height depth volume weight unit_symbol price_to_unit_rate provider_id
              after_sale_id category has_accessories archive).each do |a|
              attributes[a] = p.send(a) if p.send(a)
            end
            prod = Product.new(attributes)
          end

          # Check existance of product_programs
          updated_prices = []
          16.times do |t|
            t = t + 1

            next if !! skip_columns.index(t.to_s)

            program_name  = p.send("program_group_" + t.to_s)
            buying_price  = p.send("buying_price_" + t.to_s)
            selling_price = p.send("selling_price_" + t.to_s)

            next if program_name.blank? or selling_price.blank?

            pp = ProductProgram.where(program_group: program_name)
            unless pp.count > 0
              prod.notices.add :base, I18n.t("product.errors.missing_program", program_name: program_name)
              prod.errors.add :base, I18n.t("product.errors.missing_program", program_name: program_name)
              next
            end

            pg = prod.variants.where(program_group: program_name).first
            updated_prices << pg.program_group if pg
            pg ||= prod.variants.new
            pg.assign_attributes(
              program_group: program_name,
              buying_price: buying_price.to_money(p.currency_symbol),
              selling_price: selling_price.to_money(p.currency_symbol),
              art: p.send("art_value_" + t.to_s).to_money(p.currency_symbol) )

            # force update
            prod.variants << pg unless pg.new_record?
          end

          if updated_prices.size > 0
            msg = I18n.t("product.notices.the_following_prices_will_be_updated")
            msg += ": "
            msg += updated_prices.join(", ")
            prod.notices.add :base, msg
          end

          prod.save # trig validation
          products << prod
        end # csv

        raise ActiveRecord::Rollback unless do_record

      end # transaction

    rescue ActiveRecord::Rollback
      # continue

    rescue Exception => e
      raise e
      products = I18n.t("product.errors.unable_to_parse_file")
    end

    [products, columns_list]
  end

  ########################
  ### INSTANCE METHODS ###
  ########################

  private

end
