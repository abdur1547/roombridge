# frozen_string_literal: true

module Api::V0::Contracts::Otp
  class SendOtpContract < Dry::Validation::Contract
    params do
      required(:phone_number).filled(:string)
    end

    rule(:phone_number) do
      unless PhoneNumberService.valid?(value)
        key.failure("must be a valid phone number format")
      end
    end
  end
end
