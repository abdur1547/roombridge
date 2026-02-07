FactoryBot.define do
  factory :otp_code do
    phone_number { "MyString" }
    code { "MyString" }
    expires_at { "2026-02-07 15:26:35" }
    consumed_at { "2026-02-07 15:26:35" }
  end
end
