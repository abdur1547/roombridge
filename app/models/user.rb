# frozen_string_literal: true

class User < ApplicationRecord
  enum :admin_verification_status, { unverified: 0, pending: 1, verified: 2, rejected: 3 }
  enum :gender, { male: 0, female: 1 }
  enum :role, { seeker: 0, lister: 1 }

  validates :phone_number, presence: true, uniqueness: true
  validates :cnic, uniqueness: true, allow_nil: true
  validate :pakistani_phone_number

  def fully_verified?
    full_name.present? && cnic.present? && gender.present? && admin_verification_status.verified?
  end

  def super_admin?
    ENV.fetch("GLOBAL_ADMIN_PHONE_NUMBERS", "").split(",").map(&:strip).include?(phone_number)
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
