require "csv"
require "roo"

class BulkCalendarEventUploadService
  attr_reader :program, :file, :errors, :success_count, :failure_count

  def initialize(program, file)
    @program = program
    @file = file
    @errors = []
    @success_count = 0
    @failure_count = 0
  end

  def call
    return false unless valid_file?

    spreadsheet = open_spreadsheet
    return false if spreadsheet.nil?

    process_rows(spreadsheet)
    success_count > 0
  end

  private

  def valid_file?
    if file.nil?
      errors << "No file provided"
      return false
    end

    unless %w[.csv .xlsx .xls].include?(File.extname(file.original_filename).downcase)
      errors << "Invalid file type. Please upload a CSV or Excel file."
      return false
    end

    true
  end

  def open_spreadsheet
    case File.extname(file.original_filename).downcase
    when ".csv"
      Roo::CSV.new(file.path)
    when ".xlsx"
      Roo::Excelx.new(file.path)
    when ".xls"
      Roo::Excel.new(file.path)
    else
      errors << "Unknown file type: #{file.original_filename}"
      nil
    end
  rescue => e
    errors << "Error reading file: #{e.message}"
    nil
  end

  def process_rows(spreadsheet)
    ActiveRecord::Base.transaction do
      (2..spreadsheet.last_row).each do |row_num|
        process_row(spreadsheet.row(row_num), row_num)
      end
    end
  rescue => e
    errors << "Error processing file: #{e.message}"
    raise ActiveRecord::Rollback
  end

  def process_row(row_data, row_num)
    # Expected format: title, start_time, end_time, description, location, notes, mandatory
    title = row_data[0]&.to_s&.strip
    start_time_str = row_data[1]&.to_s&.strip
    end_time_str = row_data[2]&.to_s&.strip
    description = row_data[3]&.to_s&.strip
    location = row_data[4]&.to_s&.strip
    notes = row_data[5]&.to_s&.strip
    mandatory_str = row_data[6]&.to_s&.strip

    return if title.blank? || start_time_str.blank? || end_time_str.blank?

    begin
      start_time = parse_datetime(start_time_str)
      end_time = parse_datetime(end_time_str)

      unless start_time && end_time
        @failure_count += 1
        errors << "Row #{row_num}: Invalid date format for start_time or end_time"
        return
      end

      mandatory = parse_boolean(mandatory_str)

      calendar_event = CalendarEvent.new(
        program: program,
        title: title,
        start_time: start_time,
        end_time: end_time,
        mandatory: mandatory
      )

      calendar_event.description = description if description.present?
      calendar_event.location = location if location.present?
      calendar_event.notes = notes if notes.present?

      if calendar_event.save
        @success_count += 1
      else
        @failure_count += 1
        errors << "Row #{row_num}: #{calendar_event.errors.full_messages.join(', ')}"
      end
    rescue => e
      @failure_count += 1
      errors << "Row #{row_num}: #{e.message}"
    end
  end

  def parse_datetime(datetime_str)
    # Try multiple formats
    [
      ->(s) { DateTime.parse(s) },
      ->(s) { Time.zone.parse(s) },
      ->(s) { DateTime.strptime(s, "%m/%d/%Y %H:%M") },
      ->(s) { DateTime.strptime(s, "%Y-%m-%d %H:%M") },
      ->(s) { DateTime.strptime(s, "%m/%d/%Y %I:%M %p") }
    ].each do |parser|
      begin
        return parser.call(datetime_str)
      rescue
        next
      end
    end
    nil
  end

  def parse_boolean(value)
    return false if value.blank?
    %w[true 1 yes y].include?(value.to_s.downcase)
  end
end
