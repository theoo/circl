class Tag < ActiveRecord::Base
  has_many :taggings
  has_many :people, :through => :taggings
end

class Tagging < ActiveRecord::Base
  belongs_to :tag
  belongs_to :person, :foreign_key => :taggable_id
end

class OldSubscription < ActiveRecord::Base
  has_and_belongs_to_many :people,
                          :uniq => true,
                          :join_table => 'people_subscriptions',
                          :foreign_key => 'subscription_id'
  self.table_name = 'subscriptions'
  belongs_to :subscription_group
end

class SubscriptionGroup < ActiveRecord::Base
  has_many :old_subscriptions
end

class DirectoryBeta2 < ActiveRecord::Migration
  def up
    # Replace acts_as_taggable
    create_table(:public_tags, :timestamps => false) do |t|
      t.integer :parent_id
      t.string  :name, :null => false
    end
    add_index :public_tags, :parent_id

    create_table(:people_public_tags, :id => false) do |t|
      t.integer :person_id
      t.integer :public_tag_id
    end
    add_index :people_public_tags, :person_id
    add_index :people_public_tags, :public_tag_id

    create_table(:private_tags, :timestamps => false) do |t|
      t.integer :parent_id
      t.string  :name, :null => false
    end
    add_index :private_tags, :parent_id

    create_table(:people_private_tags, :id => false) do |t|
      t.integer :person_id
      t.integer :private_tag_id
    end
    add_index :people_private_tags, :person_id
    add_index :people_private_tags, :private_tag_id

    puts 'migrating tags to new schema'
    Tag.all.each do |t|
      new_tag = PrivateTag.create!(:name => t.name)
      new_tag.people = t.people
      new_tag.save
    end

    puts 'migrating subscriptions to new schema'
    OldSubscription.all.each do |s|
      parent = PublicTag.find_or_create_by_name(s.subscription_group.name)
      new_tag = PublicTag.create!(:name => s.name, :parent_id => parent.id)
      new_tag.people = s.people
      new_tag.save
    end

    # destroy unused tables
    %w(tags taggings people_subscriptions subscriptions subscription_groups).each do |t|
      drop_table t
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
