# frozen_string_literal: true

# app/controllers/integrations/google/integrations_controller.rb
module Integrations
  module Google
    class IntegrationsController < ApplicationController
      before_action :authenticate_user!
      before_action :authorize_user!
      before_action :client_api_integration
      before_action :update_client_api_integration_user_id, only: %i[show]
      before_action :user_api_integration

      # (POST) create a Google Calendar event
      # /integrations/google/integrations
      # integrations_google_integrations_path
      # integrations_google_integrations_url
      def create
        sanitized_params = params.permit(:calendar_id, :title, :description, :location, :recurrence, :attendee_emails, :start_utc, :end_utc, :all_day)

        if sanitized_params.dig(:calendar_id).to_s.present? && sanitized_params.dig(:title).to_s.present? && sanitized_params.dig(:start_utc).to_s.present? && (user_api_integration = current_user.user_api_integrations.find_by(target: 'google', name: ''))

          if sanitized_params.dig(:all_day).to_bool
            start_utc = sanitized_params.dig(:start_utc).to_s.to_date
            end_utc   = (sanitized_params.dig(:end_utc).to_s.to_date || start_utc) + 1.day
          else
            start_utc = sanitized_params.dig(:start_utc).to_s.to_datetime&.utc
            end_utc   = sanitized_params.dig(:end_utc).to_s.to_datetime&.utc || (start_utc + 1.hour)
          end

          if Integration::Google.valid_token?(user_api_integration)
            ggl_client = Integrations::Ggl::Calendar.new(user_api_integration.token, I18n.t('tenant.id'))
            ggl_client.event_add(
              calendar_id:     sanitized_params.dig(:calendar_id).to_s,
              title:           CGI.unescapeHTML(sanitized_params.dig(:title).to_s),
              description:     sanitized_params.dig(:description).to_s,
              location:        sanitized_params.dig(:location).to_s,
              recurrence:      sanitized_params.dig(:recurrence).to_s,
              attendee_emails: sanitized_params.dig(:attendee_emails).split(','),
              start_utc:,
              end_utc:
            )
            response = ggl_client.success? ? [true, "#{CGI.unescapeHTML(sanitized_params.dig(:title).to_s)} successfully added to Google calendar."] : [false, "#{CGI.unescapeHTML(sanitized_params.dig(:title).to_s)} could not be added to Google calendar."]
          else
            response = [false, "#{CGI.unescapeHTML(sanitized_params.dig(:title).to_s)} could not be added to Google calendar."]
          end
        end

        respond_to do |format|
          format.js { render js: response.to_json, layout: false, status: :ok }
          format.html { redirect_to integrations_google_integrations_path }
        end
      end

      # (GET) show main Google integration screen
      # /integrations/google/integrations
      # integrations_google_integrations_path
      # integrations_google_integrations_url
      def show
        respond_to do |format|
          format.js { render partial: 'integrations/google/js/show', locals: { cards: %w[overview] } }
          format.html { render 'integrations/google/show' }
        end
      end

      private

      def authorize_user!
        super
        return if (current_user.access_controller?('integrations', 'google_messages', session) || current_user.access_controller?('integrations', 'google_reviews', session)) && current_user.client.integrations_allowed.include?('google')

        raise ExceptionHandlers::UserNotAuthorized.new('Google Integrations', root_path)
      end

      def authorize_user_for_accounts_locations_config!
        return true if Integration::Google.user_authorized_for_accounts_locations_config?(current_user, @client_api_integration)

        raise ExceptionHandlers::UserNotAuthorized.new('Google Account Locations', integrations_google_reviews_path)
      end

      def authorize_user_for_messages!
        return true if current_user.access_controller?('integrations', 'google_messages', session)

        raise ExceptionHandlers::UserNotAuthorized.new('Google Messages', integrations_google_integrations_path)
      end

      def authorize_user_for_reviews!
        return true if current_user.access_controller?('integrations', 'google_reviews', session)

        raise ExceptionHandlers::UserNotAuthorized.new('Google Reviews', integrations_google_integrations_path)
      end

      def client_api_integration
        return true if (@client_api_integration = current_user.client.client_api_integrations.find_or_create_by(target: 'google', name: ''))

        raise ExceptionHandlers::UserNotAuthorized.new('Google Messages or Reviews', root_path)
      end

      def primary_user_api_integration
        @primary_user_api_integration = UserApiIntegration.find_by(user_id: @client_api_integration.user_id, target: 'google', name: '') if @client_api_integration.user_id.positive?
      end

      def update_client_api_integration_user_id
        @client_api_integration.update(user_id: current_user.id) if (current_user.access_controller?('integrations', 'google_messages', session) || current_user.access_controller?('integrations', 'google_reviews', session)) && @client_api_integration.user_id.to_i.zero?
      end

      def user_api_integration
        return true if (@user_api_integration = current_user.user_api_integrations.find_or_create_by(target: 'google', name: ''))

        raise ExceptionHandlers::UserNotAuthorized.new('Google Integrations', root_path)
      end
    end
  end
end
