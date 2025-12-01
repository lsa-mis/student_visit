FactoryBot.define do
  factory :questionnaire do
    association :program
    name { "Test Questionnaire #{SecureRandom.hex(4)}" }

    trait :with_questions do
      after(:create) do |questionnaire|
        create_list(:question, 3, questionnaire: questionnaire)
      end
    end
  end
end
