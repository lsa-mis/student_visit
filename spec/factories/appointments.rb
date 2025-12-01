FactoryBot.define do
  factory :appointment do
    association :program
    association :vip
    start_time { 1.week.from_now }
    end_time { 1.week.from_now + 30.minutes }
    student { nil }

    trait :available do
      student { nil }
    end

    trait :booked do
      association :student, factory: :user, traits: [:with_student_role]
    end

    trait :upcoming do
      start_time { 1.week.from_now }
      end_time { 1.week.from_now + 30.minutes }
    end

    trait :past do
      start_time { 1.week.ago }
      end_time { 1.week.ago + 30.minutes }
    end
  end
end
