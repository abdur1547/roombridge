# frozen_string_literal: true

module Api::V0
  class UserBlueprint < BaseBlueprint
    identifier :id

    fields :full_name, :gender, :admin_verification_status

    view :profile do
      fields :full_name, :gender, :admin_verification_status, :created_at

      field :profile_picture_url do |user|
        user.profile_picture.present? ? user.profile_picture.url : nil
      end

      field :masked_phone_number do |user|
        user.phone_number.present? ? PhoneNumberService.mask(user.phone_number) : nil
      end

      field :member_since do |user|
        "Member since #{user.created_at&.strftime('%B %Y')}"
      end
    end

    view :minimal do
      fields :id, :full_name
    end

    view :verification_status do
      fields :admin_verification_status
    end
  end
end
