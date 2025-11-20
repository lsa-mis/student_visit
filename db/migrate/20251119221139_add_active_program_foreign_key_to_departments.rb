class AddActiveProgramForeignKeyToDepartments < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :departments, :programs, column: :active_program_id, on_delete: :nullify
  end
end
