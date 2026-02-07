# frozen_string_literal: true

module Api::V0::Auth
  class RefreshOperation < BaseOperation
    contract do
      params do
        required(:refresh_token).filled(:string)
      end
    end

    def call(params)
      @params = params
      @refresh_token_record = yield validate_refresh_token
      @user = @refresh_token_record.user

      result = yield generate_new_tokens

      yield rotate_refresh_token if should_rotate_refresh_token?

      Success(json_serialize(result))
    end

    private

    attr_reader :params, :user, :refresh_token_record

    def validate_refresh_token
      refresh_token = RefreshToken.find_by_token(params[:refresh_token])
      return Failure("Invalid refresh token") unless refresh_token


      if refresh_token.exp < Time.current
        refresh_token.destroy
        return Failure("Refresh token has expired")
      end

      # Verify user still exists and is active
      user = User.find_by(id: refresh_token.user_id)
      return Failure("User not found") unless user

      Success(refresh_token)
    end

    def generate_new_tokens
      result = Jwt::Issuer.call(user)

      if result.success?
        Success(result.data)
      else
        Failure("Failed to generate new tokens")
      end
    end

    def rotate_refresh_token
      refresh_token_record.destroy
      Success()
    rescue => e
      Rails.logger.error "Failed to rotate refresh token: #{e.message}"
      Success()
    end

    def should_rotate_refresh_token?
      time_since_creation = Time.current - refresh_token_record.created_at
      total_lifetime = Constants::REFRESH_TOKEN_LIFETIME

      time_since_creation > (total_lifetime / 2)
    end

    def json_serialize(token_data)
      response = {
        access_token: token_data[:access_token]
      }

      if should_rotate_refresh_token?
        response[:refresh_token] = token_data[:refresh_token].token
      end

      response
    end
  end
end
