class AddImageAltToPrograms < ActiveRecord::Migration[8.1]
  def change
    add_column :programs, :image_alt, :string
    add_column :programs, :image_decorative, :boolean, default: false, null: false
  end
end
