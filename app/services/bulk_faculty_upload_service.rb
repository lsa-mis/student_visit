require "csv"
require "roo"

class BulkFacultyUploadService
  attr_reader :department, :file, :errors, :success_count, :failure_count

  def initialize(department, file)
    @department = department
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
    # Expected format: name, profile_url, title, ranking
    name = row_data[0]&.to_s&.strip
    return if name.blank?

    profile_url = row_data[1]&.to_s&.strip
    title = row_data[2]&.to_s&.strip
    ranking = row_data[3]&.to_i || 0

    vip = Vip.find_or_initialize_by(department: department, name: name)
    vip.profile_url = profile_url if profile_url.present?
    vip.title = title if title.present?
    vip.ranking = ranking

    if vip.save
      @success_count += 1
    else
      @failure_count += 1
      errors << "Row #{row_data}: #{vip.errors.full_messages.join(', ')}"
    end
  end
end
