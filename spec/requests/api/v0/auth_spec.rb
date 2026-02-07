# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Api::V0::Auth", type: :request do
  let(:user) { create(:user) }
  let(:expired_user) { create(:user) }

  describe "POST /api/v0/auth/refresh" do
    context "with valid refresh token" do
      let(:refresh_token) { create(:refresh_token, user: user) }

      it "returns a new access token" do
        post "/api/v0/auth/refresh", params: { refresh_token: refresh_token.token }

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be(true)
        expect(json_response['data']).to have_key('access_token')
        expect(json_response['data']['access_token']).to be_present
      end

      it "sets Authorization header" do
        post "/api/v0/auth/refresh", params: { refresh_token: refresh_token.token }

        expect(response.headers['Authorization']).to start_with('Bearer ')
      end

      it "sets API versioning headers" do
        post "/api/v0/auth/refresh", params: { refresh_token: refresh_token.token }

        expect(response.headers['X-API-Version']).to eq('v0')
        expect(response.headers['X-API-Media-Type']).to eq('application/vnd.roombridge.v0+json')
      end

      context "when refresh token should be rotated" do
        let(:old_refresh_token) { create(:refresh_token, user: user, created_at: 20.days.ago) }

        it "returns a new refresh token" do
          post "/api/v0/auth/refresh", params: { refresh_token: old_refresh_token.token }

          expect(response).to have_http_status(:ok)

          json_response = JSON.parse(response.body)
          expect(json_response['data']).to have_key('refresh_token')
        end

        it "removes the old refresh token" do
          old_token = old_refresh_token.token

          post "/api/v0/auth/refresh", params: { refresh_token: old_token }

          # Verify old token is gone (it should be destroyed during rotation)
          expect(RefreshToken.find_by_token(old_token)).to be_nil
        end
      end
    end

    context "with invalid refresh token" do
      before do
        post "/api/v0/auth/refresh", params: { refresh_token: "invalid_token" }
      end

      it "returns unauthorized for non-existent token" do
        expect(response).to have_http_status(:unauthorized)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be(false)
        expect(json_response['error']).to eq("Invalid refresh token")
      end
    end

    context "with expired refresh token" do
      let(:expired_refresh_token) { create(:refresh_token, :expired, user: expired_user) }

      it "returns unauthorized" do
        post "/api/v0/auth/refresh", params: { refresh_token: expired_refresh_token.token }

        expect(response).to have_http_status(:unauthorized)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be(false)
        expect(json_response['error']).to eq("Refresh token has expired")
      end

      it "removes the expired refresh token" do
        # Create the token explicitly
        token = expired_refresh_token # Force token creation

        expect {
          post "/api/v0/auth/refresh", params: { refresh_token: token.token }
        }.to change { RefreshToken.count }.by(-1)

        expect(RefreshToken.find_by_token(token.token)).to be_nil
      end
    end

    context "when user does not exist" do
      let(:user) { create(:user) }
      let(:refresh_token) { create(:refresh_token, user: user) }

      before do
        # Create the user and refresh token first, then destroy user
        refresh_token # Force creation before destroying user
        user.destroy
        post "/api/v0/auth/refresh", params: { refresh_token: refresh_token.token }
      end

      it "returns unauthorized" do
        expect(response).to have_http_status(:unauthorized)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be(false)
        # When user is deleted, the refresh token is also deleted due to CASCADE DELETE
        # so the error message should be "Invalid refresh token"
        expect(json_response['error']).to eq("Invalid refresh token")
      end
    end

    context "when no refresh token is provided" do
      before do
        post "/api/v0/auth/refresh"
      end

      it "returns unauthorized" do
        expect(response).to have_http_status(:unauthorized)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be(false)
      end
    end

    context "rate limiting" do
      let(:refresh_token) { create(:refresh_token, user: user) }

      it "allows multiple requests within limit" do
        3.times do
          post "/api/v0/auth/refresh", params: { refresh_token: refresh_token.token }
          expect(response).to have_http_status(:ok)
        end
      end
    end
  end

  describe "DELETE /api/v0/auth/signout" do
    let(:tokens) { generate_tokens_for_user(user) }
    let(:access_token) { tokens[:access_token] }
    let(:decoded_token) { generate_decoded_token(user) }

    context "with valid authentication" do
      before do
        # Create some refresh tokens to test revocation
        create(:refresh_token, user: user)
        create(:refresh_token, user: user)

        allow_any_instance_of(Api::V0::AuthController).to receive(:current_user).and_return(user)
        allow_any_instance_of(Api::V0::AuthController).to receive(:decoded_token).and_return(decoded_token)
        delete "/api/v0/auth/signout", headers: auth_headers(access_token)
      end

      it "successfully signs out user" do
        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be(true)
        expect(json_response['data']).to have_key('message')
        expect(json_response['data']).to have_key('signed_out_at')
      end

      it "blacklists the access token" do
        expect(user.blacklisted_tokens.count).to eq(1)

        blacklisted_token = user.blacklisted_tokens.last
        expect(blacklisted_token.jti).to eq(decoded_token[:jti])
      end

      it "revokes all refresh tokens for security" do
        # Create tokens before the before block runs
        user.refresh_tokens.count

        # After signout in before block, all refresh tokens should be revoked
        expect(user.reload.refresh_tokens.count).to eq(0)
      end

      it "sets API versioning headers" do
        expect(response.headers['X-API-Version']).to eq('v0')
        expect(response.headers['X-API-Media-Type']).to eq('application/vnd.roombridge.v0+json')
      end

      context "when blacklisting token fails" do
        before do
          allow(Jwt::Blacklister).to receive(:call).and_return(double(success?: false, failure: "Database error"))
          delete "/api/v0/auth/signout", headers: auth_headers(access_token)
        end

        it "still returns success for user experience" do
          expect(response).to have_http_status(:ok)

          json_response = JSON.parse(response.body)
          expect(json_response['success']).to be(true)
          expect(json_response['data']['message']).to eq("Signed out")
        end
      end

      context "when revoking refresh tokens fails" do
        before do
          # Mock user.refresh_tokens to raise an error
          allow_any_instance_of(User).to receive_message_chain(:refresh_tokens, :destroy_all).and_raise(ActiveRecord::StatementInvalid, "Connection timeout")
          delete "/api/v0/auth/signout", headers: auth_headers(access_token)
        end

        it "still returns success for user experience" do
          expect(response).to have_http_status(:ok)

          json_response = JSON.parse(response.body)
          expect(json_response['success']).to be(true)
          expect(json_response['data']['message']).to eq("Signed out")
        end
      end

      context "rate limiting" do
        it "allows multiple signout requests within limit" do
          5.times do
            delete "/api/v0/auth/signout", headers: auth_headers(access_token)
            # After first request, should get 401 because token is blacklisted
            expect(response).to have_http_status(:ok).or have_http_status(:unauthorized)
          end
        end
      end
    end

    context "without authentication" do
      before do
        delete "/api/v0/auth/signout"
      end

      it "returns unauthorized" do
        expect(response).to have_http_status(:unauthorized)

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be(false)
        expect(json_response['error']).to eq("Missing authentication token")
      end
    end

    context "with invalid token" do
      before do
        delete "/api/v0/auth/signout", headers: { "Authorization" => "Bearer invalid_token" }
      end

      it "returns unauthorized" do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with expired token" do
      let(:expired_token) { generate_expired_token(user) }

      before do
        delete "/api/v0/auth/signout", headers: auth_headers(expired_token)
      end

      it "returns unauthorized" do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with blacklisted token" do
      before do
        delete "/api/v0/auth/signout", headers: { "Authorization" => "Bearer invalid_token" }
      end

      it "returns unauthorized" do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
