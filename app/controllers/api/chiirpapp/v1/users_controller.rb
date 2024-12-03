# frozen_string_literal: true

# app/controllers/api/chiirpapp/v1/users_controller.rb
module Api
  module Chiirpapp
    module V1
      class UsersController < ChiirpappApiController
        # (POST) send User password reset
        # /api/chiirpapp/v1/users/:user_id
        # api_chiirpapp_v1_path(:user_id)
        # api_chiirpapp_v1_url(:user_id)
        def password_reset
          @user.send_invitation

          render json: user_json, layout: false, status: :ok
        end

        # (GET) send User info
        # /api/chiirpapp/v1/users/:user_id
        # api_chiirpapp_v1_user_path(:user_id)
        # api_chiirpapp_v1_user_url(:user_id)
        def show
          render json: user_json, layout: false, status: :ok
        end

        # (PUT/PATCH) update User info
        # /api/chiirpapp/v1/users/:id
        # api_chiirpapp_v1_user_path(:id)
        # api_chiirpapp_v1_user_url(:id)
        def update
          @user.update(user_params)

          render json: user_json, layout: false, status: :ok
        end

        private

        def user_json
          @user.attributes.slice('firstname', 'lastname', 'phone', 'email').to_json
        end

        def user_params
          params.permit(:firstname, :lastname, :phone, :email)
        end
      end
    end
  end
end
