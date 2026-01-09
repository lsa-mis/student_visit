source "https://rubygems.org"

gem "bcrypt", "~> 3.1"
gem "bootsnap", require: false
gem "google-cloud-storage"
gem "image_processing", "~> 1.2"
gem "importmap-rails"
gem "jbuilder"
gem "kamal", require: false
gem 'lsa_tdx_feedback', '~> 1.0', '>= 1.0.3'
gem "propshaft"
gem "puma", ">= 5.0"
gem "pundit"
gem "rails", "~> 8.1.2"
gem "roo"
gem "sentry-ruby"
gem "sentry-rails"
gem "solid_cable"
gem "solid_cache"
gem "solid_queue"
gem "stimulus-rails"
gem "tailwindcss-rails", "~> 4.4.0"
gem "thruster", require: false
gem "turbo-rails"
gem "tzinfo-data", platforms: %i[ windows jruby ]

group :development, :test do
  gem "factory_bot_rails"
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rspec-rails"
  gem "shoulda-matchers", "~> 7.0"
  gem "sqlite3", ">= 2.1"
end

group :development do
  gem "web-console"
end

group :development, :staging do
  gem "letter_opener_web", "~> 3.0"
end

group :staging, :production do
  gem "pg"
end

group :test do
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'simplecov', require: false
end
