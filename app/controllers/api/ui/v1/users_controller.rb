# frozen_string_literal: true

# app/controllers/api/ui/v1/users_controller.rb
module Api
  module Ui
    module V1
      class UsersController < Api::Ui::V1::BaseController
        def me
        end

        def legacy
          sign_in current_user
          render json: { location: after_sign_in_path_for(current_user) }
        end

        # (GET) provide JSON data for a collection of users
        # /api/ui/v1/users
        # api_ui_v1_users_path
        # api_ui_v1_users_url
        def index
          case params[:use_case]
          when 'dashboard'
            if current_user.access_controller?('dashboard', 'all_contacts', session)
              render json: User.select(:id, :firstname, :lastname, :phone, :email, :created_at, :updated_at).where(client_id: current_user.client_id)
            else
              render json: User.select(:id, :firstname, :lastname, :phone, :email, :created_at, :updated_at).where(client_id: current_user.client_id, user_id: current_user.id)
            end
          end
        end
      end
    end
  end
end
