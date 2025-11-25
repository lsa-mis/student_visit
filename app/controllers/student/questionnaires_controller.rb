class Student::QuestionnairesController < ApplicationController
  before_action :set_program
  before_action :set_questionnaire, only: [:show, :edit, :update]
  before_action :ensure_enrolled

  def index
    authorize :student_questionnaire, :index?
    @questionnaires = @program.questionnaires.includes(:questions)
  end

  def show
    authorize :student_questionnaire, :show?
    @questions = @questionnaire.questions.includes(:answers)
    @answers = current_user.answers.where(program: @program, question: @questions).index_by(&:question_id)
  end

  def edit
    authorize :student_questionnaire, :edit?
    @questions = @questionnaire.questions.order(:position)
    @answers = current_user.answers.where(program: @program, question: @questions).index_by(&:question_id)
  end

  def update
    authorize :student_questionnaire, :update?

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
    unless current_user.enrolled_in_program?(@program)
      redirect_to student_dashboard_path, alert: "You are not enrolled in this program."
    end
  end

  def current_user
    Current.user
  end
end
