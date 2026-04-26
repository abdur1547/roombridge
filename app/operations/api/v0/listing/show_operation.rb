# frozen_string_literal: true

module Api::V0::Listing
  class ShowOperation < BaseOperation
    def call(listing:, user: nil)
      @listing = listing
      @user = user

      yield check_listing_visibility
      result = yield build_response_data

      Success(result)
    end

    private

    attr_reader :listing, :user

    def check_listing_visibility
      # Show inactive listings only to their owners
      if !listing.is_active? && (!user || listing.user != user)
        Failure("Listing not found")
      else
        Success()
      end
    end

    def build_response_data
      response_data = {
        listing: listing.as_json
      }

      Success(response_data)
    end
  end
end
