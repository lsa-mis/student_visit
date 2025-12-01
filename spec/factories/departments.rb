FactoryBot.define do
  factory :department do
    name { "Test Department #{SecureRandom.hex(4)}" }
    building_name { "Test Building" }
    city { "Ann Arbor" }
    state { "MI" }
    street_address { "123 Test St" }
    zipcode { "48104" }
    main_office_room_number { "100" }
    main_office_phone_number { "734-555-1234" }

    trait :with_active_program do
      after(:create) do |department|
        program = create(:program, department: department, active: true)
        department.update!(active_program: program)
      end
    end
  end
end
