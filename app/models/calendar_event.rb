class CalendarEvent < ApplicationRecord
  belongs_to :program
  has_many :calendar_event_faculties, dependent: :destroy
  has_many :participating_faculty, through: :calendar_event_faculties, source: :vip

  validates :title, :start_time, :end_time, presence: true
  validate :end_time_after_start_time

  scope :upcoming, -> { where("start_time >= ?", Time.current).order(:start_time) }
  scope :past, -> { where("start_time < ?", Time.current).order(start_time: :desc) }

  private

  def end_time_after_start_time
    return unless start_time && end_time

    errors.add(:end_time, "must be after start time") if end_time <= start_time
  end
end
