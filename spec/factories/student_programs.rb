FactoryBot.define do
  factory :student_program do
    association :user
    association :program
  end
end
