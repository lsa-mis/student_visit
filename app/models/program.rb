class Program < ApplicationRecord
  belongs_to :department
  has_many :student_programs, dependent: :destroy
  has_many :students, through: :student_programs, source: :user
  has_many :calendar_events, dependent: :destroy
  has_many :questionnaires, dependent: :destroy
  has_many :appointments, dependent: :destroy
  has_many :answers, dependent: :destroy
  has_many :appointment_selections, through: :appointments
  has_many :vips, dependent: :destroy
  has_many :important_links, dependent: :destroy
  has_one_attached :image
  has_rich_text :description if defined?(ActionText)

  validates :name, presence: true
  validates :default_appointment_length, presence: true, numericality: { greater_than: 0 }
  validates :information_email_address, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validate :image_alt_or_decorative_required, if: :should_validate_image_alt?

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  after_save :ensure_single_active_program
  before_save :normalize_held_on_dates
  before_validation :preserve_unset_legacy_image_alt
  before_validation :normalize_image_alt_for_decorative

  # Alt text for the dashboard image. Decorative images use an empty string so
  # assistive technology skips them. Unset legacy alts stay nil so callers can
  # omit empty alt="" (which would hide the image from screen readers).
  def dashboard_image_alt
    return "" if image_decorative?
    image_alt
  end

  # True when the dashboard image can be rendered (e.g. with image_tag). After a
  # failed update that assigns a new upload, ActiveStorage may leave an attached
  # but unpersisted blob that cannot produce a signed_id.
  def displayable_dashboard_image?
    image.attached? && image.blob.persisted?
  end

  # Signed id for a newly assigned dashboard image that has not been saved yet
  # (e.g. after a failed alt-text validation). Used to preserve the upload across
  # the re-rendered edit form.
  def pending_dashboard_image_signed_id
    change = attachment_changes["image"]
    return unless change

    blob = change.respond_to?(:blob) ? change.blob : image.blob
    return unless blob

    blob.save! unless blob.persisted?
    blob.signed_id
  rescue ActiveRecord::RecordInvalid, ActiveStorage::Error
    nil
  end

  def open?
    return false unless open_date && close_date
    now = Time.current
    now >= open_date && now <= close_date
  end

  def closed?
    return true unless close_date
    Time.current > close_date
  end

  def questionnaire_due?
    return false unless questionnaire_due_date
    Time.current > questionnaire_due_date
  end

  # Convert held_on_dates from array of strings to array of Date objects
  def held_on_dates_as_dates
    return [] unless held_on_dates.is_a?(Array)
    held_on_dates.map { |date_str| Date.parse(date_str) rescue nil }.compact
  end

  # Check if a given date is one of the held-on dates
  def held_on_date?(date)
    return false unless held_on_dates.is_a?(Array)
    date_str = date.is_a?(Date) ? date.to_s : date.to_date.to_s
    held_on_dates.include?(date_str)
  end

  # Get all unique dates from held_on_dates
  def held_on_dates_list
    held_on_dates_as_dates.sort
  end

  private

  def normalize_held_on_dates
    return if held_on_dates.nil?

    # Convert array of date strings to normalized date strings (YYYY-MM-DD)
    if held_on_dates.is_a?(Array)
      self.held_on_dates = held_on_dates.map do |date_str|
        date_str = date_str.to_s.strip
        next nil if date_str.blank?
        Date.parse(date_str).to_s rescue nil
      end.compact.uniq.sort
    end
  end

  def ensure_single_active_program
    return unless active?

    department.programs.where.not(id: id).update_all(active: false)
    department.update(active_program_id: id)
  end

  def normalize_image_alt_for_decorative
    self.image_alt = "" if image_decorative?
  end

  # Form fields submit "" for blank inputs. Do not treat that as clearing an
  # unset legacy alt when the author is not changing image metadata.
  def preserve_unset_legacy_image_alt
    return if image_decorative?
    return if attachment_changes.key?("image")
    return if image_decorative_changed?
    return unless image_alt_changed?
    return unless image_alt_was.nil? && image_alt == ""

    self.image_alt = nil
  end

  def should_validate_image_alt?
    return false unless image.attached?
    return true if attachment_changes.key?("image")
    return true if image_decorative_changed?
    return true if image_alt_changed?

    false
  end

  def image_alt_or_decorative_required
    return if image_decorative?
    return if image_alt.present?

    errors.add(:image_alt, "must be provided, or mark the image as decorative")
  end
end
