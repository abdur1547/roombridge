# frozen_string_literal: true

module Api::V0::Auth::Signup
  class VerifyOtpOperation < BaseOperation
    contract do
      params do
        required(:phone_number).filled(:string)
        required(:otp_code).filled(:string)
        required(:full_name).filled(:string)
        optional(:email).filled(:string)
      end
    end

    def call(params)
      @params = params
      yield normalize_phone_number
      yield find_user
      yield verify_otp_code
      yield complete_registration
      yield issue_tokens
      Success(json_serialize)
    end

    private

    attr_reader :params, :phone_number, :user, :access_token, :refresh_token

    def normalize_phone_number
      @phone_number = PhoneNumberService.normalize(params[:phone_number])
      if phone_number.present? && PhoneNumberService.valid?(phone_number)
        Success()
      else
        Failure(error_message(:phone_number, "invalid format"))
      end
    end

    def find_user
      @user = User.find_by(phone_number: phone_number, otp_verified: false)
      if user.present?
        Success()
      else
        Rails.logger.warn "User not found or already verified: #{phone_number}"
        Failure(error_message(:phone_number, "invalid or already verified"))
      end
    end

    def verify_otp_code
      # Check if OTP is expired
      if user.otp_expires_at < Time.current
        Rails.logger.warn "Expired OTP attempt for: #{phone_number}"
        return Failure(error_message(:otp_code, "expired"))
      end

      # Check attempts limit (max 3 wrong attempts)
      if user.otp_attempts >= 3
        Rails.logger.warn "Too many OTP attempts for: #{phone_number}"
        return Failure(error_message(:otp_code, "too many attempts"))
      end

      # Verify OTP
      if user.otp_code == params[:otp_code]
        Rails.logger.info "OTP verified successfully for: #{phone_number}"
        Success()
      else
        user.increment(:otp_attempts)
        user.save
        Rails.logger.warn "Invalid OTP attempt for: #{phone_number}"
        Failure(error_message(:otp_code, "invalid"))
      end
    end

    def complete_registration
      user.assign_attributes(
        full_name: params[:full_name],
        email: params[:email],
        otp_verified: true,
        otp_code: nil,
        otp_expires_at: nil,
        otp_attempts: 0
      )

      if user.save
        Rails.logger.info "Registration completed for: #{phone_number}"
        # Clear rate limiting cache on successful registration
        Rails.cache.delete("otp_attempts:#{phone_number}")
        Success()
      else
        Rails.logger.error "Registration failed for: #{phone_number}, errors: #{user.errors.full_messages}"
        Failure(user.errors.to_hash)
      end
    end

    def issue_tokens
      token_pair = Jwt::Issuer.call(user).data
      @access_token = token_pair[:access_token]
      @refresh_token = token_pair[:refresh_token].token
      Success()
    end

    def json_serialize
      {
        access_token: "#{Constants::TOKEN_TYPE} #{access_token}",
        refresh_token: refresh_token,
        user: Api::V0::UserBlueprint.render_as_hash(user),
        message: "Registration completed successfully"
      }
    end
  end
end
