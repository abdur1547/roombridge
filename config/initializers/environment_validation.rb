# frozen_string_literal: true

# Environment Variable Validation
# This ensures all required environment variables are set before the app starts

class EnvironmentValidator
  REQUIRED_VARS = {
    "SECRET_KEY_BASE" => "Rails secret key for encryption",
    "DATABASE_URL" => "Database connection string"
  }.freeze

  PRODUCTION_ONLY_VARS = {
    "CORS_ALLOWED_ORIGINS" => "Allowed CORS origins for production"
  }.freeze

  def self.validate!
    missing_vars = []

    # Check required variables
    REQUIRED_VARS.each do |var, description|
      if ENV[var].blank?
        missing_vars << "#{var} (#{description})"
      end
    end

    # Check production-only variables in production
    if Rails.env.production?
      PRODUCTION_ONLY_VARS.each do |var, description|
        if ENV[var].blank?
          missing_vars << "#{var} (#{description}) - Required in production"
        end
      end
    end

    # Validate specific formats
    validate_formats(missing_vars)

    if missing_vars.any?
      error_message = "Missing required environment variables:\n" +
                     missing_vars.map { |var| "  - #{var}" }.join("\n")

      Rails.logger.fatal error_message
      raise error_message
    end

    Rails.logger.info "✓ All required environment variables are present"
  end

  private

  def self.validate_formats(missing_vars)
    # Validate SECRET_KEY_BASE length
    if ENV["SECRET_KEY_BASE"].present? && ENV["SECRET_KEY_BASE"].length < 64
      missing_vars << "SECRET_KEY_BASE must be at least 64 characters long for security"
    end

    # Validate CORS_ALLOWED_ORIGINS format in production
    if Rails.env.production? && ENV["CORS_ALLOWED_ORIGINS"].present?
      origins = ENV["CORS_ALLOWED_ORIGINS"].split(",")
      origins.each do |origin|
        unless origin.strip.match?(/\Ahttps?:\/\//)
          missing_vars << "CORS_ALLOWED_ORIGINS must contain valid URLs (found: #{origin.strip})"
        end
      end
    end
  end
end

# Validate environment variables when Rails starts
EnvironmentValidator.validate!
