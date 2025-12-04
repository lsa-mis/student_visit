class CreateAffiliatedResources < ActiveRecord::Migration[8.1]
  def change
    create_table :affiliated_resources do |t|
      t.references :department, null: false, foreign_key: true
      t.string :name, null: false
      t.string :url, null: false
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :affiliated_resources, [ :department_id, :position ]
  end
end
