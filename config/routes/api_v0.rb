# frozen_string_literal: true

namespace :api do
  namespace :v0 do
    namespace :auth do
      # Session management
      delete "signout", to: "auth#signout"
      post "refresh", to: "auth#refresh"
    end

    # OTP endpoints
    post "otp/send", to: "otp#send_otp"
    post "otp/verify", to: "otp#verify_otp"
  end
end
