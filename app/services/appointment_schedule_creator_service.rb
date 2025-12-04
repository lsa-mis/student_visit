class AppointmentScheduleCreatorService
  attr_reader :program, :vip, :schedule_blocks, :errors, :created_count

  # schedule_blocks format:
  # [
  #   { date: "2025-03-23", blocks: [
  #       { start_time: "09:00", end_time: "12:00", type: "range" },
  #       { start_time: "15:00", end_time: "16:30", type: "range" }
  #   ]},
  #   { date: "2025-03-24", blocks: [
  #       { start_time: "11:00", type: "single" },
  #       { start_time: "15:30", type: "single" }
  #   ]}
  # ]

  def initialize(program, vip, schedule_blocks)
    @program = program
    @vip = vip
    @schedule_blocks = schedule_blocks
    @errors = []
    @created_count = 0
  end

  def call
    return false unless valid?

    generate_appointments
    created_count > 0
  end

  private

  def valid?
    errors.clear

    if program.default_appointment_length.nil? || program.default_appointment_length <= 0
      errors << "Program must have a valid default appointment length"
      return false
    end

    if schedule_blocks.blank? || !schedule_blocks.is_a?(Array)
      errors << "Schedule blocks must be provided as an array"
      return false
    end

    schedule_blocks.each do |day_schedule|
      date_str = day_schedule[:date] || day_schedule["date"]
      date = parse_date(date_str)

      if date.nil?
        errors << "Invalid date: #{date_str}"
        next
      end

      # Optional: validate date is in held_on_dates
      if program.held_on_dates.present? && program.held_on_dates.is_a?(Array) && !program.held_on_dates.empty?
        unless program.held_on_date?(date)
          errors << "Date #{date.strftime('%B %d, %Y')} is not in program's held-on dates"
        end
      end

      blocks = day_schedule[:blocks] || day_schedule["blocks"] || []
      blocks.each do |block|
        validate_block(block, date)
      end
    end

    errors.empty?
  end

  def validate_block(block, date)
    start_time_str = block[:start_time] || block["start_time"]
    start_time = parse_time(start_time_str, date)

    if start_time.nil?
      errors << "Invalid start time: #{start_time_str} on #{date.strftime('%B %d, %Y')}"
      return
    end

    block_type = block[:type] || block["type"] || "single"

    if block_type == "range"
      end_time_str = block[:end_time] || block["end_time"]
      end_time = parse_time(end_time_str, date)

      if end_time.nil?
        errors << "Invalid end time: #{end_time_str} on #{date.strftime('%B %d, %Y')}"
        return
      end

      if end_time <= start_time
        errors << "End time must be after start time for block on #{date.strftime('%B %d, %Y')}"
      end
    end
  end

  def generate_appointments
    slot_length = program.default_appointment_length.minutes

    ActiveRecord::Base.transaction do
      schedule_blocks.each do |day_schedule|
        date_str = day_schedule[:date] || day_schedule["date"]
        date = parse_date(date_str)
        next if date.nil?

        blocks = day_schedule[:blocks] || day_schedule["blocks"] || []
        blocks.each do |block|
          start_time_str = block[:start_time] || block["start_time"]
          start_time = parse_time(start_time_str, date)
          next if start_time.nil?

          block_type = block[:type] || block["type"] || "single"

          if block_type == "single"
            # Single appointment
            create_appointment(start_time, start_time + slot_length)
          elsif block_type == "range"
            # Range: generate slots from start to end
            end_time_str = block[:end_time] || block["end_time"]
            end_time = parse_time(end_time_str, date)
            next if end_time.nil?

            current_time = start_time

            while current_time + slot_length <= end_time
              create_appointment(current_time, current_time + slot_length)
              current_time += slot_length
            end
          end
        end
      end
    end
  rescue => e
    errors << "Error generating appointments: #{e.message}"
    raise ActiveRecord::Rollback
  end

  def create_appointment(start_time, end_time)
    appointment = Appointment.new(
      program: program,
      vip: vip,
      start_time: start_time,
      end_time: end_time
    )

    if appointment.save
      @created_count += 1
    else
      errors << "Failed to create appointment at #{start_time.strftime('%B %d, %Y at %I:%M %p')}: #{appointment.errors.full_messages.join(', ')}"
    end
  end

  def parse_date(date_str)
    return nil if date_str.blank?

    Date.parse(date_str.to_s)
  rescue
    nil
  end

  def parse_time(time_str, date)
    return nil if time_str.blank?

    # Parse "HH:MM" or "HH:MM AM/PM" format
    time_parts = time_str.to_s.strip.upcase

    # Handle 12-hour format
    if time_parts.include?("AM") || time_parts.include?("PM")
      # Extract AM/PM marker and normalize spacing to avoid ReDoS vulnerability
      # Use string methods instead of regex to prevent catastrophic backtracking
      am_pm = time_parts.include?("AM") ? "AM" : "PM"
      # Split on AM/PM, take first part, then strip whitespace
      time_without_am_pm = time_parts.split(am_pm, 2).first.strip
      time_str_clean = "#{time_without_am_pm} #{am_pm}"
      Time.zone.parse("#{date} #{time_str_clean}")
    else
      # 24-hour format (HH:MM)
      Time.zone.parse("#{date} #{time_parts}")
    end
  rescue
    nil
  end
end
