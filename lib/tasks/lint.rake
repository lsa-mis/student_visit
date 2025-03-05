namespace :lint do
  desc "Run RuboCop with autocorrect and Rails cops"
  task :rubocop do
    sh "bundle exec rubocop -a"
  end

  desc "Run RuboCop with safe autocorrect and Rails cops"
  task :safe do
    sh "bundle exec rubocop -A"
  end

  desc "Run RuboCop with autocorrect and generate a todo file"
  task :todo do
    sh "bundle exec rubocop --auto-gen-config"
  end

  desc "Run RuboCop with autocorrect and only show offenses"
  task :offenses do
    sh "bundle exec rubocop --format offenses"
  end

  desc "Fix string quotes issues (Style/StringLiterals)"
  task :fix_quotes do
    sh "bundle exec rubocop --only Style/StringLiterals -a"
  end

  desc "Fix empty lines issues (Layout/EmptyLinesAroundBlockBody)"
  task :fix_empty_lines do
    sh "bundle exec rubocop --only Layout/EmptyLinesAroundBlockBody -a"
  end

  desc "Fix trailing whitespace issues (Layout/TrailingWhitespace)"
  task :fix_whitespace do
    sh "bundle exec rubocop --only Layout/TrailingWhitespace -a"
  end

  desc "Fix trailing empty lines issues (Layout/TrailingEmptyLines)"
  task :fix_newlines do
    sh "bundle exec rubocop --only Layout/TrailingEmptyLines -a"
  end

  desc "Fix all common formatting issues (quotes, whitespace, newlines)"
  task :fix_formatting do
    sh "bundle exec rubocop --only Style/StringLiterals,Layout/EmptyLinesAroundBlockBody,Layout/TrailingWhitespace,Layout/TrailingEmptyLines -a"
  end
end

desc "Run RuboCop with autocorrect"
task lint: "lint:rubocop"
