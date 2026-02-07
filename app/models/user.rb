# frozen_string_literal: true

class User < ApplicationRecord
  # File attachments
  include ImageUploader::Attachment.new(:profile_picture)
  include ImageUploader::Attachment.new(:verification_selfie)
  include ImageUploader::Attachment.new(:cnic_images, multiple: true)

  enum :admin_verification_status, { unverified: 0, pending: 1, verified: 2, rejected: 3 }
  enum :gender, { male: 0, female: 1 }
  enum :role, { seeker: 0, lister: 1 }

  validates :phone_number, presence: true, uniqueness: true
  validates :cnic_hash, uniqueness: true, allow_nil: true
  validates :full_name, presence: true, length: { minimum: 2, maximum: 100 }, if: :otp_verified?

  validate :pakistani_phone_number

  def fully_verified?
    full_name.present? &&
    cnic_hash.present? &&
    gender.present? &&
    admin_verification_status.verified?
  end

  def super_admin?
    ENV.fetch("GLOBAL_ADMIN_PHONE_NUMBERS", "").split(",").map(&:strip).include?(phone_number)
  end

  private

  def pakistani_phone_number
    PhoneNumberService.valid?(phone_number) || errors.add(:phone_number, "must be a valid Pakistani phone number") if phone_number.present?
  end
end
