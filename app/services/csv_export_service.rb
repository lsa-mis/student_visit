require "csv"

class CsvExportService
  def self.export_students(program)
    CSV.generate(headers: true) do |csv|
      # Ensure questionnaires and questions are loaded
      program = Program.includes(questionnaires: :questions).find(program.id)
      questions = program.questionnaires.flat_map { |q| q.questions.order(:position) }
      csv << [ "Email", "Name", "Enrolled Date" ] +
             questions.map { |qn| "Q: #{qn.text}" } +
             [ "Appointments" ]

      program.students.includes(:answers, :appointments).each do |student|
        answers = student.answers.where(program: program).index_by(&:question_id)
        appointments = student.appointments.where(program: program).includes(:vip)

        row = [
          student.email_address,
          student.email_address, # Name field - could be expanded
          student.student_programs.find_by(program: program)&.created_at&.strftime("%Y-%m-%d")
        ]

        program.questionnaires.each do |questionnaire|
          questionnaire.questions.order(:position).each do |question|
            answer = answers[question.id]
            row << (answer&.content || "")
          end
        end

        appointment_list = appointments.map do |apt|
          "#{apt.vip.display_name} - #{apt.start_time.strftime("%m/%d/%Y %I:%M %p")}"
        end.join("; ")
        row << appointment_list

        csv << row
      end
    end
  end

  def self.export_appointments_by_faculty(program)
    CSV.generate(headers: true) do |csv|
      csv << [ "Faculty", "Date", "Start Time", "End Time", "Status", "Student" ]

      program.vips.ordered.each do |vip|
        program.appointments.for_vip(vip).order(:start_time).each do |appointment|
          csv << [
            vip.display_name,
            appointment.start_time.strftime("%Y-%m-%d"),
            appointment.start_time.strftime("%I:%M %p"),
            appointment.end_time.strftime("%I:%M %p"),
            appointment.available? ? "Available" : "Booked",
            appointment.student&.email_address || ""
          ]
        end
      end
    end
  end

  def self.export_appointments_by_student(program)
    CSV.generate(headers: true) do |csv|
      csv << [ "Student Email", "Faculty", "Date", "Start Time", "End Time" ]

      program.students.order(:email_address).each do |student|
        student.appointments.where(program: program).includes(:vip).order(:start_time).each do |appointment|
          csv << [
            student.email_address,
            appointment.vip.display_name,
            appointment.start_time.strftime("%Y-%m-%d"),
            appointment.start_time.strftime("%I:%M %p"),
            appointment.end_time.strftime("%I:%M %p")
          ]
        end
      end
    end
  end

  def self.export_calendar(student, program, date = nil)
    CSV.generate(headers: true) do |csv|
      csv << [ "Type", "Title", "Date", "Start Time", "End Time", "Details" ]

      if date
        start_date = date.beginning_of_day
        end_date = date.end_of_day
      else
        start_date = program.open_date || Time.current.beginning_of_day
        end_date = program.close_date || Time.current.end_of_day
      end

      # Calendar events
      program.calendar_events.where(start_time: start_date..end_date).order(:start_time).each do |event|
        csv << [
          "Event",
          event.title,
          event.start_time.strftime("%Y-%m-%d"),
          event.start_time.strftime("%I:%M %p"),
          event.end_time.strftime("%I:%M %p"),
          event.description
        ]
      end

      # Student appointments
      student.appointments.where(program: program, start_time: start_date..end_date)
             .includes(:vip).order(:start_time).each do |appointment|
        csv << [
          "Appointment",
          appointment.vip.display_name,
          appointment.start_time.strftime("%Y-%m-%d"),
          appointment.start_time.strftime("%I:%M %p"),
          appointment.end_time.strftime("%I:%M %p"),
          "Private meeting"
        ]
      end
    end
  end

  def self.export_questionnaire_responses(questionnaire, program)
    CSV.generate(headers: true) do |csv|
      questions = questionnaire.questions.order(:position)

      # Build header row
      headers = [ "Student Email" ]
      questions.each do |question|
        headers << "Q#{question.position}: #{question.text}"
      end
      csv << headers

      # Get all students and their answers
      students = program.students.order(:email_address)
      question_ids = questions.pluck(:id)
      all_answers = Answer.where(program: program, question_id: question_ids)
                          .includes(:student, :question)
                          .index_by { |a| [ a.user_id, a.question_id ] }

      # Generate row for each student
      students.each do |student|
        row = [ student.email_address ]

        questions.each do |question|
          answer = all_answers[[ student.id, question.id ]]

          if answer
            content = answer.content
            display_value = case question.question_type
            when "checkbox"
              # Extract plain text and parse checkbox values
              content_string = if content.respond_to?(:to_plain_text)
                                content.to_plain_text
              else
                                content.to_s
              end
              if content_string.start_with?("[") && content_string.end_with?("]")
                begin
                  parsed = JSON.parse(content_string)
                  parsed.is_a?(Array) ? parsed.join("; ") : content_string
                rescue JSON::ParserError
                  content_string.split(",").map(&:strip).join("; ")
                end
              else
                content_string.split(",").map(&:strip).join("; ")
              end
            when "rich_text"
              content.respond_to?(:to_plain_text) ? content.to_plain_text : content.to_s
            else
              # radio, text, datetime, link
              content.respond_to?(:to_plain_text) ? content.to_plain_text : content.to_s
            end
            row << display_value
          else
            row << "Not answered"
          end
        end

        csv << row
      end
    end
  end
end
