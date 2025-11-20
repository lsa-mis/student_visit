class QuestionsController < ApplicationController
  before_action :set_questionnaire
  before_action :set_question, only: [:edit, :update, :destroy]

  def new
    @question = @questionnaire.questions.build
    authorize @question
  end

  def create
    @question = @questionnaire.questions.build(question_params)
    authorize @question

    if @question.save
      redirect_to [@department, @program, @questionnaire], notice: "Question was successfully added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @question
  end

  def update
    authorize @question

    if @question.update(question_params)
      redirect_to [@department, @program, @questionnaire], notice: "Question was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @question
    @question.destroy
    redirect_to [@department, @program, @questionnaire], notice: "Question was successfully deleted."
  end

  private

  def set_questionnaire
    @questionnaire = Questionnaire.find(params[:questionnaire_id])
    @program = @questionnaire.program
    @department = @program.department
  end

  def set_question
    @question = @questionnaire.questions.find(params[:id])
  end

  def question_params
    permitted = params.require(:question).permit(:text, :question_type, :position, :options)

    # Convert options text area (newline-separated) to array
    if permitted[:options].is_a?(String) && permitted[:options].present?
      permitted[:options] = permitted[:options].split("\n").map(&:strip).reject(&:blank?)
    end

    permitted
  end
end
