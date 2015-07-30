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

module Exporter

  class Factory

    def initialize(object_kind, format, options = {})
      raise ArgumentError, "An object kind is required, it should be :custom, :invoices, :receipts or :salaries symbols." if object_kind.nil?

      # To build a double entries table, a data source (resource) and
      # a selector (factory) are required.
      # Resource is generated from object_kind and has a static structure
      # Factory is the engine responsible of formatting the latter resource

      resource = case object_kind
        # if the resources is a collection and the exported lines
        # contains a summary (or a subset) of this collection,
        # then :custom is the right choice.
        # Base::export should be overloaded in the custom factory class (like in oLohnausweisssk or ocas).
        when :custom             then nil

        when :creditors          then Exporter::Creditors.new(options)
        when :invoices           then Exporter::Invoices.new(options)
        when :receipts           then Exporter::Receipts.new(options)
        when :salaries           then Exporter::Salaries.new(options)
        when :salaries_and_taxes then Exporter::SalariesAndTaxes.new(options)
        else raise ArgumentError, "Unsupported object kind '#{@object_kind}'"
      end

      @factory = case format
        when :csv             then Exporter::Csv.new(resource)
        when :banana          then Exporter::Banana.new(resource)
        when :git             then Exporter::Git.new(resource)
        when :office_maker    then Exporter::OfficeMaker.new(resource)
        when :elohnausweisssk then Exporter::Elohnausweisssk.new(resource)
        when :ocas            then Exporter::Ocas.new(resource)
        when :salary_details  then Exporter::SalaryDetails.new(resource)
      end
      raise ArgumentError, "Unsupported format '#{format}'." if @factory.nil?

    end

    def export(items)
      @factory.export(items)
    end

  end

  class Base

    attr_accessor :csv_options

    def initialize(resource)
      @resource = resource
      @csv_options = { :encoding => 'UTF-8' }
    end

    def validate_requirements(item, cols)
      cols.each do |k|
        if k.is_a? Symbol
          unless item.keys.index(k)
            raise ArgumentError, "Argument '#{k}' is missing for '#{item.inspect}'."
          end
        end
      end
    end

    def headers
      raise NotImplementedError, 'you need to subclass & overload this method'
    end

    def map_item(i)
      validate_requirements i, @cols

      @cols.map do |c|
        i[c]
      end
    end

    def export(items)
      CSV.generate(@csv_options) do |csv|
        csv << headers unless headers.blank?
        items.flatten.each do |i|
          ci = @resource.convert(i) # convert object to resource
          if ci.is_a? Array
            ci.each {|e| csv << map_item(e) }
          else
            csv << map_item(ci)     # refactor this resource for its corresponding exporter
          end
        end
      end
    end

  end

end
