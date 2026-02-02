# Student Visit Application

![Ruby Version](https://img.shields.io/badge/ruby-3.3.4-red.svg)
![Rails Version](https://img.shields.io/badge/rails-8.1.1-red.svg)
![PostgreSQL](https://img.shields.io/badge/postgresql-supported-blue.svg)

A comprehensive web application for managing student visits, appointments, and questionnaires across departments and programs. The application facilitates communication between students, department administrators, and faculty members, enabling efficient scheduling, questionnaire management, and calendar coordination.

## Features

- **Student Dashboard**: Students can view their appointments, complete questionnaires, and browse available programs
- **Appointment Management**: Schedule and manage student appointments with faculty members
- **Questionnaire System**: Create and manage questionnaires with customizable questions and response collection
- **Calendar Integration**: View and manage calendar events for programs and departments
- **Department & Program Management**: Organize resources by departments and programs
- **Bulk Upload**: Import students, appointments, calendar events, and VIPs via CSV
- **Role-Based Access Control**: Support for super admins, department admins, and students
- **Reporting**: Generate reports for students, appointments, and calendar events

## Technology Stack

- **Ruby**: 3.3.4
- **Rails**: 8.1.1
- **Database**: PostgreSQL (staging/production), SQLite3 (development/test)
- **Frontend**: Tailwind CSS, Stimulus.js, Turbo
- **Authentication**: Custom session-based authentication
- **Authorization**: Pundit policies
- **Background Jobs**: Solid Queue
- **Cache**: Solid Cache
- **Storage**: Active Storage with Google Cloud Storage support

## Requirements

### System Dependencies

- Ruby 3.3.4
- PostgreSQL (for staging/production environments)
- Node.js and npm/yarn (for asset compilation)
- ImageMagick (for image processing)

### Server Requirements

- Minimum 2GB RAM
- At least 10GB free disk space
- Ubuntu 20.04+ or similar Linux distribution recommended
- Deployment: Hatchbox on DigitalOcean (Docker/Kamal config present but unused)

## Server Setup

### 1. System Preparation

```bash
# Update system packages
sudo apt-get update && sudo apt-get upgrade -y

# Install essential dependencies
sudo apt-get install -y build-essential curl git libpq-dev libssl-dev \
  libreadline-dev zlib1g-dev libncurses5-dev libffi-dev libgdbm-dev \
  libyaml-dev libxml2-dev libxslt1-dev libcurl4-openssl-dev \
  software-properties-common imagemagick
```

### 2. Install Ruby

```bash
# Install rbenv (Ruby version manager)
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash

# Add rbenv to PATH
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc

# Install Ruby 3.3.4
rbenv install 3.3.4
rbenv global 3.3.4

# Verify installation
ruby -v
```

### 3. Install PostgreSQL

```bash
# Install PostgreSQL
sudo apt-get install -y postgresql postgresql-contrib

# Start PostgreSQL service
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create database user
sudo -u postgres createuser -s -P student_visit_user
# Enter a secure password when prompted

# Create database
sudo -u postgres createdb -O student_visit_user student_visit_production
```

### 4. Install Node.js

```bash
# Install Node.js (using NodeSource repository)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify installation
node -v
npm -v
```

### 5. Application Deployment

#### Clone the Repository

```bash
# Navigate to deployment directory
cd /var/www

# Clone the repository
sudo git clone <https://github.com/lsa-mis/student_visit> student_visit
sudo chown -R $USER:$USER student_visit
cd student_visit
```

#### Install Dependencies

```bash
# Install Bundler if not already installed
gem install bundler

# Install Ruby gems
bundle install --without development test

# Install JavaScript dependencies (if applicable)
npm install
```

#### Configure Environment Variables

```bash
# Copy environment template (create this if needed)
cp .env.example .env.production

# Edit production environment file
nano .env.production
```

Set the following required environment variables:

```bash
DATABASE_URL=postgresql://student_visit_user:password@localhost/student_visit_production
RAILS_ENV=production
RAILS_MASTER_KEY=<your-master-key>
SECRET_KEY_BASE=<generate-with-rails-secret>
```

Generate secrets:

```bash
# Generate SECRET_KEY_BASE
bin/rails secret

# RAILS_MASTER_KEY is in config/master.key or config/credentials.yml.enc
```

#### Database Setup

```bash
# Create and migrate database
RAILS_ENV=production bin/rails db:create
RAILS_ENV=production bin/rails db:migrate

# Seed database (if applicable)
RAILS_ENV=production bin/rails db:seed
```

#### Precompile Assets

```bash
# Precompile assets for production
RAILS_ENV=production bin/rails assets:precompile
```

#### Setup Puma as Service

Create a systemd service file:

```bash
sudo nano /etc/systemd/system/student_visit.service
```

Add the following configuration:

```ini
[Unit]
Description=Student Visit Puma Application Server
After=network.target

[Service]
Type=simple
User=your_username
WorkingDirectory=/var/www/student_visit
Environment="RAILS_ENV=production"
Environment="PORT=3000"
ExecStart=/home/your_username/.rbenv/shims/bundle exec puma -C config/puma.rb
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable student_visit
sudo systemctl start student_visit
sudo systemctl status student_visit
```

#### Setup Nginx as Reverse Proxy

Install Nginx:

```bash
sudo apt-get install -y nginx
```

Create Nginx configuration:

```bash
sudo nano /etc/nginx/sites-available/student_visit
```

Add the following configuration:

```nginx
upstream student_visit {
  server localhost:3000;
}

server {
  listen 80;
  server_name your-domain.com;

  client_max_body_size 50M;

  root /var/www/student_visit/public;

  try_files $uri/index.html $uri @app;

  location @app {
    proxy_pass http://student_visit;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_redirect off;
    proxy_set_header X-Forwarded-Proto $scheme;
  }

  location ~* ^/assets/ {
    expires 1y;
    add_header Cache-Control public;
  }

  error_page 500 502 503 504 /500.html;
  location = /500.html {
    root /var/www/student_visit/public;
  }
}
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/student_visit /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### 6. SSL Certificate (Let's Encrypt)

```bash
# Install Certbot
sudo apt-get install -y certbot python3-certbot-nginx

# Obtain SSL certificate
sudo certbot --nginx -d your-domain.com

# Certbot will automatically configure Nginx and set up auto-renewal
```

## Development Setup

### Prerequisites

- Ruby 3.3.4
- SQLite3 (for development)
- Node.js 20+

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/lsa-mis/student_visit
   cd student_visit
   ```

2. **Setup database**
   ```bash
   bin/rails db:create
   bin/rails db:migrate
   bin/rails db:seed
   ```

3. **Start the development server**
   ```bash
   bin/dev
   ```

   The application will be available at `http://localhost:3000`

## Testing

The application uses RSpec for testing. Run the test suite with:

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/user_spec.rb

# Run with coverage
COVERAGE=true bundle exec rspec
```

## Code Quality and Linting

This project uses RuboCop with the Rails Omakase style guide to maintain code quality and consistency.

### Running Linters Locally

```bash
# Run RuboCop with autocorrect
bin/rails lint

# Run RuboCop with safe autocorrect (more aggressive)
bin/rails lint:safe

# Generate a new .rubocop_todo.yml file
bin/rails lint:todo

# Show offense statistics
bin/rails lint:offenses
```

### Fixing Common Linting Issues

```bash
# Fix string quotes issues (Style/StringLiterals)
bin/rails lint:fix_quotes

# Fix empty lines issues (Layout/EmptyLinesAroundBlockBody)
bin/rails lint:fix_empty_lines

# Fix trailing whitespace issues (Layout/TrailingWhitespace)
bin/rails lint:fix_whitespace

# Fix trailing empty lines issues (Layout/TrailingEmptyLines)
bin/rails lint:fix_newlines

# Fix all common formatting issues at once
bin/rails lint:fix_formatting
```

### Pre-commit Hook

This project includes a pre-commit hook that automatically fixes common linting issues before committing. To enable it:

```bash
mkdir -p .git/hooks && chmod +x .githooks/pre-commit && ln -sf ../../.githooks/pre-commit .git/hooks/pre-commit
```

### Continuous Integration

The project is set up with GitHub Actions to automatically run linters on pull requests. The CI pipeline checks for:

1. Security vulnerabilities using Brakeman
2. JavaScript dependency vulnerabilities
3. Code style using RuboCop
4. Test suite using RSpec

Make sure all checks pass before merging your pull requests.

## Deployment with Kamal

This application can be deployed using [Kamal](https://kamal-deploy.org/). Configuration is in `config/deploy.yml`.

```bash
# Setup secrets
kamal setup

# Deploy to production
kamal deploy

# Access Rails console
kamal app exec -i "bin/rails console"

# View logs
kamal app logs -f
```

## Background Jobs

The application uses Solid Queue for background job processing. Jobs run in the same Puma process by default. To scale out job processing, configure a dedicated job server in `config/deploy.yml`.

## Storage

Active Storage is configured to use Google Cloud Storage in production. Configure credentials in `config/storage.yml` and set the appropriate environment variables.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

[MIT License](LICENSE)

## Support

For issues and questions, please contact the developers on GitHub.
