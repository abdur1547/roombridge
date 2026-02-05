# frozen_string_literal: true

class CleanupExpiredOtpsJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting OTP cleanup job"

    # Clean up expired OTP codes from database
    cleaned_count = User.cleanup_expired_otps

    Rails.logger.info "Cleaned up #{cleaned_count} expired OTP records"

    # Clean up expired rate limiting cache entries
    # Note: Redis keys will expire automatically, but we can clean them manually if needed
    cleanup_expired_rate_limit_cache

    Rails.logger.info "OTP cleanup job completed"
  end

  private

  def cleanup_expired_rate_limit_cache
    # This would require Redis client to manually clean up expired keys
    # For now, we rely on Redis expiration
    Rails.logger.debug "Rate limiting cache cleanup (automatic expiration)"
  end
end
