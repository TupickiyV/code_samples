# frozen_string_literal: true

require "rails_helper"

RSpec.describe Commands::CreateEmailVerificationCommand do
  subject(:command) { described_class.new(parsed_params: parsed_params) }

  describe "#execute" do
    context "execute command with valid params" do
      let!(:params) { { email: Faker::Internet.email, guid: Faker::IDNumber.valid } }
      let!(:parsed_params) { ActionController::Parameters.new(params) }

      it "should return true" do
        expect(command.execute).to eq true
      end

      it "should send email with verification" do
        command.execute
        expect(ActionMailer::Base.deliveries.map(&:subject)).to include("ACTION REQUIRED: Please Verify Your Account Email Address").at_least(1).times
      end

      it "results should be present" do
        command.execute
        expect(command.results).to eq { message: :sent }
      end

      it "should create new EmailVerification" do
        expect { command.execute }.to change { EmailVerification.count }
      end

    end

    context "execute command with invalid params" do
      let!(:invalid_params) { { email: "", guid: Faker::IDNumber.valid } }
      let!(:parsed_params) { ActionController::Parameters.new(invalid_params) }

      it "should return false" do
        expect(command.execute).to eq false
      end

      it "errors should not be blank" do
        command.execute
        expect(command.errors).to eq([{ message: "Incorrect email" }])
      end

      it "should not create new EmailVerification" do
        expect { command.execute }.not_to change { EmailVerification.count }
      end
    end
  end
end

