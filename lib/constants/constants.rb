# frozen_string_literal: true

module Constants
  SESSION_LIFETIME = 15.minutes  # Access token lifetime - shorter for security
  REFRESH_TOKEN_LIFETIME = 30.days  # Refresh token lifetime - longer term access
  TOKEN_TYPE = "Bearer"
  DEFAULT_PER_PAGE = 50
  DEFAULT_PAGE = 1
  ORDER_DIRECTIONS = %w[asc ASC desc DESC].freeze
  API_DATE_FORMAT = "%d/%m/%Y"
  API_TIME_FORMAT = "%H:%M"

  # CNIC Hashing Salt - DO NOT CHANGE THIS VALUE AFTER PRODUCTION USE
  CNIC_SALT = "roombridge_cnic_salt_2026_secure_constant_key"

  MAX_SEND_ATTEMPTS = 5
  OTP_EXPIRY_TIME = 1.hour
  OTP_CACHE_PREFIX = "otp_send_attempts"
end
