class CreateDepartmentAdmins < ActiveRecord::Migration[8.1]
  def change
    create_table :department_admins do |t|
      t.references :user, null: false, foreign_key: true
      t.references :department, null: false, foreign_key: true

      t.timestamps
    end

    add_index :department_admins, [ :user_id, :department_id ], unique: true
  end
end
