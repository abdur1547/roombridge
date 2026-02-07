# frozen_string_literal: true

class PhoneNumberService < BaseService
  def self.normalize(phone_number)
    return nil if phone_number.blank?

    # Remove spaces, dashes, parentheses
    clean_number = phone_number.to_s.gsub(/\s|-|\(|\)/, "")

    # Pakistani phone number normalization
    if clean_number.start_with?("03")
      "+92" + clean_number[1..]
    elsif clean_number.start_with?("923")
      "+" + clean_number
    elsif clean_number.start_with?("+923")
      clean_number
    else
      nil
    end
  end

  def self.valid?(phone_number)
    normalized = normalize(phone_number)
    return false if normalized.nil?

    # Pakistani mobile numbers are +92 followed by 10 digits
    normalized.match?(/\A\+92\d{11}\z/)
  end
end
