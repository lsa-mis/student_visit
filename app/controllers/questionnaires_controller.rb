class QuestionnairesController < ApplicationController
  before_action :set_program
  before_action :set_questionnaire, only: [ :show, :edit, :update, :responses, :student_response, :export_responses ]

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
      redirect_to [ @department, @program, @questionnaire ], notice: "Questionnaire was successfully created."
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
      redirect_to [ @department, @program, @questionnaire ], notice: "Questionnaire was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def responses
    authorize @questionnaire, :show?
    @questions = @questionnaire.questions.order(:position)

    # Get all students enrolled in the program
    @students = @program.students.includes(:answers)

    # Get all answers for this questionnaire
    question_ids = @questions.pluck(:id)
    @all_answers = Answer.where(program: @program, question_id: question_ids)
                          .includes(:student, :question)
                          .index_by { |a| [ a.user_id, a.question_id ] }

    # Prepare data for charts
    @chart_data = {}
    @questions.each do |question|
      answers_for_question = @all_answers.values.select { |a| a.question_id == question.id }

      case question.question_type
      when "radio", "checkbox"
        # Count responses for each option
        option_counts = {}
        question.options_array.each { |opt| option_counts[opt] = 0 }

        answers_for_question.each do |answer|
          if question.question_type == "checkbox"
            # For checkboxes, content might be an array, JSON array string, or comma-separated string
            content = answer.content
            # Extract plain text from ActionText if it's a RichText object
            content_string = if content.respond_to?(:to_plain_text)
                               content.to_plain_text
                             else
                               content.to_s
                             end
            selected = if content.is_a?(Array)
                        content
                      elsif content_string.start_with?("[") && content_string.end_with?("]")
                        # Try to parse as JSON array string
                        begin
                          JSON.parse(content_string)
                        rescue JSON::ParserError
                          content_string.split(",").map(&:strip)
                        end
                      else
                        content_string.split(",").map(&:strip)
                      end
            selected.each { |opt| option_counts[opt] += 1 if option_counts.key?(opt) }
          else
            # For radio, content is a single value
            # Extract plain text from ActionText if it's a RichText object
            content_value = if answer.content.respond_to?(:to_plain_text)
                              answer.content.to_plain_text
                            else
                              answer.content.to_s
                            end
            option_counts[content_value] += 1 if option_counts.key?(content_value)
          end
        end

        @chart_data[question.id] = {
          type: question.question_type,
          labels: option_counts.keys,
          data: option_counts.values,
          total_responses: answers_for_question.count
        }
      else
        # For text/rich_text/datetime/link, just show count of responses
        @chart_data[question.id] = {
          type: question.question_type,
          total_responses: answers_for_question.count,
          answered_count: answers_for_question.count,
          total_students: @students.count
        }
      end
    end
  end

  def student_response
    authorize @questionnaire, :show?
    @student = @program.students.find(params[:student_id])
    authorize @student, :show? # Ensure department admin can view this student
    @questions = @questionnaire.questions.order(:position)

    # Get answers for this student
    question_ids = @questions.pluck(:id)
    @answers = @student.answers.where(program: @program, question_id: question_ids)
                       .index_by(&:question_id)

    # Get appointments for this student in this program
    @appointments = @program.appointments.where(student: @student)
                           .includes(:vip)
                           .order(:start_time)
  end

  def export_responses
    authorize @questionnaire, :show?

    csv_data = CsvExportService.export_questionnaire_responses(@questionnaire, @program)
    filename = "#{@questionnaire.name.parameterize}-responses-#{Date.current.strftime('%Y-%m-%d')}.csv"

    send_data csv_data,
              filename: filename,
              type: "text/csv; charset=utf-8",
              disposition: "attachment"
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
