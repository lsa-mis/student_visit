FactoryBot.define do
  factory :question do
    association :questionnaire
    text { "What is your question?" }
    question_type { "text" }
    position { 1 }
    options { nil }

    trait :text_type do
      question_type { "text" }
    end

    trait :rich_text_type do
      question_type { "rich_text" }
    end

    trait :checkbox_type do
      question_type { "checkbox" }
      options { ["Option 1", "Option 2", "Option 3"] }
    end

    trait :radio_type do
      question_type { "radio" }
      options { ["Option A", "Option B", "Option C"] }
    end

    trait :datetime_type do
      question_type { "datetime" }
    end

    trait :link_type do
      question_type { "link" }
    end
  end
end
