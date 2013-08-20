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

module ChangesTracker

  public

  module ClassMethods
    # overloads only works with _ids= and = methods
    def monitored_habtm(name, *args)
      ids = "#{name.to_s.singularize}_ids"

      has_and_belongs_to_many name, *args

      # override "*_ids=" method
      alias_method("old_#{ids}=", "#{ids}=")
      define_method("#{ids}=") do |*a|
        changed_attributes[ids] = send(ids)
        send("old_#{ids}=", *a)
      end

      # override "*=" method
      method = "#{name.to_s}"
      alias_method("old_#{method}=", "#{method}=")
      define_method("#{method}=") do |*a|
        changed_attributes[ids] = send(ids)
        send("old_#{method}=", *a)
      end
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
    base.after_save :track_changes
  end

  def tracked_changes
    @tracked_changes ||= []
  end

  private

  def track_changes
    @tracked_changes = self.changes.reject do |k,v|
      %w{created_at updated_at}.include?(k.to_s)
    end
  end

end
