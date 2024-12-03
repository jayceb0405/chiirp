# frozen_string_literal: true

# app/controllers/api/ui/v1/dashboard_controller.rb
module Api
  module Ui
    module V1
      class DashboardController < Api::Ui::V1::BaseController
        before_action :user_settings, only: %i[attributes automations metric]

        # (GET/PUT) get/update the user's dashboard settings
        # /api/ui/v1/dashboard/attributes
        # attributes_api_ui_v1_dashboard_index_path
        # attributes_api_ui_v1_dashboard_index_url
        def attributes
          if request.get?
            render json: {
              timeframe: @user_settings.data.dig(:timeframe).to_s,
              user_id:   @user_settings.data.dig(:user_ids)&.first.to_i
            }
          elsif request.put?
            update_attributes

            render json: { status: :ok }
          end
        end

        # (GET) provide JSON data for a collection of automations
        # /api/ui/v1/dashboard/automations
        # automations_api_ui_v1_dashboard_index_path
        # automations_api_ui_v1_dashboard_index_url
        def automations
          update_automations

          render json: Users::Dashboards::Dashboard.new.automations(@user_settings)
        end

        # (GET) provide JSON data for a single metric
        # /api/ui/v1/dashboard/:id/metric
        # metric_api_ui_v1_dashboard_path(:id)
        # metric_api_ui_v1_dashboard_url(:id)
        def metric
          render json: Users::Dashboards::Dashboard.new.dashboard_button(params.permit(:id).dig(:id), @user_settings)
        end

        # (GET) provide JSON data for a collection of metrics
        # /api/ui/v1/dashboard/metrics
        # metrics_api_ui_v1_dashboard_index_path
        # metrics_api_ui_v1_dashboard_index_url
        def metrics
          render json: [
            {
              name:        'Contacts Messaged',
              description: "# Contacts text messaged through #{I18n.t('tenant.name')}",
              id:          'messages_contacts_messaged',
              isHeadLine:  true,
              units:       'contacts'
            },
            {
              name:        'Team Response Time',
              description: 'Avg incoming text response time (business hours)',
              id:          'messages_team_response_time',
              isHeadLine:  true,
              units:       'mins'
            },
            {
              name:        'Delivery Rate',
              description: '% of text messages delivered by carriers',
              id:          'messages_delivery_rate',
              isHeadLine:  true,
              units:       'percentage'
            }
          ]
        end

        private

        def update_attributes
          sanitized_params = params.permit(:timeframe, :user_id)

          @user_settings.update(data: @user_settings.data.merge({
                                                                  timeframe: (sanitized_params[:timeframe].presence || @user_settings.data.dig(:timeframe)).to_s,
                                                                  user_ids:  [(sanitized_params[:user_id].presence || @user_settings.data.dig(:user_ids)&.first).to_i]
                                                                }))
        end

        def update_automations
          sanitized_params = params.permit(:order_column, :order_direction, :page, :page_size)

          sanitized_params[:order_column]    = Users::Dashboards::Dashboard::DASHBOARD_AUTOMATIONS_COLUMNS.to_h.values.include?(sanitized_params[:order_column].to_s) ? sanitized_params[:order_column].to_s : @user_settings.data.dig(:automations, :order_column)
          sanitized_params[:order_direction] = %w[asc desc].include?(sanitized_params[:order_direction].to_s.downcase) ? sanitized_params[:order_direction].to_s.downcase : @user_settings.data.dig(:automations, :order_direction)
          sanitized_params[:page]            = sanitized_params[:page].to_i.positive? ? sanitized_params[:page].to_i : @user_settings.data.dig(:automations, :page)
          sanitized_params[:page_size]       = sanitized_params[:page_size].to_i.positive? ? sanitized_params[:page_size].to_i : @user_settings.data.dig(:automations, :page_size)

          @user_settings.update(data: @user_settings.data.merge({
                                                                  automations: {
                                                                    order_column:    sanitized_params[:order_column],
                                                                    order_direction: sanitized_params[:order_direction],
                                                                    page:            sanitized_params[:page],
                                                                    page_size:       sanitized_params[:page_size]
                                                                  }
                                                                }))
        end

        def user_settings
          @user_settings = current_user.user_settings.find_or_initialize_by(controller_action: 'dashboard_newui', current: 1)
          user_settings_initialize if @user_settings.new_record?
        end

        def user_settings_initialize
          @user_settings.update(
            name: 'My Dashboard',
            data: {
              timeframe:   'td',
              user_ids:    [current_user.id],
              automations: {
                order_column:    'last_started',
                order_direction: 'asc',
                page:            1,
                page_size:       15
              }
            }
          )
        end
      end
    end
  end
end
