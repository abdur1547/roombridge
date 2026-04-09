# frozen_string_literal: true

module Api::V0
  class ListingsController < Api::V0::ApiController
    skip_before_action :authenticate_user!, only: [ :index, :show ]

    def create
      result = Api::V0::Listing::CreateOperation.call(user: current_user, **listing_params.to_h.symbolize_keys)

      if result.success?
        success_response(result.value, :created)
      else
        unprocessable_entity(result.errors_hash)
      end
    end

    def index
      result = Api::V0::Listing::IndexOperation.call

      if result.success?
        success_response(result.value)
      else
        unprocessable_entity(result.errors_hash)
      end
    end

    def show
      result = Api::V0::Listing::ShowOperation.call(listing: @listing, user: current_user)

      if result.success?
        success_response(result.value)
      else
        unprocessable_entity(result.errors_hash)
      end
    end

    def update
      result = Api::V0::Listing::UpdateOperation.call(listing: @listing, user: current_user, **listing_params.to_h.symbolize_keys)

      if result.success?
        success_response(result.value)
      else
        unprocessable_entity(result.errors_hash)
      end
    end

    def destroy
      result = Api::V0::Listing::DestroyOperation.call(listing: @listing, user: current_user)

      if result.success?
        success_response(nil)
      else
        unprocessable_entity(result.errors_hash)
      end
    end

    private

    def listing_params
      permitted_fields = [
        :city, :area, :room_type, :max_occupants, :rent_monthly, :deposit,
        :available_from, :minimum_stay_months, :gender_preference, :furnished,
        :smoking_allowed
      ]

      # Only allow is_active if user is the owner
      permitted_fields << :is_active if @listing&.user == current_user

      params.require(:listing).permit(permitted_fields)
    end
  end
end
