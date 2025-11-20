class QuestionnairesController < ApplicationController
  before_action :set_program
  before_action :set_questionnaire, only: [:show, :edit, :update]

  def index
    @questionnaires = @program.questionnaires.includes(:questions)
    authorize Questionnaire.new(program: @program)
  end

  def show
    authorize @questionnaire
    @questions = @questionnaire.questions.order(:position)
  end

  def new
    @questionnaire = @program.questionnaires.build
    authorize @questionnaire
  end

  def create
    @questionnaire = @program.questionnaires.build(questionnaire_params)
    authorize @questionnaire

    if @questionnaire.save
      redirect_to [@department, @program, @questionnaire], notice: "Questionnaire was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @questionnaire
    @questions = @questionnaire.questions.order(:position)
  end

  def update
    authorize @questionnaire

    if @questionnaire.update(questionnaire_params)
      redirect_to [@department, @program, @questionnaire], notice: "Questionnaire was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_program
    @program = Program.find(params[:program_id])
    @department = @program.department
  end

  def set_questionnaire
    @questionnaire = @program.questionnaires.find(params[:id])
  end

  def questionnaire_params
    params.require(:questionnaire).permit(:name)
  end
end
