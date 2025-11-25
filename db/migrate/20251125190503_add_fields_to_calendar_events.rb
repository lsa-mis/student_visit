class AddFieldsToCalendarEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :calendar_events, :mandatory, :boolean, default: false, null: false
    remove_column :calendar_events, :description, :text
  end
end
