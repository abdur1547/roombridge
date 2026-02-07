# frozen_string_literal: true

module Api::V0::Otp
  class VerifyOtpOperation < BaseOperation
    contract_class Api::V0::Contracts::Otp::VerifyOtpContract

    # Maximum number of verification attempts allowed
    MAX_VERIFICATION_ATTEMPTS = 5

    def call(params)
      phone_number = PhoneNumberService.normalize(params[:phone_number])

      return Failure("Invalid phone number format") if phone_number.nil?

      code = params[:code]

      # Check rate limiting for verification attempts
      yield check_verification_rate_limit(phone_number)

      # Find active OTP for the phone number
      otp_record = yield find_active_otp(phone_number)

      # Verify the code
      yield verify_code(otp_record, code)

      # Mark OTP as consumed
      yield consume_otp(otp_record)

      Success({
        message: "OTP verified successfully",
        phone_number: mask_phone_number(phone_number),
        verified_at: Time.current
      })
    end

    private

    def check_verification_rate_limit(phone_number)
      # Check for too many verification attempts in the last hour
      recent_attempts = Rails.cache.read("otp_verify_attempts:#{phone_number}") || 0

      if recent_attempts >= MAX_VERIFICATION_ATTEMPTS
        return Failure("Too many verification attempts. Please request a new OTP.")
      end

      # Increment attempt counter
      Rails.cache.write(
        "otp_verify_attempts:#{phone_number}",
        recent_attempts + 1,
        expires_in: 1.hour
      )

      Success()
    end

    def find_active_otp(phone_number)
      otp_record = OtpCode.for_phone(phone_number).order(created_at: :desc).first

      if otp_record.nil?
        return Failure("No active OTP found for this phone number. Please request a new OTP.")
      end

      if otp_record.expired?
        return Failure("OTP has expired. Please request a new OTP.")
      end

      if otp_record.consumed?
        return Failure("OTP has already been used. Please request a new OTP.")
      end

      Success(otp_record)
    end

    def verify_code(otp_record, provided_code)
      # Use secure comparison to prevent timing attacks
      if !ActiveSupport::SecurityUtils.secure_compare(otp_record.code, provided_code)
        return Failure("Invalid OTP code. Please check and try again.")
      end

      Success()
    end

    def consume_otp(otp_record)
      otp_record.consume!

      # Clear verification attempts counter on successful verification
      Rails.cache.delete("otp_verify_attempts:#{otp_record.phone_number}")

      Success()
    rescue => e
      Rails.logger.error "Failed to consume OTP: #{e.message}"
      Failure("Verification failed. Please try again.")
    end

    def mask_phone_number(phone)
      return phone if phone.length < 4

      "#{phone[0...-4]}****"
    end
  end
end
