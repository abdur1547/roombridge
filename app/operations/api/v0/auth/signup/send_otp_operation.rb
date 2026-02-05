# frozen_string_literal: true

module Api::V0::Auth::Signup
  class SendOtpOperation < BaseOperation
    contract do
      params do
        required(:phone_number).filled(:string)
      end
    end

    def call(params)
      @params = params
      yield normalize_phone_number
      yield check_rate_limits
      yield check_existing_user
      yield generate_and_send_otp
      Success(success_response)
    end

    private

    attr_reader :params, :phone_number, :user

    def normalize_phone_number
      @phone_number = PhoneNumberService.normalize(params[:phone_number])
      if phone_number.present? && PhoneNumberService.valid?(phone_number)
        Success()
      else
        Failure(error_message(:phone_number, "invalid format"))
      end
    end

    def check_rate_limits
      # Prevent OTP spam - max 3 OTPs per phone per hour
      cache_key = "otp_attempts:#{phone_number}"
      recent_attempts = Rails.cache.read(cache_key) || 0

      if recent_attempts >= 3
        Rails.logger.warn "Rate limit exceeded for phone: #{phone_number}"
        return Failure(error_message(:rate_limit, "too many attempts, please try again later"))
      end

      Success()
    end

    def check_existing_user
      existing_user = User.find_by(phone_number: phone_number)
      if existing_user&.otp_verified?
        Rails.logger.info "User already exists and verified: #{phone_number}"
        return Failure(error_message(:phone_number, "already registered"))
      end

      Success()
    end

    def generate_and_send_otp
      @user = User.find_or_initialize_by(phone_number: phone_number)

      # Generate 6-digit OTP
      otp_code = SecureRandom.random_number(900000) + 100000

      @user.assign_attributes(
        otp_code: otp_code.to_s,
        otp_expires_at: 5.minutes.from_now,
        otp_attempts: 0,
        last_otp_sent_at: Time.current,
        otp_verified: false
      )

      return Failure(@user.errors.to_hash) unless @user.save

      # Send OTP via SMS
      sms_result = SmsService.send_otp(phone_number, otp_code)
      return Failure(error_message(:sms, "failed to send")) unless sms_result.success?

      # Track rate limiting
      cache_key = "otp_attempts:#{phone_number}"
      current_attempts = Rails.cache.read(cache_key) || 0
      Rails.cache.write(cache_key, current_attempts + 1, expires_in: 1.hour)

      Rails.logger.info "OTP sent successfully to: #{phone_number}"
      Success()
    end

    def success_response
      {
        message: "OTP sent successfully",
        expires_in: 300, # 5 minutes
        phone_number: phone_number
      }
    end
  end
end
