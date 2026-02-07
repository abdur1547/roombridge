# frozen_string_literal: true

module Jwt
  class Authenticator < BaseService
    def call(headers:, cookies:)
      token = extract_token(headers, cookies)
      return failure("Missing authentication token") if token.blank?

      decode_result = Jwt::Decoder.call(access_token: token)
      return failure(decode_result.error) unless decode_result.success?

      decoded_token = decode_result.data
      user = authenticate_user_from_token(decoded_token)
      return failure("Invalid or blacklisted token") if user.blank?

      success([ user, decoded_token ])
    rescue => e
      Rails.logger.error "Authentication error: #{e.message}"
      failure("Authentication failed")
    end

    private

    def extract_token(headers, cookies)
      token = headers["Authorization"]&.split("Bearer ")&.last
      token ||= cookies["access_token"]
      token&.strip
    end

    def authenticate_user_from_token(decoded_token)
      jti = decoded_token[:jti]
      user_id = decoded_token[:user_id]

      return nil unless jti.present? && user_id.present?

      return nil if BlacklistedToken.exists?(jti: jti)

      User.find_by(id: user_id)
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
end
