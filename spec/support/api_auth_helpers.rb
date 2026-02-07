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

  # Set cookies for authentication (useful for refresh token tests)
  # @param tokens [Hash] Hash containing access_token and refresh_token
  def set_auth_cookies(tokens)
    cookies['access_token'] = tokens[:access_token]
    cookies['refresh_token'] = tokens[:refresh_token].token if tokens[:refresh_token].respond_to?(:token)
  end
end

RSpec.configure do |config|
  config.include ApiAuthHelpers, type: :request
end
