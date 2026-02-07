# frozen_string_literal: true

module ApiAuthHelpers
  # Generate JWT tokens for a user using the JWT services
  # @param user [User] The user to generate tokens for
  # @return [Hash] Hash containing access_token and refresh_token
  def generate_tokens_for_user(user)
    result = Jwt::Issuer.call(user)
    raise "Token generation failed: #{result.failure}" unless result.success?

    result.data
  end

  # Create authorization header with JWT token
  # @param token [String] The JWT token
  # @return [Hash] Headers hash with Authorization
  def auth_headers(token)
    { 'Authorization' => "Bearer #{token}" }
  end

  # Generate access token for a user and return auth headers
  # @param user [User] The user to authenticate
  # @return [Hash] Headers with Authorization token
  def authenticate_user(user)
    tokens = generate_tokens_for_user(user)
    auth_headers(tokens[:access_token])
  end

  # Generate decoded token data for testing
  # @param user [User] The user
  # @param jti [String] Optional JTI for token
  # @return [Hash] Decoded token data
  def generate_decoded_token(user, jti: SecureRandom.hex(16))
    {
      user_id: user.id,
      jti: jti,
      iat: Time.current.to_i,
      exp: 15.minutes.from_now.to_i,
      iss: 'RoomBridge',
      aud: 'RoomBridge-API'
    }
  end

  # Generate an expired token for testing
  # @param user [User] The user
  # @return [String] An expired JWT token
  def generate_expired_token(user)
    expired_payload = {
      user_id: user.id,
      jti: SecureRandom.hex(16),
      iat: 2.hours.ago.to_i,
      exp: 1.hour.ago.to_i,
      iss: 'RoomBridge',
      aud: 'RoomBridge-API'
    }
    Jwt::Encoder.call(expired_payload).data
  end
end

RSpec.configure do |config|
  config.include ApiAuthHelpers, type: :request
end
