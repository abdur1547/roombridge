# frozen_string_literal: true

module Api::V0::Listing
  class IndexOperation < BaseOperation
    def call
      listings = yield fetch_active_listings
      result = yield build_response_data(listings)

      Success(result)
    end

    private

    def fetch_active_listings
      listings = Listing.where(is_active: true)
                        .order(created_at: :desc)

      Success(listings)
    end

    def build_response_data(listings)
      response_data = {
        listings: listings.as_json,
        count: listings.count
      }

      Success(response_data)
    end
  end
end
