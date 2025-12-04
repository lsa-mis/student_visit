class CreateAppointmentSelections < ActiveRecord::Migration[8.1]
  def change
    create_table :appointment_selections do |t|
      t.references :appointment, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :action, null: false

      t.timestamps
    end

    add_index :appointment_selections, [ :appointment_id, :user_id ]
  end
end
