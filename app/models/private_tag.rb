class PrivateTag < ApplicationRecord

  ################
  ### INCLUDES ###
  ################

  include SearchEngineConcern

  #################
  ### CALLBACKS ###
  #################

  before_destroy :ensure_it_doesnt_have_members

  #################
  ### RELATIONS ###
  #################

  # FIXME: Incompatible with person's HABTM
  # default_scope { order('name ASC') }
  scope :by_usage, -> do
    select("private_tags.id, private_tags.name, private_tags.color, count(people_private_tags.private_tag_id) AS tags_count")
    .joins(:people)
    .group("people_private_tags.private_tag_id, private_tags.id, private_tags.name")
    .order("tags_count DESC")
  end

  # TODO Raises deprecations warnings
  acts_as_tree

  has_and_belongs_to_many :people,
                          -> { distinct },
                          after_add: [:update_elasticsearch_index, :select_parents],
                          after_remove: :update_elasticsearch_index
  has_many :subscription_values,
           -> { order('position ASC') }

  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :name
  validates_uniqueness_of :name, scope: :parent_id
  validate :cannot_be_its_own_parent

  # Validate fields of type 'string' length
  validates_length_of :name, maximum: 255
  validates_format_of :color,
    with: /\A#(?:[0-9a-fA-F]{3}){1,2}\z/,
    allow_blank: true


  ########################
  ### INSTANCE METHODS ###
  ########################

  def cannot_be_its_own_parent
    if parent == self
      errors.add(:parent, I18n.t('tag.errors.cannot_be_its_own_parent'))
      false
    end
  end

  # attributes overridden - JSON API
  def as_json(options = nil)
    h = super(options || {})
    h[:parent_name] = parent.try(:name)
    h[:members_count] = people.count
    h
  end

  def ensure_it_doesnt_have_members
    if self.people.count > 0
      errors.add(:base,
                 I18n.t('tag.errors.cannot_destroy_tag_if_it_has_members'))
      false
    end
  end

  # Recursive!
  def select_parents(person)
    self.parent.people.push person if self.parent
  end

end
