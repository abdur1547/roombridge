# frozen_string_literal: true

FactoryBot.define do
  factory :blacklisted_token do
    jti { SecureRandom.hex(16) }
    association :user
    exp { 24.hours.from_now }

    trait :expired do
      exp { 1.hour.ago }
    end
  end
end
