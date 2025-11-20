class Student::MapController < ApplicationController
  before_action :set_department

  def show
    authorize :student_map, :show?
  end

  private

  def set_department
    @department = Department.find(params[:department_id])
  end
end
