# frozen_string_literal: true

module Api::V0
  class ApiController < ActionController::API
    include ErrorHandler
    include Api::Versioning

    before_action :authenticate_user!

    attr_reader :current_user, :decoded_token

    private

    def authenticate_user!
      result = Jwt::Authenticator.call(
        headers: request.headers,
        cookies: request.cookies
      )

      if result.success?
        current_user, decoded_token = result.data
        @current_user ||= current_user
        @decoded_token ||= decoded_token
      else
        unauthorized_response(result.error)
      end
    end
  end
end
