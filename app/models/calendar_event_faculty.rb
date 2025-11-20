class CalendarEventFaculty < ApplicationRecord
  belongs_to :calendar_event
  belongs_to :vip

  validates :calendar_event_id, uniqueness: { scope: :vip_id }
end
