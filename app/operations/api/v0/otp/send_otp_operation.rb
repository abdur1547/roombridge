# frozen_string_literal: true

module Api::V0::Otp
  class SendOtpOperation < BaseOperation
    contract_class Api::V0::Contracts::Otp::SendOtpContract

    def call(params)
      phone_number = PhoneNumberService.normalize(params[:phone_number])

      return Failure("Invalid phone number format") if phone_number.nil?

      yield check_send_rate_limit(phone_number)

      yield deactivate_existing_otp(phone_number)

      otp_record = yield create_otp_record(phone_number)

      yield send_otp_message(otp_record)

      Success({
        message: "OTP sent successfully",
        phone_number: mask_phone_number(phone_number),
        expires_in_minutes: otp_record.time_until_expiry,
        sent_at: otp_record.created_at
      })
    end

    private

    def check_send_rate_limit(phone_number)
      recent_attempts = Rails.cache.read("#{Constants::OTP_CACHE_PREFIX}:#{phone_number}") || 0

      if recent_attempts >= Constants::MAX_SEND_ATTEMPTS
        return Failure("Too many OTP requests. Please try again later.")
      end

      Rails.cache.write(
        "#{Constants::OTP_CACHE_PREFIX}:#{phone_number}",
        recent_attempts + 1,
        expires_in: Constants::OTP_EXPIRY_TIME
      )

      Success()
    end

    def deactivate_existing_otp(phone_number)
      existing_otp = OtpCode.find_active_for_phone(phone_number)
      existing_otp&.consume!

      Success()
    rescue => e
      Rails.logger.error "Failed to deactivate existing OTP: #{e.message}"
      Success() # Continue even if deactivation fails
    end

    def create_otp_record(phone_number)
      otp_code = OtpCode.generate_code
      expires_at = 5.minutes.from_now # 5 minute expiry

      otp_record = OtpCode.create!(
        phone_number: phone_number,
        code: otp_code,
        expires_at: expires_at
      )

      Success(otp_record)
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Failed to create OTP record: #{e.message}"
      Failure("Failed to generate OTP. Please try again.")
    rescue => e
      Rails.logger.error "Unexpected error creating OTP: #{e.message}"
      Failure("System error. Please try again later.")
    end

    def send_otp_message(otp_record)
      # In development/test, log the OTP instead of sending SMS
      if Rails.env.development? || Rails.env.test?
        Rails.logger.info "OTP for #{otp_record.phone_number}: #{otp_record.code}"
        return Success()
      end

      # In production, integrate with SMS service like Twilio, AWS SNS, etc.
      # Example structure:
      # begin
      #   SmsService.send_message(
      #     to: otp_record.phone_number,
      #     body: "Your verification code is: #{otp_record.code}. Valid for 10 minutes."
      #   )
      #   Success()
      # rescue SmsService::Error => e
      #   Rails.logger.error "SMS sending failed: #{e.message}"
      #   Failure("Failed to send OTP. Please try again.")
      # end

      # For now, simulate successful sending in production
      Rails.logger.info "SMS would be sent to #{otp_record.phone_number}"
      Success()
    end

    def mask_phone_number(phone)
      return phone if phone.length < 4

      "#{phone[0...-4]}****"
    end
  end
end
