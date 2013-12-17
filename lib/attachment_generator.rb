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

require 'serenity'

class AttachmentGenerator

  include Serenity::Generator

  def initialize(object, relations = [])
    @object = object
    @o = object
    # TODO convert to OpenStruct
    # o = @object.as_json
    # relations.each do |r|
    #   o[r.to_sym] = @object.send(r).as_json
    # end

    # @o = RecursiveOpenStruct.new o
  end

  def pdf
    prepare

    # Convert to PDF in the same dir of odt
    system("lowriter --headless --convert-to pdf #{@tmp_file.path} --outdir #{@tmp_file.path.gsub(/([^\/]+.odt)$/, "")}")
    @pdf_path = @tmp_file.path.gsub(/\.odt$/,".pdf")
    @pdf_file = File.open(@pdf_path, "r")
    if block_given?
      yield(@object, @pdf_file)
    else
      file = @pdf_file.read
    end

    cleanup
    file
  end

  def html
    prepare

    # Convert to PDF in the same dir of odt
    system("lowriter --headless --convert-to html #{@tmp_file.path} --outdir #{@tmp_file.path.gsub(/([^\/]+.odt)$/, "")}")
    @html_path = @tmp_file.path.gsub(/\.odt$/,".html")
    @html_file = File.open(@html_path, "r")
    if block_given?
      yield(@object, @html_file)
    else
      file = @html_file.read
    end

    cleanup
    file
  end

  def jpg
    # TODO
  end

  def odt
    prepare
    # Re-read the file
    @odt_file = File.open(@tmp_file.path, "r")
    if block_given?
      yield(@object, @odt_file)
    else
      file = @odt_file.read
    end

    cleanup
    file
  end

  private

  def prepare
    @tmp_file = Tempfile.new(['pdf_generation' + @object.id.to_s, '.odt'], :encoding => 'ascii-8bit')
    @tmp_file.binmode
    @title = "WTF"
    render_odt @object.generic_template.odt.path, @tmp_file.path
  end

  def cleanup
    # No need to destroy odt_file which is tmp_file
    File.delete(@pdf_path) if @pdf_file
    File.delete(@html_path) if @html_file
    @tmp_file.unlink
  end

  # /home/to/Code/rails/circl/public/system/generic_templates/odts/000/000/002/original/salary.odt

end