class CreateDepartments < ActiveRecord::Migration[8.1]
  def change
    create_table :departments do |t|
      t.string :name, null: false
      t.string :street_address
      t.text :google_map_url
      t.integer :active_program_id

      t.timestamps
    end

    add_index :departments, :name, unique: true
  end
end
