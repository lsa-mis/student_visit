class AddAddressFieldsToDepartments < ActiveRecord::Migration[8.1]
  def change
    add_column :departments, :building_name, :string
    add_column :departments, :main_office_room_number, :string
    add_column :departments, :city, :string
    add_column :departments, :state, :string
    add_column :departments, :zipcode, :string
    add_column :departments, :main_office_phone_number, :string
  end
end
