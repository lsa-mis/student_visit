#!/usr/bin/env ruby
# Quick script to check SolidQueue status
# Usage: RAILS_ENV=production bin/rails runner lib/tasks/queue_status.rb

total = SolidQueue::Job.count
pending = SolidQueue::Job.where(finished_at: nil).where("scheduled_at <= ?", Time.current).count
failed = SolidQueue::FailedExecution.count
processes = SolidQueue::Process.count

puts "Total jobs: #{total}"
puts "Pending jobs: #{pending}"
puts "Failed jobs: #{failed}"
puts "SolidQueue processes running: #{processes}"

if processes == 0
  puts "\n⚠️  WARNING: No SolidQueue processes found!\n"
  puts "This means jobs won't be processed.\n"
  puts "SOLID_QUEUE_IN_PUMA should be set to 'true' and Puma needs to be restarted."
end

if pending > 0
  puts "\nOldest pending job:"
  job = SolidQueue::Job.where(finished_at: nil).where("scheduled_at <= ?", Time.current).order(:created_at).first
  puts "  ID: #{job.id}, Class: #{job.class_name}, Created: #{job.created_at}"
end

if failed > 0
  puts "\nMost recent failed job:"
  failed_job = SolidQueue::FailedExecution.order(:created_at).last
  job = failed_job.job
  puts "  Job ID: #{job.id}"
  puts "  Error: #{failed_job.error&.lines&.first}"
end
