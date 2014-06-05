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

module DeviseHelper
  # TODO make this use ApplicationHelper#error_messages_for
  def devise_error_messages!
    return "" if resource.errors.empty?

    messages = resource.errors.full_messages.map { |msg| content_tag(:li, msg) }.join
    sentence = I18n.t('activerecord.errors.template.header',
                      count: resource.errors.count,
                      resource: resource.class.model_name.human.downcase)

    haml_tag :div, class: 'error_explanation ui-state-error ui-corner-all' do
      haml_tag :h2 do
        haml_tag :span, class: 'ui-icon ui-icon-alert float_left'
        haml_concat sentence
      end
      haml_tag :ul do
        haml_concat messages
      end
    end
  end
end
