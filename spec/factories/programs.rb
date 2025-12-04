FactoryBot.define do
  factory :program do
    association :department
    name { "Test Program #{SecureRandom.hex(4)}" }
    default_appointment_length { 30 }
    active { true }
    open_date { 1.month.ago }
    close_date { 1.month.from_now }
    questionnaire_due_date { 2.weeks.from_now }
    held_on_dates { [] }
    google_map_url { nil }

    trait :inactive do
      active { false }
    end

    trait :closed do
      close_date { 1.day.ago }
    end

    trait :with_held_on_dates do
      held_on_dates { [ Date.current.to_s, 1.week.from_now.to_date.to_s ] }
    end
  end
end
