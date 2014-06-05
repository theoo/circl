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
# Table name: invoice_templates
#
# *id*::                    <tt>integer, not null, primary key</tt>
# *title*::                 <tt>string(255), default(""), not null</tt>
# *html*::                  <tt>text, default(""), not null</tt>
# *created_at*::            <tt>datetime</tt>
# *updated_at*::            <tt>datetime</tt>
# *with_bvr*::              <tt>boolean, default(FALSE)</tt>
# *bvr_address*::           <tt>text, default("")</tt>
# *bvr_account*::           <tt>string(255), default("")</tt>
# *snapshot_file_name*::    <tt>string(255)</tt>
# *snapshot_content_type*:: <tt>string(255)</tt>
# *snapshot_file_size*::    <tt>integer</tt>
# *snapshot_updated_at*::   <tt>datetime</tt>
# *show_invoice_value*::    <tt>boolean, default(TRUE)</tt>
#--
# == Schema Information End
#++

class InvoiceTemplate < ActiveRecord::Base

  ################
  ### INCLUDES ###
  ################

  include ChangesTracker

  #################
  ### CALLBACKS ###
  #################

  before_destroy :ensure_there_is_no_invoices, :ensure_there_is_no_subscriptions

  ###################
  ### VALIDATIONS ###
  ###################

  # validations
  validates_presence_of :title, :html, :language_id
  validate :bvr_address_and_account_are_set
  validate :bvr_account_match_requirements
  validates_uniqueness_of :title

  # Validate fields of type 'string' length
  validates_length_of :title, maximum: 255
  validates_length_of :bvr_account, maximum: 255

  # Validate fields of type 'text' length
  validates_length_of :html, maximum: 65536
  validates_length_of :bvr_address, maximum: 65536

  #################
  ### RELATIONS ###
  #################

  belongs_to :language
  has_many :invoices
  has_many :subscriptions, through: :subscription_values
  has_many :subscription_values
  has_attached_file :snapshot,
    default_url: '/images/missing_thumbnail.png',
    default_style: :thumb,
    use_timestamp: true,
    styles: {medium: "420x594>",thumb: "105x147>"}

  ########################
  ### INSTANCE METHODS ###
  ########################

  # Returns a list of all available placeholders for an invoice.
  def placeholders
    # Stub
    i = Invoice.new(invoice_template: self,
                    owner: Person.new,
                    buyer: Person.new,
                    receiver: Person.new,
                    created_at: Time.now)
    p = i.placeholders
    h = {}
    %w(simples iterators).each { |i| h[i] = p[i.to_sym].keys.sort }
    h
  end

  def thumb_url
    snapshot.url(:thumb) if snapshot_file_name
  end

  def take_snapshot(html)
    kit = IMGKit.new(html).to_jpg
    file = Tempfile.new(["snapshot_#{self.id.to_s}", 'jpg'], 'tmp', encoding: 'ascii-8bit')
    file.binmode
    file.write(kit)
    file.flush
    self.snapshot = file
    self.save!
    file.unlink
  end

  def as_json(options = nil)
    h = super(options)

    h[:thumb_url] = thumb_url

    h[:language_name] = language.try(:name)
    h[:invoices_count] = invoices.count
    h[:placeholders] = placeholders
    h[:errors] = errors

    h
  end

  private

  def bvr_address_and_account_are_set
    if with_bvr
      if bvr_address.blank? or bvr_account.blank?
        errors.add(:with_bvr,
                   I18n.t('invoice_template.errors.bvr_address_and_bvr_account_are_required_if_with_bvr_is_set'))
        return false
      end
    end
  end

  def bvr_account_match_requirements
    if with_bvr # don't check if with_bvr isn't set
      unless bvr_account.match(/^[0-9]{1,2}-[0-9]{1,6}-[0-9]$/)
        errors.add(:bvr_account,
                   I18n.t('invoice_template.errors.bvr_account_must_match_format'))
        return false
      end
    end
  end

  def ensure_there_is_no_invoices
    unless invoices.empty?
      errors.add(:base,
                 I18n.t('invoice_template.errors.can_not_delete_if_invoices_are_subscribed'))
      return false
    end
  end

  def ensure_there_is_no_subscriptions
    unless subscriptions.empty?
      errors.add(:base,
                 I18n.t('invoice_template.errors.can_not_delete_if_subscriptions_are_subscribed'))
      return false
    end
  end

end
