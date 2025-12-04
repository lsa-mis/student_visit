class CreateImportantLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :important_links do |t|
      t.references :program, null: false, foreign_key: true
      t.string :name, null: false
      t.string :url, null: false
      t.integer :ranking, default: 0

      t.timestamps
    end

    add_index :important_links, [ :program_id, :ranking ]
  end
end
