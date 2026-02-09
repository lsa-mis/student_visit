class AddOfficeNumberToVips < ActiveRecord::Migration[8.1]
  def change
    add_column :vips, :office_number, :string
  end
end
