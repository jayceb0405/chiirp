# frozen_string_literal: true

# app/controllers/api/chiirpapp/v1/settings_controller.rb
module Api
  module Chiirpapp
    module V1
      class SettingsController < ChiirpappApiController
        before_action :user_settings

        # (GET) User Settings for ChiirpApp
        # /api/chiirpapp/v1/user/:user_id/settings
        # api_chiirpapp_v1_user_settings_path(:user_id)
        # api_chiirpapp_v1_user_settings_url(:user_id)
        def show
          if @user_settings.new_record?
            @user_settings.update(data: {
                                    include_automated: false,
                                    show_user_ids:     ['0']
                                  })
          end

          users = if @user.access_controller?('central', 'all_contacts', session)

                    if @user.client.agency_access && @user.agent?
                      @user.users_for_active_contacts(all_users: true, agent: true)
                    else
                      @user.users_for_active_contacts(all_users: true)
                    end
                  else
                    @user.users_for_active_contacts
                  end

          response = {
            include_automated: @user_settings.data.dig(:include_automated).to_bool,
            show_user_ids:     @user_settings.data.dig(:show_user_ids),
            agent:             @user.agent?,
            all_users:         users
          }

          render json: response.to_json, layout: false, status: :ok
        end

        # (PUT/PATCH) User Settings for ChiirpApp
        # /api/chiirpapp/v1/user/:user_id/settings
        # api_chiirpapp_v1_user_settings_path(:user_id)
        # api_chiirpapp_v1_user_settings_url(:user_id)
        def update
          sanitized_params = params_user_settings

          @user_settings.data[:include_automated] = sanitized_params[:include_automated].to_bool if sanitized_params.include?(:include_automated)
          @user_settings.data[:show_user_ids]     = sanitized_params[:show_user_ids] if sanitized_params.include?(:show_user_ids)
          @user_settings.save

          render json: { message: 'Success' }, layout: false, status: :ok
        end

        private

        def params_user_settings
          params.permit(:include_automated, show_user_ids: [])
        end
      end
    end
  end
end
