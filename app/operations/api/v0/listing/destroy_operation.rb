# frozen_string_literal: true

module Api::V0::Listing
  class DestroyOperation < BaseOperation
    def call(listing:, user:)
      @listing = listing
      @user = user

      yield soft_delete_listing

      Success(true)
    end

    private

    attr_reader :listing, :user

    def soft_delete_listing
      if listing.update(is_active: false)
        Success()
      else
        Failure(listing.errors.full_messages)
      end
    end
  end
end
