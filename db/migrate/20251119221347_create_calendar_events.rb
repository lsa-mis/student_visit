class CreateCalendarEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :calendar_events do |t|
      t.references :program, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false

      t.timestamps
    end

    add_index :calendar_events, [ :program_id, :start_time ]
  end
end
