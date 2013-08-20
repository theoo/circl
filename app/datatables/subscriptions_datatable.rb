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

class SubscriptionsDatatable
  delegate :params, :h, :link_to, :number_to_currency, to: :@view

  def initialize(view)
    @view = view
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: Subscription.count,
      iTotalDisplayRecords: subscriptions.total_entries,
      aaData: data
    }
  end

  private

  def data

    edit_subscription_trad = I18n.t('subscription.views.contextmenu.edit_subscription')
    view_subscription_members_trad = I18n.t('subscription.views.contextmenu.view_subscription_members')
    view_subscription_buyers_trad = I18n.t('subscription.views.contextmenu.view_subscription_buyers')
    view_subscription_receivers_trad = I18n.t('subscription.views.contextmenu.view_subscription_receivers')
    view_subscription_members_who_paid_trad = I18n.t('subscription.views.contextmenu.view_subscription_members_who_paid')
    view_subscription_members_who_didnt_paid_trad = I18n.t('subscription.views.contextmenu.view_subscription_members_who_didnt_paid')
    add_members_to_subscription_trad = I18n.t('subscription.views.contextmenu.add_members_to_subscription')
    remove_members_from_subscription_trad = I18n.t('subscription.views.contextmenu.remove_members_from_subscription')
    view_subscription_pdf_trad = I18n.t('subscription.views.contextmenu.view_subscription_pdf')
    transfer_overpaid_value_trad = I18n.t('subscription.views.contextmenu.transfer_overpaid_value')
    subscription_reminder_trad = I18n.t('subscription.views.contextmenu.subscription_reminder')
    destroy_subscription_trad = I18n.t('subscription.views.contextmenu.destroy_subscription')

    subscriptions.map do |subscription|
      actions = [ edit_subscription_trad,
                  add_members_to_subscription_trad,
                  view_subscription_pdf_trad ]

      actions << remove_members_from_subscription_trad if subscription.receipts.count <= 0 and subscription.people.count > 0
      if subscription.people.count > 0
        actions << view_subscription_members_trad
       actions << view_subscription_buyers_trad
        actions << view_subscription_receivers_trad
      end
      actions << view_subscription_members_who_paid_trad if subscription.receipts.count > 0
      actions << view_subscription_members_who_didnt_paid_trad if subscription.people.count > 0
      actions << transfer_overpaid_value_trad if subscription.overpaid_value > 0.to_money
      actions << subscription_reminder_trad if subscription.receipts.count < subscription.invoices.size
      actions << destroy_subscription_trad if subscription.receipts.count <= 0

      values_summary = subscription.values.map do |v|
        if v.private_tag
          "#{v.private_tag.name}: #{v.value.to_view}"
        else
          "*: #{v.value.to_view}"
        end
      end.join("<br />")

      {
        0 => subscription.id,
        1 => subscription.parent_id,
        2 => subscription.title,
        3 => values_summary,
        4 => subscription.invoices.count,
        5 => subscription.receipts.count,
        6 => subscription.invoices_value.to_view,
        7 => subscription.receipts_value.to_view,
        8 => subscription.overpaid_value.to_money.to_view,
        9 => subscription.created_at,
        'id' => subscription.id,
        'actions' => actions,
        'level' => subscription.tree_level,
        'number_columns' => [4,5,3,6,7,8]
     }
    end
  end

  def subscriptions
    @subscriptions ||= fetch_subscriptions
  end

  def fetch_subscriptions
    subscriptions = Subscription.select("s.*")
      .from("subscriptions_as_tree() s")
      .joins("LEFT JOIN affairs_subscriptions ON affairs_subscriptions.subscription_id = s.id")
      .joins("LEFT JOIN affairs ON affairs.id = affairs_subscriptions.affair_id")
      .joins("LEFT JOIN invoices ON invoices.affair_id = affairs.id")
      .joins("LEFT JOIN receipts ON receipts.invoice_id = invoices.id")
      .group('s.id,
              s.parent_id,
              s.title,
              s.description,
              s.interval_starts_on,
              s.interval_ends_on,
              s.created_at,
              s.updated_at,
              s.sort')

    if params[:sSearch].present?
      param = params[:sSearch].to_s.gsub('\\'){ '\\\\' } # We use the block form otherwise we need 8 backslashes
      if param.is_i?
        subscriptions = subscriptions.where("s.id = ? OR s.parent_id = ?", param, param)
      else
        subscriptions = subscriptions.where("s.title #{SQL_REGEX_KEYWORD} ?", param)
      end
    end

    if sort_column == 'id' or sort_column == 'parent_id'
      order = "s.sort #{sort_direction}, s.id #{sort_direction}"
    else
      order = "#{sort_column} #{sort_direction}"
    end
    subscriptions = subscriptions.order(order)
    subscriptions = subscriptions.page(page).per_page(per_page)
    subscriptions
  end

  def page
    (params[:iDisplayStart].to_i/per_page) + 1
  end

  def per_page
    (params[:iDisplayLength].to_i > 0) ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = %w{id parent_id title value invoices receipts invoices_value receipts_value overpaid_value created_at}
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == 'desc' ? 'desc' : 'asc'
  end
end
