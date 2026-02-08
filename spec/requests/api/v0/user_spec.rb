# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Api::V0::User", type: :request do
  let(:user) { create(:user, :fully_verified) }
  let(:headers) { authenticate_user(user) }

  def json
    JSON.parse(response.body)
  end

  describe "GET /api/v0/user" do
    subject { get "/api/v0/user", headers: }

    context "when authenticated" do
      it "returns user profile successfully" do
        subject

        expect(response).to have_http_status(:ok)
        expect(json["success"]).to be(true)
        expect(json["data"]).to be_present
      end

      it "includes user profile data" do
        subject

        user_data = json["data"]
        expect(user_data["masked_phone_number"]).to be_present
        expect(user_data["full_name"]).to eq(user.full_name)
        expect(user_data["admin_verification_status"]).to eq(user.admin_verification_status)
      end
    end

    context "when not authenticated" do
      let(:headers) { {} }

      it "returns 401 unauthorized" do
        subject

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when token is invalid" do
      let(:headers) { { 'Authorization' => 'Bearer invalid_token' } }

      it "returns 401 unauthorized" do
        subject

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "PATCH /api/v0/user" do
    subject { patch "/api/v0/user", params:, headers: }

    context "when authenticated" do
      context "with valid profile picture" do
        let(:profile_picture) { fixture_file_upload("spec/fixtures/files/valid_profile.jpg", "image/jpeg") }
        let(:params) { { profile_picture: } }

        it "updates user profile successfully" do
          subject

          expect(response).to have_http_status(:ok)
          expect(json["success"]).to be(true)
          expect(json["data"]["message"]).to eq("Profile updated successfully")
        end

        it "updates the user's profile picture" do
          expect { subject }.to change { user.reload.profile_picture.present? }.from(false).to(true)
        end

        it "returns updated user data" do
          subject

          user_data = json["data"]["user"]
          expect(user_data["masked_phone_number"]).to be_present
          expect(json["data"]["updated_at"]).to be_present
        end
      end

      context "with invalid profile picture" do
        let(:invalid_file) { fixture_file_upload("spec/fixtures/files/invalid.txt", "text/plain") }
        let(:params) { { profile_picture: invalid_file } }

        # it "returns validation error" do
        #   subject

        #   expect(response).to have_http_status(:unprocessable_entity)
        #   expect(json["success"]).to be(false)
        #   expect(json["error"]).to be_present
        # end

        it "does not update the user" do
          expect { subject }.not_to change { user.reload.updated_at }
        end
      end

      context "with empty params" do
        let(:params) { {} }

        it "returns success with no changes" do
          subject

          expect(response).to have_http_status(:ok)
          expect(json["success"]).to be(true)
        end
      end

      context "with nil profile picture" do
        let(:params) { { profile_picture: nil } }

        it "returns success with no changes" do
          subject

          expect(response).to have_http_status(:ok)
          expect(json["success"]).to be(true)
        end
      end
    end

    context "when not authenticated" do
      let(:headers) { {} }
      let(:params) { {} }

      it "returns 401 unauthorized" do
        subject

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/v0/user/upload_verification_documents" do
    subject { post "/api/v0/user/upload_verification_documents", params:, headers: }

    context "when authenticated" do
      context "with valid CNIC images" do
        let(:cnic_images) { fixture_file_upload("spec/fixtures/files/valid_cnic1.jpg", "image/jpeg") }
        let(:params) { { cnic_images: } }

        it "uploads CNIC images successfully" do
          subject

          expect(response).to have_http_status(:ok)
          expect(json["success"]).to be(true)
        end

        it "updates the user's CNIC images" do
          expect { subject }.to change { user.reload.cnic_images.present? }.from(false).to(true)
        end
      end

      context "with valid verification selfie" do
        let(:verification_selfie) { fixture_file_upload("spec/fixtures/files/valid_selfie.jpg", "image/jpeg") }
        let(:params) { { verification_selfie: } }

        it "uploads verification selfie successfully" do
          subject

          expect(response).to have_http_status(:ok)
          expect(json["success"]).to be(true)
        end

        it "updates the user's verification selfie" do
          expect { subject }.to change { user.reload.verification_selfie.present? }.from(false).to(true)
        end
      end

      context "with both CNIC images and verification selfie" do
        let(:cnic_images) { fixture_file_upload("spec/fixtures/files/valid_cnic1.jpg", "image/jpeg") }
        let(:verification_selfie) { fixture_file_upload("spec/fixtures/files/valid_cnic2.jpg", "image/jpeg") }
        let(:params) { { cnic_images:, verification_selfie: } }

        it "uploads both documents successfully" do
          subject

          expect(response).to have_http_status(:ok)
          expect(json["success"]).to be(true)
        end

        it "updates both user documents" do
          subject
          user.reload

          expect(user.cnic_images).to be_present
          expect(user.verification_selfie).to be_present
        end
      end

      # context "with invalid file types" do
      #   let(:invalid_file) { fixture_file_upload("spec/fixtures/files/invalid.txt", "text/plain") }
      #   let(:params) { { cnic_images: invalid_file } }

      #   it "returns validation error" do
      #     subject

      #     expect(response).to have_http_status(:unprocessable_entity)
      #     expect(json["success"]).to be(false)
      #     expect(json["error"]).to be_present
      #   end

      #   it "does not update the user" do
      #     expect { subject }.not_to change { user.reload.updated_at }
      #   end
      # end

      context "with no files provided" do
        let(:params) { {} }

        it "returns validation error" do
          subject

          expect(response).to have_http_status(:unprocessable_entity)
          expect(json["success"]).to be(false)
          expect(json["error"]).to be_an(Array)
          expect(json["error"]).to include("At least one verification document must be provided")
        end
      end

      context "with empty file parameters" do
        let(:params) { { cnic_images: nil, verification_selfie: nil } }

        it "returns validation error" do
          subject

          expect(response).to have_http_status(:unprocessable_entity)
          expect(json["success"]).to be(false)
          expect(json["error"]).to be_an(Array)
          expect(json["error"]).to include("At least one verification document must be provided")
        end
      end
    end

    context "when not authenticated" do
      let(:headers) { {} }
      let(:params) { {} }

      it "returns 401 unauthorized" do
        subject

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when token is invalid" do
      let(:headers) { { 'Authorization' => 'Bearer invalid_token' } }
      let(:params) { {} }

      it "returns 401 unauthorized" do
        subject

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
