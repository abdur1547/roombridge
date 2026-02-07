# frozen_string_literal: true

module Api::V0::User
  class UploadVerificationDocumentsOperation < BaseOperation
    contract do
      extend Contracts::FileUploadValidation

      params do
        optional(:cnic_images)
        optional(:verification_selfie)
      end

      validate_file_upload(:cnic_images)
      validate_file_upload(:verification_selfie)

      rule do
        if !values[:cnic_images].present? && !values[:verification_selfie].present?
          key.failure("at least one verification document must be provided")
        end
      end
    end

    def call(user:, **params)
      @params = params
      @user = user
      result = yield upload_verification_documents
      result = yield build_response_data

      Success(result)
    end

    private

    attr_reader :params, :user

    def upload_verification_documents
      update_attributes = {}

      update_attributes[:cnic_images] = params[:cnic_images] if params[:cnic_images].present?
      update_attributes[:verification_selfie] = params[:verification_selfie] if params[:verification_selfie].present?

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
