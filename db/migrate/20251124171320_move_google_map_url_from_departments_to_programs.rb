class MoveGoogleMapUrlFromDepartmentsToPrograms < ActiveRecord::Migration[8.1]
  def up
    # Add google_map_url to programs
    add_column :programs, :google_map_url, :text

    # Migrate existing data from departments to their active programs
    execute <<-SQL
      UPDATE programs
      SET google_map_url = (
        SELECT departments.google_map_url
        FROM departments
        WHERE departments.id = programs.department_id
          AND departments.active_program_id = programs.id
          AND departments.google_map_url IS NOT NULL
      )
      WHERE EXISTS (
        SELECT 1
        FROM departments
        WHERE departments.id = programs.department_id
          AND departments.active_program_id = programs.id
          AND departments.google_map_url IS NOT NULL
      )
    SQL

    # Remove google_map_url from departments
    remove_column :departments, :google_map_url
  end

  def down
    # Add google_map_url back to departments
    add_column :departments, :google_map_url, :text

    # Migrate data back from active programs to departments
    execute <<-SQL
      UPDATE departments
      SET google_map_url = (
        SELECT programs.google_map_url
        FROM programs
        WHERE programs.department_id = departments.id
          AND programs.id = departments.active_program_id
          AND programs.google_map_url IS NOT NULL
      )
      WHERE EXISTS (
        SELECT 1
        FROM programs
        WHERE programs.department_id = departments.id
          AND programs.id = departments.active_program_id
          AND programs.google_map_url IS NOT NULL
      )
    SQL

    # Remove google_map_url from programs
    remove_column :programs, :google_map_url
  end
end
