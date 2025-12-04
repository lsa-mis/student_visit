class CreateCalendarEventFaculty < ActiveRecord::Migration[8.1]
  def change
    create_table :calendar_event_faculties do |t|
      t.references :calendar_event, null: false, foreign_key: true
      t.references :vip, null: false, foreign_key: true

      t.timestamps
    end

    add_index :calendar_event_faculties, [ :calendar_event_id, :vip_id ], unique: true
  end
end
