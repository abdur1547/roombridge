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
      yield validate_refresh_token
      Success(json_serialize)
    end

    private

    attr_reader :params, :user, :decoded_token

    def validate_refresh_token
      refresh_token = RefreshToken.find_by_token(params[:refresh_token]) # rubocop:disable Rails/DynamicFindBy
      return Failure(:unauthorized) unless refresh_token

      @user = User.find_by(id: refresh_token.user_id)
      return Failure(:unauthorized) unless user

      Success()
    end

    def json_serialize
      {
        access_token: Jwt::Encoder.call(user).data.first
      }
    end
  end
end
