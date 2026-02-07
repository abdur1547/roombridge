# frozen_string_literal: true

# Rate limiting and attack protection configuration
# NOTE: This requires the 'rack-attack' gem to be added to Gemfile
# Run 'bundle install' after adding gem 'rack-attack' to Gemfile

class Rack::Attack
  ### Configure Cache
  # Note: This will use Rails.cache by default, no need to explicitly set it

  ### Throttle OTP Requests
  # Throttle OTP send requests by phone number (5 requests per hour)
  throttle("otp/send", limit: 5, period: 1.hour) do |req|
    req.params["phone_number"] if req.path.include?("send_otp")
  end

  # Throttle OTP verification attempts by phone number (5 attempts per 15 minutes)
  throttle("otp/verify", limit: 5, period: 15.minutes) do |req|
    req.params["phone_number"] if req.path.include?("verify_otp")
  end

  ### General API Throttling
  # Throttle all API requests by IP (100 requests per hour)
  throttle("api/requests/ip", limit: 100, period: 1.hour) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  # Throttle auth requests by IP (10 requests per 15 minutes)
  throttle("auth/requests/ip", limit: 10, period: 15.minutes) do |req|
    req.ip if req.path.include?("/api/v0/auth")
  end

  ### Safelist and Blocklist
  # Always allow requests from localhost in development
  safelist("allow local") do |req|
    "127.0.0.1" == req.ip || "::1" == req.ip if Rails.env.development?
  end

  ### Custom response for throttled requests
  self.throttled_responder = lambda do |env|
    [
      429, # status
      { "Content-Type" => "application/json" }, # headers
      [ { error: "Rate limit exceeded", retry_after: env["rack.attack.match_data"][:period] }.to_json ] # body
    ]
  end

  ### Logging
  ActiveSupport::Notifications.subscribe("rack.attack") do |name, start, finish, request_id, payload|
    req = payload[:request]
    Rails.logger.warn "[Rack::Attack] #{req.ip} #{req.request_method} #{req.fullpath} - #{payload[:match_type]} #{payload[:match_discriminator]}"
  end
end
