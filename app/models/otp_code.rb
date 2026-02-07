class OtpCode < ApplicationRecord
  validates :phone_number, presence: true, format: { with: /\A\+?[1-9]\d{1,14}\z/, message: "Invalid phone number format" }
  validates :code, presence: true, length: { is: 6 }, numericality: { only_integer: true }
  validates :expires_at, presence: true

  scope :active, -> { where(consumed_at: nil).where("expires_at > ?", Time.current) }
  scope :for_phone, ->(phone) { where(phone_number: phone) }
  scope :expired, -> { where("expires_at <= ?", Time.current) }
  scope :consumed, -> { where.not(consumed_at: nil) }
  scope :recent, -> { where("created_at > ?", 24.hours.ago) }

  def consumed?
    consumed_at.present?
  end

  def expired?
    Time.current > expires_at
  end

  def valid_for_verification?
    !consumed? && !expired?
  end

  def consume!
    update!(consumed_at: Time.current)
  end

  def time_until_expiry
    return 0 if expired?

    ((expires_at - Time.current) / 1.minute).ceil
  end

  def self.cleanup_expired!
    expired.delete_all
  end

  def self.generate_code
    SecureRandom.random_number(100000..999999).to_s
  end

  def self.find_active_for_phone(phone_number)
    active.for_phone(phone_number).order(created_at: :desc).first
  end
end
