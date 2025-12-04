FactoryBot.define do
  factory :page_content do
    sequence(:page_path) { |n| "/test-page-#{n}" }
    sequence(:area_name) { |n| "main_content_#{n}" }
    content { "Test content" }
  end
end
