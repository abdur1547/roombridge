# frozen_string_literal: true

module Contracts
  module FileUploadValidation
    extend ActiveSupport::Concern

    class_methods do
      def validate_file_upload(field_name)
        rule(field_name) do
          if value.present?
            unless value.is_a?(ActionDispatch::Http::UploadedFile) ||
                   value.is_a?(Rack::Test::UploadedFile) ||
                   value.respond_to?(:read)
              key.failure("must be a valid file upload")
            end
          end
        end
      end
    end
  end
end
