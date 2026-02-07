# frozen_string_literal: true

module Api::V0::Contracts::Otp
  class VerifyOtpContract < Dry::Validation::Contract
    params do
      required(:phone_number).filled(:string)
      required(:code).filled(:string)
    end

    rule(:phone_number) do
      unless PhoneNumberService.valid?(value)
        key.failure("must be a valid phone number format")
      end
    end

    rule(:code) do
      unless /\A\d{6}\z/.match?(value)
        key.failure("must be a 6-digit numeric code")
      end
    end
  end
end
