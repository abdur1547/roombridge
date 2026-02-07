# frozen_string_literal: true

module Api::V0::Auth
  class SignoutOperation < BaseOperation
    def call(user, decoded_token)
      jti = decoded_token&.fetch(:jti, nil)
      exp = decoded_token&.fetch(:exp, nil)

      return Failure("Invalid token data") if jti.blank?

      yield blacklist_access_token(user, jti, exp)

      yield revoke_refresh_tokens(user)

      Success({
        message: "Successfully signed out",
        signed_out_at: Time.current
      })
    end

    private

    def blacklist_access_token(user, jti, exp)
      result = Jwt::Blacklister.call(jti: jti, user: user, exp: exp)

      if result.success?
        Success()
      else
        Failure("Failed to invalidate token")
      end
    end

    def revoke_refresh_tokens(user)
      user.refresh_tokens.destroy_all
      Success()
    rescue => e
      Rails.logger.error "Failed to revoke refresh tokens: #{e.message}"
      Success()
    end
  end
end
