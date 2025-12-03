class ChangeVipsFromDepartmentToProgram < ActiveRecord::Migration[8.1]
  def up
    # Add program_id column (nullable initially)
    add_reference :vips, :program, null: true, foreign_key: true

    # Migrate data: assign each VIP to a program from its department
    # Prefer active program, otherwise use first program
    execute <<-SQL
      UPDATE vips
      SET program_id = (
        SELECT COALESCE(
          (SELECT id FROM programs WHERE department_id = vips.department_id AND active = true LIMIT 1),
          (SELECT id FROM programs WHERE department_id = vips.department_id ORDER BY created_at ASC LIMIT 1)
        )
      )
      WHERE program_id IS NULL
    SQL

    # Make program_id not null
    change_column_null :vips, :program_id, false

    # Remove old department_id column and its indexes
    remove_index :vips, name: "index_vips_on_department_id" if index_exists?(:vips, :department_id)
    remove_index :vips, name: "index_vips_on_department_id_and_ranking" if index_exists?(:vips, [:department_id, :ranking])
    remove_foreign_key :vips, :departments if foreign_key_exists?(:vips, :departments)
    remove_reference :vips, :department, null: false, foreign_key: false

    # Add composite index for program_id and ranking (add_reference already creates index on program_id)
    add_index :vips, [:program_id, :ranking] unless index_exists?(:vips, [:program_id, :ranking])
  end

  def down
    # Add department_id column back
    add_reference :vips, :department, null: true, foreign_key: true

    # Migrate data back: assign each VIP to the department of its program
    execute <<-SQL
      UPDATE vips
      SET department_id = (
        SELECT department_id FROM programs WHERE id = vips.program_id LIMIT 1
      )
      WHERE department_id IS NULL
    SQL

    # Make department_id not null
    change_column_null :vips, :department_id, false

    # Remove program_id column and its indexes
    remove_index :vips, name: "index_vips_on_program_id_and_ranking" if index_exists?(:vips, [:program_id, :ranking])
    remove_foreign_key :vips, :programs if foreign_key_exists?(:vips, :programs)
    remove_reference :vips, :program, null: false, foreign_key: true

    # Add back old indexes for department_id (add_reference already creates index on department_id)
    add_index :vips, [:department_id, :ranking] unless index_exists?(:vips, [:department_id, :ranking])
  end
end
