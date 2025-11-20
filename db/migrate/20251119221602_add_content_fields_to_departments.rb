class AddContentFieldsToDepartments < ActiveRecord::Migration[8.1]
  def change
    add_column :departments, :mission_statement, :text
  end
end
