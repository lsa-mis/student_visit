class AddDisplayOnStudentDashboardToVips < ActiveRecord::Migration[8.1]
  def change
    add_column :vips, :display_on_student_dashboard, :boolean, default: false, null: false
  end
end
