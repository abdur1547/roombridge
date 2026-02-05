# frozen_string_literal: true

class User < ApplicationRecord
  # File attachments
  include ImageUploader::Attachment.new(:profile_picture)
  include IdentityUploader::Attachment.new(:verification_selfie)
  include IdentityUploader::Attachment.new(:cnic_images, multiple: true)

  enum :admin_verification_status, { unverified: 0, pending: 1, verified: 2, rejected: 3 }
  enum :gender, { male: 0, female: 1 }
  enum :role, { seeker: 0, lister: 1 }

  validates :phone_number, presence: true, uniqueness: true
  validates :cnic, uniqueness: true, allow_nil: true
  validates :full_name, presence: true, length: { minimum: 2, maximum: 100 }, if: :otp_verified?
  validates :otp_code, length: { is: 6 }, allow_nil: true, numericality: { only_integer: true }

  validate :pakistani_phone_number

  # Security scopes
  scope :otp_not_expired, -> { where("otp_expires_at > ?", Time.current) }
  scope :otp_verified, -> { where(otp_verified: true) }
  scope :otp_pending, -> { where(otp_verified: false) }

  def fully_verified?
    full_name.present? &&
    cnic.present? &&
    gender.present? &&
    verification_selfie.present? &&
    cnic_images.present? &&
    admin_verification_status.verified? &&
    otp_verified?
  end

  def super_admin?
    ENV.fetch("GLOBAL_ADMIN_PHONE_NUMBERS", "").split(",").map(&:strip).include?(phone_number)
  end

  def has_profile_picture?
    profile_picture.present?
  end

  def verification_documents_complete?
    verification_selfie.present? && cnic_images.present?
  end

  def ready_for_verification?
    full_name.present? && cnic.present? && gender.present? && verification_documents_complete?
  end

  # Clean expired OTP codes
  def self.cleanup_expired_otps
    where("otp_expires_at < ?", Time.current).update_all(
      otp_code: nil,
      otp_expires_at: nil,
      otp_attempts: 0
    )
  end

  def otp_expired?
    otp_expires_at.nil? || otp_expires_at < Time.current
  end

  def otp_attempts_exceeded?
    otp_attempts >= 3
  end

  private

  def pakistani_phone_number
    return if phone_number.blank?

    num = phone_number.gsub(/\s|-|\(|\)/, "")

    normalized =
      if num.start_with?("03")
        "+92" + num[1..]
      elsif num.start_with?("923")
        "+" + num
      elsif num.start_with?("+923")
        num
      else
        num
      end

    unless normalized.match?(/\A\+923\d{9}\z/)
      errors.add(:phone_number, "must be a valid Pakistani mobile number")
    else
      self.phone_number = normalized
    end
  end
end
