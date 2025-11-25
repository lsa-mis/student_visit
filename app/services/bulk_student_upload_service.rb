require "csv"
require "roo"

class BulkStudentUploadService
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
      (2..spreadsheet.last_row).each do |row|
        process_row(spreadsheet.row(row))
      end
    end
  rescue => e
    errors << "Error processing file: #{e.message}"
    raise ActiveRecord::Rollback
  end

  def process_row(row_data)
    email = row_data[0]&.to_s&.strip&.downcase
    return nil if email.blank?

    user = User.find_or_initialize_by(email_address: email)
    was_new_record = user.new_record?

    # Update user fields from the row data
    user.last_name = row_data[1]&.to_s&.strip if row_data[1].present?
    user.first_name = row_data[2]&.to_s&.strip if row_data[2].present?
    user.umid = format_umid(row_data[3]) if row_data[3].present?

    if was_new_record
      # Set initial password to UMID - user will be required to change it on first login
      umid_value = format_umid(row_data[3])
      user.password = umid_value.present? ? umid_value : SecureRandom.hex(16)
      user.must_change_password = true
      unless user.save
        @failure_count += 1
        errors << "Row #{row_data}: #{user.errors.full_messages.join(', ')}"
        return nil
      end
      # Add student role if not present
      user.add_role("student") unless user.student?
    else
      # Update existing user if fields have changed
      unless user.save
        @failure_count += 1
        errors << "Row #{row_data}: Failed to update user - #{user.errors.full_messages.join(', ')}"
        return nil
      end
    end

    # Enroll in program
    student_program = StudentProgram.find_or_initialize_by(user: user, program: program)
    if student_program.new_record?
      if student_program.save
        @success_count += 1
      else
        @failure_count += 1
        errors << "Row #{row_data}: Failed to enroll student - #{student_program.errors.full_messages.join(', ')}"
      end
    else
      @success_count += 1 # Already enrolled, count as success
    end

    # Return user if it was newly created
    was_new_record ? user : nil
  end

  def format_umid(value)
    return nil if value.nil?

    # Convert to string and remove any whitespace
    umid_str = value.to_s.strip

    # If it's a numeric value (integer or float), format it as an 8-digit string with leading zeros
    if umid_str.match?(/^\d+(\.0+)?$/)
      # Remove decimal point and trailing zeros if present (e.g., "1234567.0" -> "1234567")
      umid_str = umid_str.split(".").first
      # Pad with leading zeros to ensure 8 digits
      umid_str.rjust(8, "0")
    else
      # Already a string, use as-is
      umid_str
    end
  end
end
