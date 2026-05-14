FactoryBot.define do
  factory :property do
    property_type { 1 }
    city { Faker::Address.city }
    area { "#{Faker::Name.first_name} Town" }
    address { Faker::Address.street_address }
    total_bedrooms { 1 }
    total_bathrooms { 1 }
    parking { false }
  end
end
