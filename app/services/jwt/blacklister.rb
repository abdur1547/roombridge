# frozen_string_literal: true

module Jwt
  class Blacklister < BaseService
    def call(jti:, user:, exp: nil)
      exp_time = exp ? Time.at(exp).utc : 24.hours.from_now.utc

      token = user.blacklisted_tokens.create!(
        jti: jti,
        exp: exp_time
      )

      success(token)
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Failed to blacklist token: #{e.message}"
      failure("Failed to blacklist token")
    rescue => e
      Rails.logger.error "Unexpected blacklist error: #{e.message}"
      failure("Token blacklisting failed")
    end
  end
end
