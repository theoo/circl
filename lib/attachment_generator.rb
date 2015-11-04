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

  # TODO remove useless reference and provide template overriding instead.
  def initialize(object, reference = nil, relations = [])
    # TODO limit access to object, provide a list of allowd methods

    # Object used in block
    if reference
      @object = reference
    else
      @object = object
    end
    # Object used in document as placeholder
    # TODO It has to be a clone because render_odt is corrupting object. Text field contains <text:line-break/>
    # instead of \n afterwards !
    @o = object.dup
  end

  def pdf
    prepare

    # Convert to PDF in the same dir of odt
    system("lowriter --headless --convert-to pdf \"#{@tmp_file.path}\" --outdir \"#{@tmp_file.path.gsub(/([^\/]+.odt)$/, "")}\"")
    @pdf_path = @tmp_file.path.gsub(/\.odt$/,".pdf")

    if File.exists?(@pdf_path)
      @pdf_file = File.open(@pdf_path, "r")
    else
      @pdf_file = File.open(@general_error_file_path, "r")
    end

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
    system("lowriter --headless --convert-to html \"#{@tmp_file.path}\" --outdir \"#{@tmp_file.path.gsub(/([^\/]+.odt)$/, "")}\"")
    @html_path = @tmp_file.path.gsub(/\.odt$/,".html")

    if File.exists?(@html_path)
      @html_file = File.open(@html_path, "r")
    else
      @html_file = File.open(@general_error_file_path, "r")
    end

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

    if File.exists?(@tmp_file)
      @odt_file = File.open(@tmp_file, "r")
    else
      @odt_file = File.open(@general_error_file_path, "r")
    end

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
    id = @o.try(:id) || "export"
    @tmp_file = Tempfile.new(['pdf_generation' + id.to_s, '.odt'], :encoding => 'ascii-8bit')
    @tmp_file.binmode

    @general_error_file_path = "app/assets/odt/error.pdf"

    I18n.locale = @object.template.language.symbol

    begin
      render_odt @object.template.odt.path, @tmp_file.path
    rescue Exception => @e
      render_odt [Rails.root, "app/assets/odt/error.odt"].join("/"), @tmp_file.path
    end

  end

  def cleanup
    # No need to destroy odt_file which is tmp_file
    if @pdf_file.try(:path) != @general_error_file_path
      File.delete(@pdf_path) if @pdf_file
      File.delete(@html_path) if @html_file
    end
    @tmp_file.unlink
  end

end