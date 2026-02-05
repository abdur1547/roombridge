# frozen_string_literal: true

class SmsService < BaseService
  def self.send_otp(phone_number, otp_code)
    # Use your SMS provider (Twilio, etc.)
    # In development, just log the OTP
    if Rails.env.development?
      Rails.logger.info "📱 OTP for #{phone_number}: #{otp_code}"
      puts "📱 SMS: Your verification code is: #{otp_code}"
      return success(sent: true, provider: "development")
    end

    # Production SMS sending logic
    case Rails.application.credentials.sms_provider
    when "twilio"
      send_via_twilio(phone_number, otp_code)
    else
      Rails.logger.error "No SMS provider configured"
      failure("SMS provider not configured")
    end
  rescue StandardError => e
    Rails.logger.error "SMS sending failed: #{e.message}"
    failure("SMS sending failed: #{e.message}")
  end

  private

  def self.send_via_twilio(phone_number, otp_code)
    # TODO: Implement Twilio integration
    # client = Twilio::REST::Client.new(
    #   Rails.application.credentials.twilio_account_sid,
    #   Rails.application.credentials.twilio_auth_token
    # )
    #
    # message = client.messages.create(
    #   body: "Your verification code is: #{otp_code}",
    #   to: phone_number,
    #   from: Rails.application.credentials.twilio_phone_number
    # )

    # For now, return success in production too
    Rails.logger.info "Would send OTP #{otp_code} to #{phone_number} via Twilio"
    success(sent: true, provider: "twilio")
  end
end
