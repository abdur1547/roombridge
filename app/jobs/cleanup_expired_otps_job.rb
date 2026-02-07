# frozen_string_literal: true

class CleanupExpiredOtpsJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "Starting OTP cleanup job"

    # Clean up expired OTP codes from database
    deleted_count = OtpCode.cleanup_expired!

    Rails.logger.info "Cleaned up #{deleted_count} expired OTP records"

    Rails.logger.info "Cleaned up #{cleaned_count} expired OTP records"

    Rails.logger.info "OTP cleanup job completed"
  end
end
