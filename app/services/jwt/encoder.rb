# frozen_string_literal: true

module Jwt
  class Encoder < BaseService
    ALGORITHM = "HS256"

    def call(user, exp = nil)
      jti = SecureRandom.hex(16)
      iat = token_issued_at
      exp ||= token_expiry(iat)

      payload = {
        user_id: user.id,
        jti: jti,
        iat: iat,
        exp: exp,
        iss: "RoomBridge",
        aud: "RoomBridge-API"
      }

      access_token = JWT.encode(
        payload,
        secret_key,
        ALGORITHM
      )

      success([ access_token, jti, exp ])
    rescue => e
      Rails.logger.error "JWT encoding failed: #{e.message}"
      failure("Token generation failed")
    end

    private

    def token_expiry(iat)
      iat + Constants::SESSION_LIFETIME.to_i
    end

    def token_issued_at
      Time.current.to_i
    end

    def secret_key
      ENV.fetch("SECRET_KEY_BASE") do
        raise "SECRET_KEY_BASE environment variable is not set"
      end
    end
  end
end
