FactoryBot.define do
  factory :role do
    name { "student" }

    trait :super_admin do
      name { "super_admin" }
    end

    trait :department_admin do
      name { "department_admin" }
    end

    trait :student do
      name { "student" }
    end

    trait :faculty do
      name { "faculty" }
    end
  end
end
