# frozen_string_literal: true

module Api::V0
  class AuthController < ApiController
    skip_before_action :authenticate_user!, only: %i[refresh]

    def refresh
      result = Api::V0::Auth::RefreshOperation.call(refresh_params)
      if result.success?
        data = result.value
        response.set_header("Authorization", "Bearer #{data[:access_token]}")
        success_response(data)
      else
        unauthorized_response(result.errors)
      end
    rescue => e
      Rails.logger.error "Refresh operation error: #{e.message}"
      internal_server_error("Authentication refresh failed")
    end

    def signout
      result = Api::V0::Auth::SignoutOperation.call(current_user, decoded_token)

      if result.success?
        success_response(result.value)
      else
        Rails.logger.warn "Signout operation warning: #{result.errors}"
        success_response({ message: "Signed out", signed_out_at: Time.current })
      end
    rescue => e
      Rails.logger.error "Signout operation error: #{e.message}"
      success_response({ message: "Signed out", signed_out_at: Time.current })
    end

    private

    def refresh_params
      {
        refresh_token: params[:refresh_token]
      }
    end
  end
end
