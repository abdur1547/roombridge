# frozen_string_literal: true

module Api::V0
  class UsersController < ApiController
    def show
      result = Api::V0::User::ShowOperation.call(user: current_user)

      if result.success?
        success_response(result.value)
      else
        unprocessable_entity(result.errors)
      end
    end

    def update
      result = Api::V0::User::UpdateOperation.call(user: current_user, **update_params)

      if result.success?
        success_response(result.value)
      else
        unprocessable_entity(result.errors)
      end
    end

    def upload_verification_documents
      result = Api::V0::User::UploadVerificationDocumentsOperation.call(
        user: current_user, **verification_params
      )

      if result.success?
        success_response(result.value)
      else
        unprocessable_entity(result.errors)
      end
    end

    private

    def update_params
      params.permit(:profile_picture)
    end

    def verification_params
      params.permit(:cnic_images, :verification_selfie)
    end
  end
end
