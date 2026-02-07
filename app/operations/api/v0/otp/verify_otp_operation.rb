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

      yield check_verification_rate_limit(phone_number)
      otp_record = yield find_active_otp(phone_number)
      yield verify_code(otp_record, code)
      yield consume_otp(otp_record)
      user = yield find_or_create_user(phone_number)
      tokens = yield generate_tokens(user)

      Success({
        message: "OTP verified successfully",
        phone_number: mask_phone_number(phone_number),
        verified_at: Time.current,
        access_token: tokens[:access_token],
        refresh_token: tokens[:refresh_token].token,
        token_type: tokens[:token_type],
        expires_in: tokens[:expires_in],
        user: {
          id: user.id,
          phone_number: user.phone_number,
          full_name: user.full_name,
          fully_verified: user.fully_verified?
        }
      })
    end

    private

    def check_verification_rate_limit(phone_number)
      recent_attempts = Rails.cache.read("otp_verify_attempts:#{phone_number}") || 0

      if recent_attempts >= MAX_VERIFICATION_ATTEMPTS
        return Failure("Too many verification attempts. Please request a new OTP.")
      end

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
      if !ActiveSupport::SecurityUtils.secure_compare(otp_record.code, provided_code)
        return Failure("Invalid OTP code. Please check and try again.")
      end

      Success()
    end

    def consume_otp(otp_record)
      otp_record.consume!

      Rails.cache.delete("otp_verify_attempts:#{otp_record.phone_number}")

      Success()
    rescue => e
      Rails.logger.error "Failed to consume OTP: #{e.message}"
      Failure("Verification failed. Please try again.")
    end

    def find_or_create_user(phone_number)
      user = User.find_by(phone_number: phone_number)

      if user.nil?
        user = User.create!(phone_number: phone_number)
        Rails.logger.info "Created new user for phone: #{mask_phone_number(phone_number)}"
      end

      Success(user)
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Failed to create user: #{e.message}"
      Failure("Failed to create user account")
    rescue => e
      Rails.logger.error "User creation error: #{e.message}"
      Failure("Account setup failed")
    end

    def generate_tokens(user)
      result = Jwt::Issuer.call(user)

      if result.success?
        Success(result.data)
      else
        Rails.logger.error "Token generation failed for user #{user.id}"
        Failure("Failed to generate authentication tokens")
      end
    end

    def mask_phone_number(phone)
      return phone if phone.length < 4

      "#{phone[0...-4]}****"
    end
  end
end
