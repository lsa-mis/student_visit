class Student::QuestionnairesController < ApplicationController
  before_action :set_program
  before_action :set_questionnaire, only: [ :show, :edit, :update ]
  before_action :ensure_enrolled

  def index
    authorize [:student, :questionnaire], :index?
    @questionnaires = @program.questionnaires.includes(:questions)
  end

  def show
    authorize [:student, :questionnaire], :show?
    @questions = @questionnaire.questions.includes(:answers)
    @answers = current_user.answers.where(program: @program, question: @questions).index_by(&:question_id)
  end

  def edit
    authorize [:student, :questionnaire], :edit?
    @questions = @questionnaire.questions.order(:position)
    @answers = current_user.answers.where(program: @program, question: @questions).index_by(&:question_id)
  end

  def update
    authorize [:student, :questionnaire], :update?

    if @program.questionnaire_due?
      redirect_to student_department_program_questionnaire_path(@program.department, @program, @questionnaire),
                  alert: "The questionnaire deadline has passed. You can no longer edit your answers."
      return
    end

    params[:answers]&.each do |question_id, answer_data|
      question = @questionnaire.questions.find_by(id: question_id)
      next unless question

      answer = current_user.answers.find_or_initialize_by(
        question: question,
        program: @program
      )

      answer.content = answer_data[:content]
      answer.save
    end

    redirect_to student_department_program_questionnaire_path(@program.department, @program, @questionnaire),
                notice: "Your answers have been saved."
  end

  private

  def set_program
    @program = Program.find(params[:program_id])
    @department = @program.department
  end

  def set_questionnaire
    @questionnaire = @program.questionnaires.find(params[:id])
  end

  def ensure_enrolled
    # Allow department admins and super admins to preview student views
    return if current_user&.super_admin?
    return if current_user&.department_admin? && current_user.department_admin_for?(@program.department)

    unless current_user&.enrolled_in_program?(@program)
      redirect_to student_dashboard_path, alert: "You are not enrolled in this program."
    end
  end

  def current_user
    Current.user
  end
end
