FactoryBot.define do
  factory :vip do
    association :program
    name { "Dr. #{SecureRandom.hex(4)}" }
    title { "Professor" }
    ranking { 0 }
    profile_url { nil }
  end
end
