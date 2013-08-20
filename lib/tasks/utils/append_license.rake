# encoding: utf-8

namespace :utils do
  namespace :license do
    desc 'Prepend license on files header'
    task :remove => :environment do
      Dir.glob([Rails.root, "app/models", "**/*rb"].join("/")).each do |f|
        print "Loading " + File.basename(f.to_s) + ": "

        content = File.read(f)
        bol = content.index(/^=begin\n\s+CIRCL/)
        eol = content.index(/>\.\n=end\n/)

        if bol.nil? and eol.nil?
          puts red("No license found.")
        else
          print green("Removing license.")
          eol = eol + 7
          puts [bol,eol].join(" -> ")

          bol = bol - 1 unless bol == 0
          eol = eol + 1 unless eol == content.size

          new_content = content[0...bol] + content[eol...content.size]

          File.truncate(f, 0)
          File.open(f, 'r+') do |file|
            file.write new_content
          end
        end
      end
    end

    desc 'Remove license from files header'
    task :prepend => :environment do
      Dir.glob([Rails.root, "app/models", "**/*rb"].join("/")).each do |f|
        print "Loading " + File.basename(f.to_s) + ": "

        content = File.read(f)
        bol = content.index(/^=begin\n\s+CIRCL/)
        eol = content.index(/>\.\n=end/)

        if bol.nil? and eol.nil?
          puts green("Installing license.")
          license = "=begin
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
=end"
          File.truncate(f, 0)
          File.open(f, 'r+') do |file|
            content = license + "\n" + content
            file.write content
          end
        else
          puts red("License already installed.")
        end

      end
    end
  end
end
