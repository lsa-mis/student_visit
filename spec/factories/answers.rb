FactoryBot.define do
  factory :answer do
    association :question
    association :student, factory: :user, traits: [:with_student_role]
    association :program
    content { "Test answer content" }
  end
end
