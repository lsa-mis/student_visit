FactoryBot.define do
  factory :user do
    email_address { "user#{SecureRandom.hex(4)}@example.com" }
    password { "password123" }
    first_name { "John" }
    last_name { "Doe" }
    umid { nil }

    trait :with_student_role do
      after(:create) do |user|
        user.add_role('student')
      end
    end

    trait :with_super_admin_role do
      after(:create) do |user|
        user.add_role('super_admin')
      end
    end

    trait :with_department_admin_role do
      after(:create) do |user|
        user.add_role('department_admin')
      end
    end

    trait :with_faculty_role do
      after(:create) do |user|
        user.add_role('faculty')
      end
    end
  end
end
