class Listing < ApplicationRecord
  include ImageUploader::Attachment(:photos)

  belongs_to :user

  enum :room_type, {
    private_room: 0,
    shared_room: 1
  }

  enum :gender_preference, {
    male: 0,
    female: 1,
    any: 2
  }

  validates :user_id, presence: true
  validates :city, presence: true
  validates :area, presence: true
  validates :room_type, presence: true
  validates :max_occupants, presence: true, numericality: { greater_than: 0 }
  validates :rent_monthly, presence: true, numericality: { greater_than: 0 }
  validates :deposit, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :available_from, presence: true
  validates :minimum_stay_months, presence: true, numericality: { greater_than: 0 }
  validates :gender_preference, presence: true
  validates :furnished, inclusion: { in: [ true, false ] }
  validates :smoking_allowed, inclusion: { in: [ true, false ] }
  validates :is_active, inclusion: { in: [ true, false ] }
end
