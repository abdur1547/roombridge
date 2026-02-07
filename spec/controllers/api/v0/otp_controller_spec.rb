require 'rails_helper'

RSpec.describe Api::V0::OtpController, type: :controller do
  describe 'POST #send_otp' do
    let(:valid_params) do
      { otp: { phone_number: '+923001234567' } }
    end

    let(:invalid_params) do
      { otp: { phone_number: 'invalid' } }
    end

    context 'with valid phone number' do
      it 'returns success response' do
        post :send_otp, params: valid_params

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['success']).to be true
        expect(JSON.parse(response.body)['data']).to include('message', 'expires_in_minutes')
      end

      it 'creates OTP record' do
        expect {
          post :send_otp, params: valid_params
        }.to change(OtpCode, :count).by(1)

        otp = OtpCode.last
        expect(otp.phone_number).to eq('+923001234567')
        expect(otp.code).to be_present
        expect(otp.expires_at).to be > Time.current
      end
    end

    context 'with invalid phone number' do
      it 'returns error response' do
        post :send_otp, params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['success']).to be false
        expect(JSON.parse(response.body)['errors']).to be_present
      end
    end
  end

  describe 'POST #verify_otp' do
    let!(:otp_code) do
      OtpCode.create!(
        phone_number: '+923001234567',
        code: '123456',
        expires_at: 10.minutes.from_now
      )
    end

    let(:valid_params) do
      { otp: { phone_number: '+923001234567', code: '123456' } }
    end

    let(:invalid_code_params) do
      { otp: { phone_number: '+923001234567', code: '654321' } }
    end

    context 'with valid OTP code' do
      it 'returns success response' do
        post :verify_otp, params: valid_params

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['success']).to be true
        expect(JSON.parse(response.body)['data']).to include('message', 'verified_at')
      end

      it 'marks OTP as consumed' do
        post :verify_otp, params: valid_params

        otp_code.reload
        expect(otp_code.consumed?).to be true
      end
    end

    context 'with invalid OTP code' do
      it 'returns error response' do
        post :verify_otp, params: invalid_code_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['success']).to be false
      end

      it 'does not mark OTP as consumed' do
        post :verify_otp, params: invalid_code_params

        otp_code.reload
        expect(otp_code.consumed?).to be false
      end
    end

    context 'with expired OTP' do
      before { otp_code.update!(expires_at: 1.minute.ago) }

      it 'returns error response' do
        post :verify_otp, params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['errors']['base']).to include(match(/expired/i))
      end
    end
  end
end
