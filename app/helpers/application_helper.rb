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

module ApplicationHelper

  # build the container for flash messages
  def flash_messages
    if flash[:notice]
      haml_tag :div, class: 'alert alert-info timeoutable' do
        haml_tag :button, class: 'close', "data-dismiss" => "alert", "aria-hidden" => true do
          haml_concat "&times;"
        end
        haml_concat flash[:notice]
      end
    end

    if flash[:error] or flash[:alert]
      haml_tag :div, class: 'alert alert-danger' do
        haml_tag :button, class: 'close', "data-dismiss" => "alert", "aria-hidden" => true do
          haml_concat "&times;"
        end
        haml_concat flash[:alert]
        haml_concat flash[:error]
      end
    end
  end

  # build the container for error messages
  def error_messages_for(obj)
    if obj.errors && obj.errors.any?
      haml_tag :div, class: 'alert alert-danger' do
        haml_tag :h2 do
          haml_concat I18n.t('activerecord.errors.template.header', model: 'model', count: obj.errors.count)
        end
        haml_tag :p, I18n.t('activerecord.errors.template.body')
        haml_tag :ul do
          obj.errors.messages.each_pair do |key,msg|
            haml_tag :li do
              haml_tag :b, key.to_s.humanize + ":"
              haml_concat msg.join(", ")
            end
          end
        end
      end
    end
  end

  # To extract informations from ES results or people import
  def relation_to_string(obj)
    # Work around Ruby's "smart" real class hiding for relations
    obj = obj.to_a if obj.class == Array

    case obj
    when Array
      obj.map{ |o| relation_to_string(o) }.join ', '
    when Hash # FIXME migrate Tire::Results::Item to ElasticSearch
      if obj.full_name
        return obj.full_name
      elsif obj.string
        return obj.string
      elsif obj.title
        return obj.title
      else
        return obj.name
      end
    else
      %w{full_name as_string name title to_s}.each do |s|
        return obj.send(s) if obj.respond_to?(s)
      end
    end
  end

  # To highlight results from ES
  def highlight(obj, field)
    field = field.to_sym
    if obj.highlight && obj.highlight.to_hash.has_key?(field)
      relation_to_string obj.highlight.send(field).join
    else
      relation_to_string(obj.send(field))
    end
  end

  def affair_value_summary(affair)

    capture_haml do
      haml_tag "table.affair_value" do
        if ApplicationSetting.value('use_vat')
          without_taxes_translation = I18n.t("affair.views.value.without_taxes")
        else
          without_taxes_translation = I18n.t("affair.views.value.value")
        end

        if affair.value != affair.compute_value

          haml_tag :tr do
            haml_tag :td do
              haml_tag "strike.text-danger", affair.compute_value.to_view
            end
            haml_tag :td, I18n.t("affair.views.value.computed")
          end

          haml_tag :tr do
            haml_tag :td do
              haml_tag ".text-danger", (affair.value - affair.compute_value).to_view
            end
            haml_tag :td, I18n.t("affair.views.value.bid")
          end

          haml_tag :tr do
            haml_tag :td, affair.value.to_view
            haml_tag :td, without_taxes_translation
          end

        else

          haml_tag :tr do
            haml_tag :td, affair.value.to_view
            haml_tag :td, without_taxes_translation
          end

        end

        if ApplicationSetting.value('use_vat')

          haml_tag :tr do
            haml_tag :td, affair.vat.to_view
            haml_tag :td, I18n.t("affair.views.value.vat")
          end

          haml_tag :tr do
            haml_tag :td, affair.value_with_taxes.to_view
            haml_tag :td, I18n.t("affair.views.value.with_taxes")
          end

        end

      end # table

    end # value
  end

  def invoice_value_summary(invoice)
    capture_haml do
      haml_tag "table.affair_value" do
        if ApplicationSetting.value('use_vat')
          without_taxes_translation = I18n.t("affair.views.value.without_taxes")
        else
          without_taxes_translation = I18n.t("affair.views.value.value")
        end

        haml_tag :tr do
          haml_tag :td, invoice.value.to_view
          haml_tag :td, without_taxes_translation
        end

        if ApplicationSetting.value('use_vat')

          haml_tag :tr do
            haml_tag :td, invoice.vat.to_view
            haml_tag :td, I18n.t("affair.views.value.vat")
          end

          haml_tag :tr do
            haml_tag :td, invoice.value_with_taxes.to_view
            haml_tag :td, I18n.t("affair.views.value.with_taxes")
          end

        end

      end # table

    end # value
  end

  def creditor_value_summary(creditor)
    capture_haml do
      haml_tag "table.affair_value" do
        if ApplicationSetting.value('use_vat')
          without_taxes_translation = I18n.t("affair.views.value.without_taxes")
        else
          without_taxes_translation = I18n.t("affair.views.value.value")
        end

        haml_tag :tr do
          haml_tag :td, creditor.value.to_view
          haml_tag :td, without_taxes_translation
        end

        if ApplicationSetting.value('use_vat')
          haml_tag :tr do
            haml_tag :td, creditor.vat.to_view
            haml_tag :td, I18n.t("affair.views.value.vat")
          end
        end

        if ApplicationSetting.value('use_vat')
          haml_tag :tr do
            haml_tag :td, creditor.value_with_taxes.to_view
            haml_tag :td, I18n.t("affair.views.value.with_taxes")
          end
        end

      end # table

    end # value
  end

  def creditor_discount_value_and_date(creditor)
    capture_haml do
      haml_tag "table.affair_value" do
        if creditor.discount_ends_on
          haml_tag :tr do
            haml_tag :td, I18n.l(creditor.discount_ends_on)
            haml_tag :td, ""
          end
        end

        if creditor.discount_percentage and creditor.discount_percentage > 0
          haml_tag :tr do
            haml_tag :td, creditor.discount_percentage
            haml_tag :td, "%"
          end
        end

        if creditor.discount_value > 0
          haml_tag :tr do
            haml_tag :td do
              haml_tag ".text-danger", "-#{creditor.discount_value.to_view}"
            end
            haml_tag :td, ""
          end
        end

      end # table

    end # value
  end

end
