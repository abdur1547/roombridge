# frozen_string_literal: true

module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError do |exception|
      case exception.class.name
      when ActiveRecord::RecordInvalid.name
        unprocessable_entity(exception.message)
      when ActiveRecord::RecordNotFound.name
        not_found_response("Resource not found")
      when ActionController::ParameterMissing.name
        bad_request_response("Missing required parameter: #{exception.param}")
      when ::Auth::InvalidTokenError.name, ::Auth::MissingTokenError.name
        forbidden_response(exception.message)
      when ::Auth::UnauthorizedError.name
        unauthorized_response
      when JWT::ExpiredSignature.name
        unauthorized_response("Token has expired")
      when JWT::DecodeError.name, JWT::VerificationError.name
        unauthorized_response("Invalid token")
      else
        process_standard_error(exception)
      end
    end
  end

  private

  def success_response(data = {}, status: :ok)
    render json: { success: true, data: }, status:
  end

  def process_standard_error(exception)
    Rails.logger.error "Unhandled exception: #{exception.class} - #{exception.message}"
    Rails.logger.error exception.backtrace.join("\n") if Rails.env.development?

    error_message = Rails.env.production? ? "An internal error occurred" : exception.message
    render json: { success: false, error: error_message }, status: :internal_server_error
  end

  def unauthorized_response(reason = "You are unauthorized to access this resource")
    render json: { success: false, error: reason }, status: :unauthorized
  end

  def not_found_response(reason = "The requested resource does not exist")
    render json: { success: false, error: reason }, status: :not_found
  end

  def bad_request_response(reason = "Bad request")
    render json: { success: false, error: reason }, status: :bad_request
  end

  def unprocessable_entity(reason)
    render json: { success: false, error: reason }, status: :unprocessable_entity
  end

  def forbidden_response(reason = "Forbidden")
    render json: { success: false, error: reason }, status: :forbidden
  end

  def internal_server_error(reason = "Internal server error")
    render json: { success: false, error: reason }, status: :internal_server_error
  end
end
