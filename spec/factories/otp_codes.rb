FactoryBot.define do
  factory :otp_code do
    phone_number { "+923001234567" }
    code { "123456" }
    expires_at { 10.minutes.from_now }
    consumed_at { nil }

    trait :consumed do
      consumed_at { 5.minutes.ago }
    end

    trait :expired do
      expires_at { 1.minute.ago }
    end

    trait :expired_and_consumed do
      expires_at { 1.minute.ago }
      consumed_at { 2.minutes.ago }
    end
  end
end
