# frozen_string_literal: true

module Api::V0
  class AuthController < ApiController
    include ActionController::Cookies

    skip_before_action :authenticate_user!, only: %i[refresh]

    def refresh
      result = Api::V0::Auth::RefreshOperation.call(refresh_params)
      if result.success?
        data = result.value!
        set_auth_cookies(data[:access_token], data[:refresh_token]) if data[:refresh_token]
        response.set_header("Authorization", "Bearer #{data[:access_token]}")
        success_response(data)
      else
        clear_auth_cookies
        unauthorized(result.failure)
      end
    rescue => e
      Rails.logger.error "Refresh operation error: #{e.message}"
      clear_auth_cookies
      internal_server_error("Authentication refresh failed")
    end

    def signout
      result = Api::V0::Auth::SignoutOperation.call(current_user, decoded_token)

      clear_auth_cookies

      if result.success?
        success_response(result.value!)
      else
        Rails.logger.warn "Signout operation warning: #{result.failure}"
        success_response({ message: "Signed out", signed_out_at: Time.current })
      end
    rescue => e
      Rails.logger.error "Signout operation error: #{e.message}"
      clear_auth_cookies
      success_response({ message: "Signed out", signed_out_at: Time.current })
    end

    private

    def set_auth_cookies(access_token, refresh_token)
      cookie_options = {
        httponly: true,
        secure: Rails.env.production?,
        samesite: :lax
      }

      cookies[:access_token] = cookie_options.merge(
        value: access_token,
        expires: Constants::SESSION_LIFETIME.from_now
      )

      if refresh_token
        cookies[:refresh_token] = cookie_options.merge(
          value: refresh_token,
          expires: Constants::REFRESH_TOKEN_LIFETIME.from_now
        )
      end
    end

    def clear_auth_cookies
      cookie_options = {
        httponly: true,
        secure: Rails.env.production?,
        samesite: :lax
      }

      cookies.delete(:access_token, cookie_options)
      cookies.delete(:refresh_token, cookie_options)
    end

    def refresh_params
      {
        refresh_token: request.cookies["refresh_token"] || params[:refresh_token]
      }
    end
  end
end
