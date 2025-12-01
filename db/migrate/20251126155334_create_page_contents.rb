class CreatePageContents < ActiveRecord::Migration[8.1]
  def change
    create_table :page_contents do |t|
      t.string :page_path, null: false
      t.string :area_name, null: false

      t.timestamps

      t.index [:page_path, :area_name], unique: true, name: "index_page_contents_on_page_and_area"
    end
  end
end
