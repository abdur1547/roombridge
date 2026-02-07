# frozen_string_literal: true

module Api::V0::User
  class ShowOperation < BaseOperation
    def call(user:)
      @user = user

      result = yield build_user_profile_data

      Success(result)
    end

    private

    attr_reader :user

    def build_user_profile_data
      blueprint_data = Api::V0::UserBlueprint.render_as_hash(user, view: :profile)

      Success(blueprint_data)
    end
  end
end
