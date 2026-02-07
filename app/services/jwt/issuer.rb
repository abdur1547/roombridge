# frozen_string_literal: true

module Jwt
  class Issuer < BaseService
    def call(user)
      encoder_result = Jwt::Encoder.call(user)
      return failure("Failed to generate access token") unless encoder_result.success

      access_token = encoder_result.data.first

      refresh_token = user.refresh_tokens.create!

      success({
        access_token: access_token,
        refresh_token: refresh_token,
        token_type: Constants::TOKEN_TYPE,
        expires_in: Constants::SESSION_LIFETIME.to_i
      })
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Failed to create refresh token: #{e.message}"
      failure("Failed to create refresh token")
    rescue => e
      Rails.logger.error "Token issuance failed: #{e.message}"
      failure("Token generation failed")
    end
  end
end
