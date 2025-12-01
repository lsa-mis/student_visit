FactoryBot.define do
  factory :calendar_event do
    association :program
    title { "Test Event #{SecureRandom.hex(4)}" }
    start_time { 1.week.from_now }
    end_time { 1.week.from_now + 1.hour }
    mandatory { false }

    # Ensure end_time is always after start_time
    after(:build) do |event|
      event.end_time ||= event.start_time + 1.hour if event.start_time
    end

    trait :mandatory do
      mandatory { true }
    end

    trait :upcoming do
      start_time { 1.week.from_now }
      end_time { 1.week.from_now + 1.hour }
    end

    trait :past do
      start_time { 1.week.ago }
      end_time { 1.week.ago + 1.hour }
    end
  end
end
