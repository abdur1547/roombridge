# frozen_string_literal: true

module Api::V0::Listing
  class UpdateOperation < BaseOperation
    contract do
      params do
        optional(:city).maybe(:string)
        optional(:area).maybe(:string)
        optional(:room_type).maybe(:integer)
        optional(:max_occupants).maybe(:integer, gt?: 0)
        optional(:rent_monthly).maybe(:integer, gt?: 0)
        optional(:deposit).maybe(:integer, gteq?: 0)
        optional(:available_from).maybe(:date)
        optional(:minimum_stay_months).maybe(:integer, gt?: 0)
        optional(:gender_preference).maybe(:integer)
        optional(:furnished).maybe(:bool)
        optional(:smoking_allowed).maybe(:bool)
        optional(:is_active).maybe(:bool)
      end
    end

    def call(listing:, user:, **params)
      @params = params
      @listing = listing
      @user = user

      yield update_listing
      result = yield build_response_data

      Success(result)
    end

    private

    attr_reader :params, :listing, :user

    def update_listing
      # Filter out empty params
      update_attributes = params.reject { |_, v| v.nil? }

      return Success() if update_attributes.empty?

      if listing.update(update_attributes)
        Success()
      else
        Failure(listing.errors.full_messages)
      end
    end

    def build_response_data
      listing.reload

      response_data = {
        message: "Listing updated successfully",
        listing: listing.as_json,
        updated_at: listing.updated_at
      }

      Success(response_data)
    end
  end
end
