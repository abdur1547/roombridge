# frozen_string_literal: true

module Api::V0
  class SigninController < ApiController
    include ActionController::Cookies

    skip_before_action :authenticate_user!, only: %i[send_otp verify_otp]

    def send_otp
      result = Api::V0::Auth::Signin::SendOtpOperation.call(params.to_unsafe_h)
      if result.success?
        success_response(result.value)
      else
        unprocessable_entity(result.errors)
      end
    end

    def verify_otp
      result = Api::V0::Auth::Signin::VerifyOtpOperation.call(params.to_unsafe_h)
      if result.success?
        set_auth_cookies(result.value[:access_token], result.value[:refresh_token])
        response.set_header("Authorization", result.value[:access_token])
        success_response(result.value)
      else
        unprocessable_entity(result.errors)
      end
    end

    private

    def set_auth_cookies(access_token, refresh_token)
      cookies[:access_token] = {
        value: access_token,
        httponly: true,
        secure: Rails.env.production?,
        same_site: :lax
      }
      cookies[:refresh_token] = {
        value: refresh_token,
        httponly: true,
        secure: Rails.env.production?,
        same_site: :lax
      }
    end
  end
end
