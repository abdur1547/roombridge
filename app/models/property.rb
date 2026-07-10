class Property < ApplicationRecord
  enum property_type: { apartment: 0, house: 1 }
  enum :gender_preference, { any: 0, male: 1, female: 2 }

  belongs_to :owner, class_name: "User", foreign_key: "owner_id"
  has_many :listings, dependent: :destroy

  validates :property_type, presence: true
  validates :city, presence: true
  validates :area, presence: true
  validates :address, presence: true
  validates :total_bedrooms, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :total_bathrooms, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :parking, inclusion: { in: [ true, false ] }
  validates :only_verified_users, inclusion: { in: [ true, false ] }
  validates :elevator, inclusion: { in: [ true, false ] }
end
