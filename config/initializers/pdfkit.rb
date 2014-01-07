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


class String
  # Make assets with full path the ugly way
  # TODO Change this to something reasonable like generating correct link when rendering
  def assets_to_full_path!
    gsub!(/(["'])\/?assets\/([^"']+)/, "\\1#{Rails.configuration.settings['directory_url']}/assets/\\2")
  end
end

PDFKit.configure do |config|
  Rails.configuration.settings['pdfkit'].each do |k, v|
    config.send("#{k}=", v)
  end
end

IMGKit.configure do |config|
  Rails.configuration.settings['imgkit'].each do |k, v|
    config.send("#{k}=", v)
  end
end
