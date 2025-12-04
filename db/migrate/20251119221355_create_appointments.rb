class CreateAppointments < ActiveRecord::Migration[8.1]
  def change
    create_table :appointments do |t|
      t.references :program, null: false, foreign_key: true
      t.references :vip, null: false, foreign_key: true
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.references :student, null: true, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :appointments, [ :program_id, :start_time ]
    add_index :appointments, [ :vip_id, :start_time ]
  end
end
