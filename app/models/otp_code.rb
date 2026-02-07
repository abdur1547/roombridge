class OtpCode < ApplicationRecord
  validates :phone_number, presence: true
  validates :code, presence: true
  validates :expires_at, presence: true
  validates_uniqueness_of [ :phone_number, :code ], message: "OTP code for this phone number already exists"

  def consumed?
    consumed_at.present?
  end

  def expired?
    Time.current > expires_at
  end
end
