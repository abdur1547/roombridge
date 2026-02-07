# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:phone_number) { |n| "+9230012345#{n.to_s.rjust(2, '0')}" }

    trait :fully_verified do
      full_name { "John Doe" }
      cnic_hash { Digest::SHA256.hexdigest("12345-1234567-1") }
      gender { :male }
      admin_verification_status { :verified }
      role { :seeker }
    end

    trait :female do
      gender { :female }
    end

    trait :lister do
      role { :lister }
    end

    trait :unverified do
      admin_verification_status { :unverified }
    end

    trait :pending_verification do
      admin_verification_status { :pending }
    end

    trait :rejected do
      admin_verification_status { :rejected }
    end
  end
end
