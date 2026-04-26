# frozen_string_literal: true

module Api::V0::Listing
  class CreateOperation < BaseOperation
    contract do
      params do
        required(:city).filled(:string)
        required(:area).filled(:string)
        required(:room_type).filled(:integer)
        required(:max_occupants).filled(:integer, gt?: 0)
        required(:rent_monthly).filled(:integer, gt?: 0)
        optional(:deposit).maybe(:integer, gteq?: 0)
        required(:available_from).filled(:date)
        required(:minimum_stay_months).filled(:integer, gt?: 0)
        required(:gender_preference).filled(:integer)
        optional(:furnished).maybe(:bool)
        optional(:smoking_allowed).maybe(:bool)
      end
    end

    def call(user:, **params)
      @params = params
      @user = user

      listing = yield create_listing
      result = yield build_response_data(listing)

      Success(result)
    end

    private

    attr_reader :params, :user

    def create_listing
      listing_params = params.merge(user: user)
      listing = Listing.new(listing_params)

      if listing.save
        Success(listing)
      else
        Failure(listing.errors.full_messages)
      end
    end

    def build_response_data(listing)
      response_data = {
        message: "Listing created successfully",
        listing: listing.as_json,
        created_at: listing.created_at
      }

      Success(response_data)
    end
  end
end
