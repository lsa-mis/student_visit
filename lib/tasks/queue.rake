namespace :db do
  namespace :queue do
    desc "Load the queue database schema"
    task :schema_load do
      # Use SolidQueue connection directly since it's already configured for the queue database
      unless SolidQueue::Job.connection.table_exists?("solid_queue_jobs")
        puts "Loading queue schema..."
        # Switch to queue database connection to load schema
        ActiveRecord::Base.connected_to(role: :writing, shard: :queue) do
          load Rails.root.join("db/queue_schema.rb")
        end
        puts "Queue schema loaded successfully."
      else
        puts "Queue schema already exists. Skipping."
      end
    end

    desc "Check if queue tables exist"
    task :check do
      if SolidQueue::Job.connection.table_exists?("solid_queue_jobs")
        puts "✓ Queue tables exist"
      else
        puts "✗ Queue tables do not exist. Run 'rails db:queue:schema_load' to create them."
        exit 1
      end
    end

    desc "Show queue status and pending jobs"
    task :status do
      # SolidQueue models are already connected to the queue database
      total = SolidQueue::Job.count
      pending = SolidQueue::Job.where(finished_at: nil).where("scheduled_at <= ?", Time.current).count
      scheduled = SolidQueue::Job.where(finished_at: nil).where("scheduled_at > ?", Time.current).count
      finished = SolidQueue::Job.where.not(finished_at: nil).count
      failed = SolidQueue::FailedExecution.count

      puts "SolidQueue Status:"
      puts "  Total jobs: #{total}"
      puts "  Pending (ready to process): #{pending}"
      puts "  Scheduled (future): #{scheduled}"
      puts "  Finished: #{finished}"
      puts "  Failed: #{failed}"

      if pending > 0
        puts "\nPending jobs:"
        SolidQueue::Job.where(finished_at: nil).where("scheduled_at <= ?", Time.current).limit(10).each do |job|
          puts "  - ID: #{job.id}, Class: #{job.class_name}, Queue: #{job.queue_name}, Created: #{job.created_at}"
        end
      end

      if failed > 0
        puts "\nFailed jobs:"
        SolidQueue::FailedExecution.limit(10).each do |failed_job|
          job = failed_job.job
          puts "  - Job ID: #{job.id}, Class: #{job.class_name}, Error: #{failed_job.error&.lines&.first}"
        end
      end

      # Check if SolidQueue processes are running
      processes = SolidQueue::Process.count
      puts "\nSolidQueue Processes: #{processes}"
      if processes > 0
        SolidQueue::Process.all.each do |process|
          puts "  - #{process.name} (PID: #{process.pid}, Last heartbeat: #{process.last_heartbeat_at})"
        end
      else
        puts "  ⚠️  No SolidQueue processes found! Jobs won't be processed."
        puts "     Make sure SOLID_QUEUE_IN_PUMA=true is set and Puma was restarted."
      end
    end
  end
end

# Hook into db:prepare to automatically load queue schema
Rake::Task["db:prepare"].enhance do
  begin
    Rake::Task["db:queue:schema_load"].invoke
  rescue StandardError => e
    puts "Warning: Could not load queue schema: #{e.message}"
    puts "You may need to run 'rails db:queue:schema_load' manually."
  end
end
