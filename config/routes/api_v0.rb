# frozen_string_literal: true

namespace :api do
  namespace :v0 do
    namespace :auth do
      # Registration flow
      post "signup/send_otp", to: "signup#send_otp"
      post "signup/verify_otp", to: "signup#verify_otp"

      # Login flow
      post "signin/send_otp", to: "signin#send_otp"
      post "signin/verify_otp", to: "signin#verify_otp"

      # Session management
      delete "signout", to: "auth#signout"
      post "refresh", to: "auth#refresh"
    end
  end
end
