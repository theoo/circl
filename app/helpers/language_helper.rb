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

module LanguageHelper
  def translations
    I18n.backend.send(:translations)
  end

  # DEAD CODE
  # def select_languages
  #   links = []
  #   I18n.available_locales.each do |loc|
  #     if loc == I18n.locale
  #       links << "<span class='active'>" + translations[loc][:common][:language_name] + "</span>"
  #     else
  #       links << link_to( translations[loc][:common][:language_name], url_for(params.merge(locale: loc)) )
  #     end
  #   end
  #   links.join( " / " )
  # end
end
