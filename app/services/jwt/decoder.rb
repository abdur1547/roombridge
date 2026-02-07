# frozen_string_literal: true

module Jwt
  class Decoder < BaseService
    ALGORITHM = "HS256"

    attr_reader :access_token, :verify

    def call(access_token:, verify: true)
      options = {
        verify_iat: true,
        verify_iss: true,
        verify_aud: true,
        iss: "RoomBridge",
        aud: "RoomBridge-API",
        algorithm: ALGORITHM
      }

      decoded_token = JWT.decode(
        access_token,
        secret_key,
        verify,
        options
      )[0]

      success(decoded_token.symbolize_keys)
    rescue JWT::ExpiredSignature => e
      Rails.logger.info "Expired JWT token: #{e.message}"
      failure("Token has expired")
    rescue JWT::InvalidIssuerError, JWT::InvalidAudError => e
      Rails.logger.warn "Invalid JWT issuer/audience: #{e.message}"
      failure("Invalid token source")
    rescue JWT::VerificationError => e
      Rails.logger.warn "JWT verification failed: #{e.message}"
      failure("Token verification failed")
    rescue JWT::DecodeError => e
      Rails.logger.warn "JWT decode error: #{e.message}"
      failure("Invalid token format")
    rescue => e
      Rails.logger.error "Unexpected JWT decode error: #{e.message}"
      failure("Token processing failed")
    end

    private

    def secret_key
      ENV.fetch("SECRET_KEY_BASE") do
        raise "SECRET_KEY_BASE environment variable is not set"
      end
    end
  end
end
