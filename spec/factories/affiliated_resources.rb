FactoryBot.define do
  factory :affiliated_resource do
    association :department
    name { "Test Resource #{SecureRandom.hex(4)}" }
    url { "https://example.com/resource" }
    position { 0 }
  end
end
