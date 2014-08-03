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
      haml_tag :div, class: 'alert alert-info timoutable' do
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
    when Tire::Results::Item
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

end
