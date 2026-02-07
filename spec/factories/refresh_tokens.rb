# frozen_string_literal: true

FactoryBot.define do
  factory :refresh_token do
    association :user
    exp { 30.days.from_now }

    trait :expired do
      exp { 1.day.ago }
    end

    trait :expiring_soon do
      exp { 1.hour.from_now }
    end
  end
end
