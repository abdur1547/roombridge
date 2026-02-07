# frozen_string_literal: true

module Api::V0
  class OtpController < ApiController
    skip_before_action :authenticate_user!

    def send_otp
      result = Api::V0::Otp::SendOtpOperation.call(otp_send_params.to_h)

      if result.success?
        success_response(result.value)
      else
        unprocessable_entity(result.errors_hash)
      end
    end

    def verify_otp
      result = Api::V0::Otp::VerifyOtpOperation.call(otp_verify_params.to_h)

      if result.success?
        success_response(result.value)
      else
        unprocessable_entity(result.errors_hash)
      end
    end

    private

    def otp_send_params
      params.require(:otp).permit(:phone_number)
    end

    def otp_verify_params
      params.require(:otp).permit(:phone_number, :code)
    end
  end
end
