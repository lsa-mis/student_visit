class Student::MapController < ApplicationController
  before_action :set_department
  before_action :set_program

  def show
    authorize [ :student, :map ], :show?
  end

  private

  def set_department
    @department = Department.find(params[:department_id])
  end

  def set_program
    @program = @department.active_program
  end
end
