class CalendarEvent < ApplicationRecord
  belongs_to :program
  has_many :calendar_event_faculties, dependent: :destroy
  has_many :participating_faculty, through: :calendar_event_faculties, source: :vip

  has_rich_text :description
  has_rich_text :location
  has_rich_text :notes

  validates :title, :start_time, :end_time, presence: true
  validate :end_time_after_start_time
  validate :start_time_on_held_on_date

  scope :upcoming, -> { where("start_time >= ?", Time.current).order(:start_time) }
  scope :past, -> { where("start_time < ?", Time.current).order(start_time: :desc) }

  private

  def end_time_after_start_time
    return unless start_time && end_time

    errors.add(:end_time, "must be after start time") if end_time <= start_time
  end

  def start_time_on_held_on_date
    return unless start_time && program

    # Skip validation if program has no held-on dates set
    return if program.held_on_dates.blank? || !program.held_on_dates.is_a?(Array) || program.held_on_dates.empty?

    event_date = start_time.to_date
    unless program.held_on_date?(event_date)
      dates_list = program.held_on_dates_list.map { |d| d.strftime("%B %d, %Y") }.join(", ")
      errors.add(:start_time, "must be on one of the program's held-on dates (#{dates_list})")
    end
  end
end
