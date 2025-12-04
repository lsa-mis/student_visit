class CreatePrograms < ActiveRecord::Migration[8.1]
  def change
    create_table :programs do |t|
      t.references :department, null: false, foreign_key: true
      t.string :name, null: false
      t.datetime :open_date
      t.datetime :close_date
      t.datetime :questionnaire_due_date
      t.integer :default_appointment_length, default: 30
      t.boolean :active, default: false

      t.timestamps
    end

    add_index :programs, [ :department_id, :active ]
  end
end
