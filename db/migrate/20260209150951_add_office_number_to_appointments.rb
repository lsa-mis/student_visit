class AddOfficeNumberToAppointments < ActiveRecord::Migration[8.1]
  def change
    add_column :appointments, :office_number, :string
  end
end
