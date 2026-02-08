# frozen_string_literal: true

module Api::V0::User
  class UpdateOperation < BaseOperation
    def call(user:, **params)
      @params = params
      @user = user

      yield update_user_profile
      result = yield build_updated_user_data

      Success(result)
    end

    private

    attr_reader :params, :user

    def update_user_profile
      update_attributes = {}

      update_attributes[:profile_picture] = params["profile_picture"] if params["profile_picture"].present?

      return Success() if update_attributes.empty?

      if user.update(update_attributes)
        Success()
      else
        Failure(user.errors.full_messages)
      end
    end

    def build_updated_user_data
      user.reload

      response_data = {
        message: "Profile updated successfully",
        user: Api::V0::UserBlueprint.render_as_hash(user, view: :profile),
        updated_at: user.updated_at
      }

      Success(response_data)
    end
  end
end
