# SimpleCov configuration
# This file provides default settings for SimpleCov

SimpleCov.configure do
  # Track coverage for Rails application code
  track_files '{app,lib}/**/*.rb'

  # Exclude files that don't need coverage
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/db/'
  add_filter '/vendor/'
  add_filter '/tmp/'

  # Track coverage for different groups
  add_group 'Controllers', 'app/controllers'
  add_group 'Models', 'app/models'
  add_group 'Helpers', 'app/helpers'
  add_group 'Jobs', 'app/jobs'
  add_group 'Mailers', 'app/mailers'
  add_group 'Views', 'app/views'

  # Output format - HTML for detailed reports, SimpleFormatter for console output
  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::SimpleFormatter
  ])

  # Merge results from multiple test runs (useful for parallel tests)
  merge_timeout 3600

  # Minimum coverage threshold (adjust as needed - start lower and increase over time)
  # Set to 0 initially, increase as you add more tests
  # minimum_coverage 80
end
