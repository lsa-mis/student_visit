class Program < ApplicationRecord
  belongs_to :department
  has_many :student_programs, dependent: :destroy
  has_many :students, through: :student_programs, source: :user
  has_many :calendar_events, dependent: :destroy
  has_many :questionnaires, dependent: :destroy
  has_many :appointments, dependent: :destroy
  has_many :answers, dependent: :destroy
  has_many :appointment_selections, through: :appointments

  validates :name, presence: true
  validates :default_appointment_length, presence: true, numericality: { greater_than: 0 }

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  after_save :ensure_single_active_program

  def open?
    return false unless open_date && close_date
    Time.current >= open_date && Time.current <= close_date
  end

  def closed?
    return true unless close_date
    Time.current > close_date
  end

  def questionnaire_due?
    return false unless questionnaire_due_date
    Time.current > questionnaire_due_date
  end

  private

  def ensure_single_active_program
    return unless active?

    department.programs.where.not(id: id).update_all(active: false)
    department.update(active_program_id: id)
  end
end
