# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Api::V0::Otp", type: :request do
  describe "POST /api/v0/otp/send" do
    let(:valid_phone) { "+923001234567" }
    let(:invalid_phone) { "invalid_phone" }

    context "with valid phone number" do
      before do
        post "/api/v0/otp/send", params: { otp: { phone_number: valid_phone } }
      end

      it "returns success response" do
        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be(true)
        expect(json_response['data']).to have_key('message')
        expect(json_response['data']).to have_key('expires_in_minutes')
        expect(json_response['data']['message']).to include('sent')
      end

      it "sets API versioning headers" do
        expect(response.headers['X-API-Version']).to eq('v0')
        expect(response.headers['X-API-Media-Type']).to eq('application/vnd.roombridge.v0+json')
      end

      it "creates OTP record in database" do
        # Check that OTP was created
        otp = OtpCode.find_by(phone_number: valid_phone)
        expect(otp).to be_present
        expect(otp.code).to be_present
        expect(otp.code.length).to eq(6)
        expect(otp.expires_at).to be > Time.current
        expect(otp.consumed_at).to be_nil
      end
    end

    context "with invalid phone number" do
      before do
        post "/api/v0/otp/send", params: { otp: { phone_number: invalid_phone } }
      end

      it "returns unprocessable entity" do
        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be(false)
        expect(json_response['error']).to be_present
      end

      it "does not create OTP record" do
        expect(OtpCode.find_by(phone_number: invalid_phone)).to be_nil
      end
    end

    context "with missing phone number parameter" do
      before do
        post "/api/v0/otp/send", params: { otp: {} }
      end

      it "returns bad request" do
        expect(response).to have_http_status(:bad_request)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be(false)
        expect(json_response['error']).to be_present
      end
    end

    context "with malformed request" do
      before do
        post "/api/v0/otp/send", params: { invalid: "structure" }
      end

      it "returns bad request for missing otp parameter" do
        expect(response).to have_http_status(:bad_request)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be(false)
        expect(json_response['error']).to include('Missing required parameter: otp')
      end
    end

    context "rate limiting" do
      before do
        post "/api/v0/otp/send", params: { otp: { phone_number: valid_phone } }
      end

      it "allows multiple requests within limit" do
        3.times do |i|
          post "/api/v0/otp/send", params: { otp: { phone_number: "+92300123456#{i}" } }
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  describe "POST /api/v0/otp/verify" do
    let(:phone_number) { "+923001234567" }
    let(:valid_code) { "123456" }
    let(:invalid_code) { "654321" }

    context "with valid OTP code" do
      let!(:otp_record) do
        create(:otp_code,
          phone_number: phone_number,
          code: valid_code,
          expires_at: 10.minutes.from_now
        )
      end

      it "returns success response with tokens" do
        post "/api/v0/otp/verify", params: {
          otp: {
            phone_number: phone_number,
            code: valid_code
          }
        }

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be(true)
        expect(json_response['data']).to have_key('message')
        expect(json_response['data']).to have_key('verified_at')

        # Should return authentication tokens after successful verification
        expect(json_response['data']).to have_key('access_token')
        expect(json_response['data']).to have_key('refresh_token')
        expect(json_response['data']['access_token']).to be_present
        expect(json_response['data']['refresh_token']).to be_present
      end

      it "sets authorization header" do
        post "/api/v0/otp/verify", params: {
          otp: {
            phone_number: phone_number,
            code: valid_code
          }
        }

        json_response = JSON.parse(response.body)
        access_token = json_response['data']['access_token']

        expect(response.headers['Authorization']).to eq("Bearer #{access_token}")
      end

      it "sets auth cookies" do
        post "/api/v0/otp/verify", params: {
          otp: {
            phone_number: phone_number,
            code: valid_code
          }
        }

        expect(response.cookies['access_token']).to be_present
        expect(response.cookies['refresh_token']).to be_present
      end

      it "sets API versioning headers" do
        post "/api/v0/otp/verify", params: {
          otp: {
            phone_number: phone_number,
            code: valid_code
          }
        }

        expect(response.headers['X-API-Version']).to eq('v0')
        expect(response.headers['X-API-Media-Type']).to eq('application/vnd.roombridge.v0+json')
      end

      it "marks OTP as consumed" do
        post "/api/v0/otp/verify", params: {
          otp: {
            phone_number: phone_number,
            code: valid_code
          }
        }

        otp_record.reload
        expect(otp_record.consumed_at).to be_present
        expect(otp_record.consumed?).to be(true)
      end

      it "creates or finds user account" do
        post "/api/v0/otp/verify", params: {
          otp: {
            phone_number: phone_number,
            code: valid_code
          }
        }

        user = User.find_by(phone_number: phone_number)
        expect(user).to be_present
        expect(user.phone_number).to eq(phone_number)
      end

      it "creates refresh token for user" do
        post "/api/v0/otp/verify", params: {
          otp: {
            phone_number: phone_number,
            code: valid_code
          }
        }

        user = User.find_by(phone_number: phone_number)
        expect(user.refresh_tokens.count).to be > 0
      end
    end

    context "with invalid OTP code" do
      let!(:otp_record2) do
        create(:otp_code,
          phone_number: "+923009999999",
          code: "999999",
          expires_at: 10.minutes.from_now
        )
      end

      it "returns unprocessable entity" do
        post "/api/v0/otp/verify", params: {
          otp: {
            phone_number: otp_record2.phone_number,
            code: invalid_code
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be(false)
        expect(json_response['error']).to be_present
      end

      it "does not mark OTP as consumed" do
        post "/api/v0/otp/verify", params: {
          otp: {
            phone_number: otp_record2.phone_number,
            code: invalid_code
          }
        }

        otp_record2.reload
        expect(otp_record2.consumed_at).to be_nil
        expect(otp_record2.consumed?).to be(false)
      end

      it "does not set auth cookies" do
        post "/api/v0/otp/verify", params: {
          otp: {
            phone_number: otp_record2.phone_number,
            code: invalid_code
          }
        }

        expect(response.cookies['access_token']).to be_blank
        expect(response.cookies['refresh_token']).to be_blank
      end

      it "does not set authorization header" do
        post "/api/v0/otp/verify", params: {
          otp: {
            phone_number: otp_record2.phone_number,
            code: invalid_code
          }
        }

        expect(response.headers['Authorization']).to be_blank
      end
    end

    context "with expired OTP" do
      let!(:expired_otp) do
        create(:otp_code,
          phone_number: "+923008888888",
          code: "888888",
          expires_at: 1.minute.ago
        )
      end

      it "returns unprocessable entity" do
        post "/api/v0/otp/verify", params: {
          otp: {
            phone_number: expired_otp.phone_number,
            code: expired_otp.code
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be(false)

        # Error format is { "base" => ["OTP has expired. Please request a new OTP."] }
        expect(json_response['error']['base']).to include(match(/expired/i))
      end

      it "does not mark expired OTP as consumed" do
        post "/api/v0/otp/verify", params: {
          otp: {
            phone_number: expired_otp.phone_number,
            code: expired_otp.code
          }
        }

        expired_otp.reload
        expect(expired_otp.consumed_at).to be_nil
        expect(expired_otp.consumed?).to be(false)
      end
    end

    context "with already consumed OTP" do
      let!(:consumed_otp) do
        create(:otp_code,
          phone_number: "+923007777777",
          code: "777777",
          expires_at: 10.minutes.from_now,
          consumed_at: 5.minutes.ago
        )
      end

      it "returns unprocessable entity" do
        post "/api/v0/otp/verify", params: {
          otp: {
            phone_number: consumed_otp.phone_number,
            code: consumed_otp.code
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be(false)
        expect(json_response['error']).to be_present
      end
    end

    context "with non-existent phone number" do
      it "returns unprocessable entity" do
        post "/api/v0/otp/verify", params: {
          otp: {
            phone_number: "+923001111111",
            code: "123456"
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be(false)
        expect(json_response['error']).to be_present
      end
    end

    context "with missing required parameters" do
      it "returns bad request for missing otp parameter" do
        post "/api/v0/otp/verify", params: { invalid: "structure" }

        expect(response).to have_http_status(:bad_request)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be(false)
        expect(json_response['error']).to include('Missing required parameter: otp')
      end

      it "returns unprocessable entity for missing phone_number" do
        post "/api/v0/otp/verify", params: {
          otp: { code: valid_code }
        }

        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be(false)
        expect(json_response['error']).to be_present
      end

      it "returns unprocessable entity for missing code" do
        post "/api/v0/otp/verify", params: {
          otp: { phone_number: phone_number }
        }

        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be(false)
        expect(json_response['error']).to be_present
      end
    end

    context "rate limiting" do
      it "allows multiple verify requests within limit" do
        3.times do |i|
          # Create separate OTP for each attempt
          otp = create(:otp_code,
            phone_number: "+9230012345#{i.to_s.rjust(2, '0')}",
            code: "12345#{i}",
            expires_at: 10.minutes.from_now
          )

          post "/api/v0/otp/verify", params: {
            otp: {
              phone_number: otp.phone_number,
              code: otp.code
            }
          }
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end
end
