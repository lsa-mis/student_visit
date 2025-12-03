class Appointment < ApplicationRecord
  belongs_to :program
  belongs_to :vip
  belongs_to :student, class_name: "User", optional: true
  has_many :appointment_selections, dependent: :destroy

  validates :start_time, presence: true
  validates :end_time, presence: true
  validate :end_time_after_start_time

  before_validation :set_end_time_from_default_length, if: -> { end_time.blank? && start_time.present? && program.present? }

  scope :available, -> { where(student_id: nil) }
  scope :booked, -> { where.not(student_id: nil) }
  scope :for_vip, ->(vip) { where(vip: vip) }
  scope :for_student, ->(student) { where(student: student) }
  scope :upcoming, -> { where("start_time >= ?", Time.current).order(:start_time) }
  scope :past, -> { where("start_time < ?", Time.current).order(start_time: :desc) }

  def available?
    student_id.nil?
  end

  def booked?
    !available?
  end

  def select_by!(student)
    return false unless available?

    transaction do
      update!(student: student)
      appointment_selections.create!(user: student, action: "selected")
    end
    true
  end

  def release!
    return false unless booked?

    student_user = student
    transaction do
      update!(student: nil)
      appointment_selections.create!(user: student_user, action: "deleted") if student_user
    end
    true
  end

  private

  def set_end_time_from_default_length
    return unless program&.default_appointment_length

    self.end_time = start_time + program.default_appointment_length.minutes
  end

  def end_time_after_start_time
    return unless start_time && end_time

    errors.add(:end_time, "must be after start time") if end_time <= start_time
  end
end
