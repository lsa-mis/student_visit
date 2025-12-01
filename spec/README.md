# Test Suite Improvements

This document outlines the improvements made to the RSpec test suite.

## Improvements Made

### 1. RSpec Configuration Enhancements

- **Enabled focus filtering**: Use `fit`, `fdescribe`, `fcontext` to run specific tests
- **Enabled example status persistence**: Track failures between runs with `--only-failures`
- **Enabled spec type inference**: Automatically detect spec types from file location
- **Enabled profiling**: Identify slow tests (top 10)
- **Enabled random ordering**: Surface order dependencies
- **Enabled documentation formatter**: Better output for single file runs

### 2. Authentication Helpers Improvements

- **Unique email generation**: Prevents conflicts when running tests in parallel
- **Enhanced student helper**: Added `enrolled_in` parameter for easier test setup
- **Better factory-like methods**: More flexible and reusable helpers

### 3. Shared Examples

Created `spec/support/shared_examples/authentication_examples.rb` with reusable patterns:

- `requires authentication`: Tests unauthenticated access
- `requires super admin`: Tests super admin-only endpoints
- `requires department admin or super admin`: Tests admin endpoints
- `requires student`: Tests student-only endpoints

**Usage Example:**

```ruby
describe "GET /departments" do
  include_examples "requires department admin or super admin", :departments_path
end
```

### 4. New Test Coverage

#### Student Dashboard

- Added comprehensive request specs for `Student::DashboardController`
- Tests department selection logic
- Tests single vs multiple department scenarios
- Tests active program display
- Added policy spec for `Student::DashboardPolicy`

### 5. Test Organization

- Better separation of concerns
- Consistent naming conventions
- Improved test readability
- Better use of `let` and `before` blocks

## Recent Improvements (Completed)

### 1. FactoryBot Added ✅

FactoryBot has been added for better test data management:

- Added `factory_bot_rails` gem to Gemfile
- Configured FactoryBot in `rails_helper.rb`
- Created factories for all main models:
  - `User` (with role traits)
  - `Department` (with active_program trait)
  - `Program` (with various states)
  - `StudentProgram`
  - `VIP`
  - `Appointment` (with available/booked/upcoming/past traits)
  - `Questionnaire` (with questions trait)
  - `Question` (with various question types)
  - `Answer`
  - `CalendarEvent` (with mandatory/upcoming/past traits)
  - `Role`

**Usage:**

```ruby
# Create a user with student role
user = create(:user, :with_student_role)

# Create a department with active program
department = create(:department, :with_active_program)

# Create an available appointment
appointment = create(:appointment, :available, :upcoming)
```

### 2. Student Controller Tests Added ✅

Comprehensive request specs have been added for:

- `Student::AppointmentsController` - Full CRUD operations, filtering, VIP selection
- `Student::CalendarController` - All filter modes (all, date single, date multi)
- `Student::MapController` - Basic access and authorization
- `Student::QuestionnairesController` - View, edit, update with deadline validation

### 3. Policy Specs Added ✅

Complete policy specs have been added for:

- `Student::AppointmentPolicy` - index?, create?, destroy?
- `Student::CalendarPolicy` - show?
- `Student::MapPolicy` - show?
- `Student::QuestionnairePolicy` - index?, show?, edit?, update?

All policy specs test access control for students, admins, and unauthenticated users.

### 4. SimpleCov Coverage Reporting Enabled ✅

SimpleCov has been configured for test coverage reporting:

- Coverage reports generated in `/coverage/` directory
- Minimum coverage threshold set to 80%
- Coverage grouped by Models, Controllers, Policies, Services, Mailers, Jobs
- Run tests with coverage: `COVERAGE=true bundle exec rspec`

### 5. System Specs Added ✅

System specs have been added for critical user flows:

- Student dashboard flow (login, department selection, navigation)
- Student appointment flow (viewing, selecting, canceling, filtering)
- Student questionnaire flow (viewing, editing, saving, deadline validation)

### 6. Admin Navigation Coverage ✅

- Added `spec/system/admin_management_flow_spec.rb` to exercise the end-to-end workflow super admins rely on when managing departments, programs, questionnaires, calendar events, appointments, students, and VIPs.
- This spec signs in as a super admin, seeds representative data via FactoryBot, and asserts that each management surface renders successfully and links together as expected.
- Removed the legacy helper and Tailwind view specs (they only contained `pending` examples) so that the suite now reports **zero** pending tests—the new high-level system spec covers the critical rendering paths those placeholders were meant to represent.

## Recommendations for Further Improvements

### 4. Improve View Specs

Current view specs are very basic. Consider:

- Testing conditional rendering
- Testing form submissions
- Testing error messages
- Testing success messages

### 5. Add More System Specs

Additional system specs could be added for:

- Calendar view interactions (date selection, filter switching)
- Map view interactions
- Multi-step workflows (appointment selection → confirmation)
- Error handling flows

### 7. Use Database Cleaner Strategy

Consider using `database_cleaner` or `database_cleaner-active_record` for more control over test database state, especially for system tests.

### 8. Add Request Spec Helpers

Create helpers for common request patterns:

- Testing JSON responses
- Testing file uploads
- Testing pagination
- Testing filtering

## Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific file
bundle exec rspec spec/models/user_spec.rb

# Run with focus (only focused tests)
bundle exec rspec --tag focus

# Run only failures from last run
bundle exec rspec --only-failures

# Run with documentation format
bundle exec rspec --format documentation

# Run specific line
bundle exec rspec spec/models/user_spec.rb:10

# Run with coverage reporting
COVERAGE=true bundle exec rspec

# View coverage report
open coverage/index.html
```

## Test Structure

```bash
spec/
├── controllers/          # Controller specs (legacy, prefer request specs)
├── factories/            # FactoryBot factories
├── mailers/              # Mailer specs
├── models/               # Model specs
├── policies/             # Policy specs (includes student namespace)
├── requests/             # Request specs (preferred for controllers)
│   └── student/          # Student namespace request specs
├── services/             # Service specs
├── support/              # Test support files
│   ├── authentication_helpers.rb
│   └── shared_examples/  # Shared examples
└── system/               # System/integration specs
    ├── admin_management_flow_spec.rb
    ├── student_appointment_flow_spec.rb
    ├── student_dashboard_flow_spec.rb
    └── student_questionnaire_flow_spec.rb
```

## Best Practices

1. **Use request specs** instead of controller specs for testing controllers
2. **Use shared examples** for common authentication/authorization patterns
3. **Use `let`** for lazy-loaded test data
4. **Use `before`** for setup that applies to multiple examples
5. **Keep tests focused** - one assertion per test when possible
6. **Use descriptive test names** - they serve as documentation
7. **Test edge cases** - nil values, empty collections, invalid input
8. **Use factories** instead of direct model creation - FactoryBot is now available
9. **Keep tests fast** - avoid unnecessary database queries
10. **Use `build` vs `create`** - use `build` when persistence isn't needed
