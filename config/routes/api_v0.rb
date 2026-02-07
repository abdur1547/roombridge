# frozen_string_literal: true

namespace :api do
  namespace :v0 do
    # Session management
    delete "auth/signout", to: "auth#signout"
    post "auth/refresh", to: "auth#refresh"

    # OTP endpoints
    post "otp/send", to: "otp#send_otp"
    post "otp/verify", to: "otp#verify_otp"
  end
end
