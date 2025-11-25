class AddHeldOnDatesToPrograms < ActiveRecord::Migration[8.1]
  def change
    add_column :programs, :held_on_dates, :json
  end
end
