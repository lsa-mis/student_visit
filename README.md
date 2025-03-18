# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

## Code Quality and Linting

This project uses RuboCop with the Rails Omakase style guide to maintain code quality and consistency.

### Running Linters Locally

You can run the linters locally using the following commands:

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

The project has specific tasks to fix common linting issues:

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

This project includes a pre-commit hook that automatically fixes common linting issues before committing. To enable it, run:

```bash
mkdir -p .git/hooks && chmod +x .githooks/pre-commit && ln -sf ../../.githooks/pre-commit .git/hooks/pre-commit
```

The pre-commit hook will automatically fix the following issues in staged Ruby files:

* String quotes (Style/StringLiterals)
* Empty lines around block bodies (Layout/EmptyLinesAroundBlockBody)
* Trailing whitespace (Layout/TrailingWhitespace)
* Trailing empty lines (Layout/TrailingEmptyLines)

### Style Conventions

This project follows these style conventions:

1. **String Quotes**: Use double quotes (`"`) for strings unless you need single quotes to avoid extra backslashes for escaping.
2. **Block Bodies**: No extra empty lines at the beginning or end of block bodies.
3. **Whitespace**: No trailing whitespace at the end of lines.
4. **File Endings**: All files should end with a newline.

### Continuous Integration

The project is set up with GitHub Actions to automatically run linters on pull requests.
The CI pipeline will check for:

1. Security vulnerabilities using Brakeman
2. JavaScript dependency vulnerabilities
3. Code style using RuboCop
4. Test suite using RSpec

Make sure all checks pass before merging your pull requests.

* ...
