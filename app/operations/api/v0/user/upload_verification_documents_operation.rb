# frozen_string_literal: true

module Api::V0::User
  class UploadVerificationDocumentsOperation < BaseOperation
    def call(user:, **params)
      @params = params
      @user = user

      # Validate that at least one file is provided
      yield validate_file_presence
      yield upload_verification_documents
      result = yield build_response_data

      Success(result)
    end

    private

    attr_reader :params, :user

    def validate_file_presence
      has_cnic = params["cnic_images"] && params["cnic_images"].respond_to?(:read)
      has_selfie = params["verification_selfie"] && params["verification_selfie"].respond_to?(:read)

      if !has_cnic && !has_selfie
        Failure([ "At least one verification document must be provided" ])
      else
        Success()
      end
    end

    def upload_verification_documents
      update_attributes = {}

      update_attributes[:cnic_images] = params["cnic_images"] if params["cnic_images"].present?
      update_attributes[:verification_selfie] = params["verification_selfie"] if params["verification_selfie"].present?

      if user.update(update_attributes)
        Success()
      else
        Failure(user.errors.full_messages)
      end
    end

    def build_response_data
      user.reload

      response_data = {
        message: "Verification documents uploaded successfully",
        verification_info: Api::V0::UserBlueprint.render_as_hash(user, view: :verification_status),
        uploaded_at: Time.current
      }

      Success(response_data)
    end
  end
end
