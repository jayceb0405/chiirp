# frozen_string_literal: true

# app/controllers/api/chiirpapp/v1/chiirpapp_api_controller.rb
module Api
  module Chiirpapp
    module V1
      # rubocop:disable Rails/ApplicationController
      class ChiirpappApiController < ActionController::Base
        # rubocop:enable Rails/ApplicationController
        skip_before_action :verify_authenticity_token
        before_action :authorize_chiirpapp!
        before_action :user
        before_action :authorize_user!

        private

        def authorize_chiirpapp!
          render json: { message: 'Unauthorized' }, layout: false, status: :unauthorized and return false unless credentials_approved?
        end

        def authorize_user!
          render json: { message: 'User Suspended' }, layout: false, status: :unauthorized and return false if @user.suspended?
          render json: { message: 'Client Inactive' }, layout: false, status: :unauthorized and return false unless @user.client.active?
        end

        def basic_auth
          Base64.encode64("#{Rails.application.credentials[:chiirpapp][:api_key]}:#{Rails.application.credentials[:chiirpapp][:secret]}")
        end

        def contact
          render json: { message: 'Contact Not Found' }, layout: false, status: :not_found and return false unless (@contact = @user.client.contacts.find_by(id: params.permit(:contact_id).dig(:contact_id)))
        end

        def credentials_approved?
          decoded_credentials = Base64.decode64(request.headers[:Authorization][6..]).split(':')
          decoded_credentials.first == Rails.application.credentials[:chiirpapp][:api_key] && decoded_credentials.last == Rails.application.credentials[:chiirpapp][:secret]
        end

        def twnumber
          render json: { message: 'Phone Number Not Found' }, layout: false, status: :not_found and return false unless (@twnumber = @user.client.twnumbers.find_by(phonenumber: params.permit(:phone_number).dig(:phone_number)))
        end

        def user
          render json: { message: 'User Not Found' }, layout: false, status: :not_found and return false unless (@user = User.find_by(id: params.permit(:user_id).dig(:user_id)))
        end

        def user_settings
          render json: { message: 'User Settings Not Found' }, layout: false, status: :not_found and return false unless (@user_settings = @user.user_settings.find_or_initialize_by(controller_action: 'chiirpapp_message_central', name: ''))
        end
      end
    end
  end
end
