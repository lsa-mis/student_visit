class CreateStudentPrograms < ActiveRecord::Migration[8.1]
  def change
    create_table :student_programs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :program, null: false, foreign_key: true

      t.timestamps
    end

    add_index :student_programs, [:user_id, :program_id], unique: true
  end
end
