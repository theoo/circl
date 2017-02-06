class GenericTemplate < ApplicationRecord

  # templates table name is a reserved words
  self.table_name = :generic_templates

  ###################
  ### CALLBACKS #####
  ###################

  before_destroy :ensure_template_has_no_salaries

  ################
  ### INCLUDES ###
  ################

  include SearchEngineConcern

  #################
  ### RELATIONS ###
  #################

  belongs_to :language
  has_many :salaries,
           class_name: 'Salaries::Salary'

  has_attached_file :odt,
                    default_url: '/assets/generic_template.odt',
                    use_timestamp: true

  has_attached_file :snapshot,
                    default_url: '/images/missing_thumbnail.png',
                    default_style: :thumb,
                    use_timestamp: true,
                    styles: {medium: ["420x594>", :png], thumb: ["105x147>", :png]}

  ###################
  ### VALIDATIONS ###
  ###################

  validates_presence_of :title, :class_name, :language_id
  validates_uniqueness_of :title

  # Validate fields of type 'string' length
  validates_length_of :title, maximum: 255

  validates_attachment :odt,
    content_type: { content_type: /^application\// }

  validates_attachment :snapshot,
    content_type: { content_type: [ /^image\//, "application/pdf" ] }


  ########################
  ### INSTANCE METHODS ###
  ########################

  def thumb_url
    snapshot.url(:thumb) if snapshot_file_name
  end

  def as_json(options = nil)
    h = super(options)

    h[:thumb_url] = thumb_url
    h[:odt_url] = odt.url

    assoc = class_name.split("::").last.downcase.pluralize
    if self.respond_to? assoc
      h[:association_count] = self.send(assoc).count
    else
      h[:association_count] = I18n.t("common.none")
    end

    h[:errors] = errors

    h
  end

  private

  def ensure_template_has_no_salaries
    if salaries.count > 0
      errors.add(:base,
        I18n.t('template.errors.unable_to_destroy_a_template_which_has_salaries'))
      false
    end
  end

end
