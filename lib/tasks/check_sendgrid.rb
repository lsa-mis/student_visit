#!/usr/bin/env ruby
# Check if SendGrid API key is configured
# Usage: RAILS_ENV=production bin/rails runner lib/tasks/check_sendgrid.rb

api_key = Rails.application.credentials.dig(:sendgrid, :api_key)

if api_key.present?
  puts "✓ SendGrid API key is set"
  puts "  Key length: #{api_key.length} characters"
  puts "  Key starts with: #{api_key[0..10]}..."
else
  puts "✗ SendGrid API key is missing!"
  puts "  You need to set it in Rails credentials:"
  puts "  EDITOR=vim bin/rails credentials:edit"
  puts "  Then add: sendgrid:"
  puts "    api_key: YOUR_SENDGRID_API_KEY"
end
