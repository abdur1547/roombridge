# frozen_string_literal: true

class CleanupExpiredTokensJob < ApplicationJob
  queue_as :low_priority

  def perform
    cleanup_expired_refresh_tokens
    cleanup_expired_blacklisted_tokens
    Rails.logger.info "Token cleanup completed at #{Time.current}"
  end

  private

  def cleanup_expired_refresh_tokens
    expired_count = RefreshToken.where("exp < ?", Time.current).delete_all
    Rails.logger.info "Cleaned up #{expired_count} expired refresh tokens"
  end

  def cleanup_expired_blacklisted_tokens
    expired_count = BlacklistedToken.where("exp < ?", Time.current).delete_all
    Rails.logger.info "Cleaned up #{expired_count} expired blacklisted tokens"
  end
end
