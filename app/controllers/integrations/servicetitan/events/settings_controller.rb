# frozen_string_literal: true

# app/controllers/integrations/servicetitan/events/settings_controller.rb
module Integrations
  module Servicetitan
    module Events
      class SettingsController < Servicetitan::EventsController
        before_action :client_api_integration_line_items, only: %i[line_items]

        # (GET) show ServiceTitan events form
        # /integrations/servicetitan/events/settings/edit
        # edit_integrations_servicetitan_events_settings_path
        # edit_integrations_servicetitan_events_settings_url
        def edit; end

        # (GET) update dropdown element with ServiceTitan line items from selected categories
        # /integrations/servicetitan/events/settings/line_items
        # integrations_servicetitan_events_settings_line_items_path
        # integrations_servicetitan_events_settings_line_items_url
        def line_items
          @client_api_integration_line_items.update(params_line_items)
          @client_api_integration.update(ignore_sold_with_line_items: [])
          @client_api_integration_line_items.update(line_items: Integration::Servicetitan::V2::Base.new(@client_api_integration).collect_line_items_from_servicetitan.sort_by { |_k, v| v }.map { |li| [li[1], li[0]] })
        end

        # (PUT/PATCH) update ServiceTitan events settings
        # /integrations/servicetitan/events/settings
        # integrations_servicetitan_events_settings_path
        # integrations_servicetitan_events_settings_url
        def update
          @client_api_integration.update(params_ignore_line_items)
        end

        private

        def client_api_integration_line_items
          @client_api_integration_line_items = current_user.client.client_api_integrations.find_or_create_by(target: 'servicetitan', name: 'line_items')
        end

        def params_ignore_line_items
          sanitized_params = params.permit(:call_event_delay, ignore_sold_with_line_items: [])

          sanitized_params[:call_event_delay]            = sanitized_params.dig(:call_event_delay).to_i
          sanitized_params[:ignore_sold_with_line_items] = (sanitized_params.dig(:ignore_sold_with_line_items) || []).compact_blank.map(&:to_i)

          sanitized_params
        end

        def params_line_items
          sanitized_params = params.permit(:equipment, :materials, :services, categories: [])

          sanitized_params[:categories] = (sanitized_params.dig(:categories) || []).compact_blank.map(&:to_i)
          sanitized_params[:equipment]  = sanitized_params.dig(:equipment).to_bool
          sanitized_params[:materials]  = sanitized_params.dig(:materials).to_bool
          sanitized_params[:services]   = sanitized_params.dig(:services).to_bool

          sanitized_params
        end
      end
    end
  end
end
