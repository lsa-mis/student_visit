class AppointmentSelection < ApplicationRecord
  belongs_to :appointment
  belongs_to :user

  validates :action, presence: true, inclusion: { in: %w[selected deleted] }
end
