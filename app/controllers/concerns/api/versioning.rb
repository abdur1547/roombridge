# frozen_string_literal: true

module Api
  module Versioning
    extend ActiveSupport::Concern

    included do
      before_action :set_api_version_headers
      before_action :log_api_request
    end

    private

    def set_api_version_headers
      response.headers["X-API-Version"] = api_version
      response.headers["X-API-Media-Type"] = "application/vnd.roombridge.v0+json"
      response.headers["X-RateLimit-Limit"] = "100"
      response.headers["X-RateLimit-Remaining"] = rate_limit_remaining.to_s if respond_to?(:rate_limit_remaining)
    end

    def log_api_request
      Rails.logger.info do
        "API Request: #{request.method} #{request.path} " \
        "Version: #{api_version} " \
        "User: #{current_user&.id || 'anonymous'} " \
        "IP: #{request.remote_ip}"
      end
    end

    def api_version
      # Extract version from controller namespace
      self.class.module_parent.name.split("::").last.downcase
    end
  end
end
