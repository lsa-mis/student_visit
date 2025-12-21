class AddInformationEmailAddressToPrograms < ActiveRecord::Migration[8.1]
  def change
    add_column :programs, :information_email_address, :string
  end
end
