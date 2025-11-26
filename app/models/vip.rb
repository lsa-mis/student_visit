class Vip < ApplicationRecord
  belongs_to :department
  has_many :calendar_event_faculty, dependent: :destroy
  has_many :calendar_events, through: :calendar_event_faculty
  has_many :appointments, dependent: :destroy

  validates :name, presence: true

  scope :ordered, -> { order(:ranking, :name) }

  def display_name
    [title, name].compact.reject(&:blank?).join(" ")
  end
end
