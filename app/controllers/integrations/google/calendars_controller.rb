# frozen_string_literal: true

# app/controllers/integrations/google/calendars_controller.rb
module Integrations
  module Google
    class CalendarsController < Google::IntegrationsController
      # (GET) Google Calendar dashboard integration configuration screen
      # /integrations/google/calendars/edit
      # edit_integrations_google_calendars_path
      # edit_integrations_google_calendars_url
      def edit
        respond_to do |format|
          format.js { render partial: 'integrations/google/js/show', locals: { cards: %w[calendars_edit] } }
          format.html { redirect_to integrations_google_integrations_path }
        end
      end

      # (PATCH/PUT) save Google calendar ids selected to be displayed
      # /integrations/google/calendars
      # integrations_google_calendars_path
      # integrations_google_calendars_url
      def update
        @user_api_integration.update(params_dashboard_calendar_ids)

        respond_to do |format|
          format.js { render partial: 'integrations/google/js/show', locals: { cards: %w[calendars_edit] } }
          format.html { redirect_to integrations_google_integrations_path }
        end
      end

      private

      def params_dashboard_calendar_ids
        sanitized_params = params.require(:user_api_integration).permit(:calendar_colors, dashboard_calendars: [])
        response         = { dashboard_calendars: [] }

        sanitized_params[:calendar_colors] = JSON.parse(sanitized_params[:calendar_colors]) if sanitized_params.include?(:calendar_colors)

        if sanitized_params.include?(:dashboard_calendars) && sanitized_params.include?(:calendar_colors)

          sanitized_params[:dashboard_calendars].reject(&:empty?).each do |calendar|
            dashboard_calendar_color = sanitized_params[:calendar_colors].find { |dc| dc[:id] == calendar } || {}
            response[:dashboard_calendars] << { id: calendar, background_color: dashboard_calendar_color.dig(:background_color), foreground_color: dashboard_calendar_color.dig(:foreground_color) }
          end
        end

        response
      end
    end
  end
end
