class CreateVips < ActiveRecord::Migration[8.1]
  def change
    create_table :vips do |t|
      t.references :department, null: false, foreign_key: true
      t.string :name, null: false
      t.string :profile_url
      t.string :title
      t.integer :ranking, default: 0

      t.timestamps
    end

    add_index :vips, [:department_id, :ranking]
  end
end
