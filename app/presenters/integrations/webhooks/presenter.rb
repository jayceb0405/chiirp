# frozen_string_literal: true

# app/presenters/integrations/webhooks/presenter.rb
module Integrations
  module Webhooks
    class Presenter
      attr_reader :client, :client_api_integration, :webhook

      DATA_TYPES = [
        ['Campaigns (GET)', 'campaigns'],
        ['Contacts (POST)', 'contact'],
        ['Custom Fields (GET)', 'custom_fields'],
        ['Groups (GET)', 'groups'],
        ['Stages (GET)', 'stages'],
        ['Tags (GET)', 'tags'],
        ['Users (POST)', 'user']
      ].freeze
      WEBHOOK_TYPES = [
        ['New Contact', 'contact_created'],
        ['Updated Contact', 'contact_updated'],
        ['Deleted Contact', 'contact_deleted']
      ].freeze

      def initialize(args = {})
        self.client_api_integration = args.dig(:client_api_integration)
      end

      def api_form_submit_path
        if @webhook&.new_record?
          Rails.application.routes.url_helpers.integrations_webhook_apis_path
        else
          Rails.application.routes.url_helpers.integrations_webhook_api_path(@webhook.id)
        end
      end

      def apis
        @client.webhooks.order(:name)
      end

      def campaigns_allowed?
        @client.campaigns_count.positive?
      end

      def cleaned_option_key(key)
        key.delete('[').delete(']')
      end

      def client_api_integration=(client_api_integration)
        @client_api_integration = case client_api_integration
                                  when ClientApiIntegration
                                    client_api_integration
                                  when Integer
                                    ClientApiIntegration.find_by(id: client_api_integration)
                                  else
                                    ClientApiIntegration.new
                                  end

        @webhook                = nil
        @client                 = @client_api_integration.client
      end

      def groups_allowed?
        @client.groups_count.positive?
      end

      def stages_allowed?
        @client.stages_count.positive?
      end

      def subscription_webhook_url
        app_host = I18n.with_locale(@client.tenant) { I18n.t("tenant.#{Rails.env}.app_host") }

        case @webhook.data_type
        when 'campaigns'
          Rails.application.routes.url_helpers.integrations_webhook_v1_api_campaigns_url(@webhook.token, host: app_host)
        when 'contact'
          Rails.application.routes.url_helpers.integrations_webhook_client_api_url(@client, @webhook.token, host: app_host)
        when 'custom_fields'
          Rails.application.routes.url_helpers.integrations_webhook_v1_api_custom_fields_url(@webhook.token, host: app_host)
        when 'groups'
          Rails.application.routes.url_helpers.integrations_webhook_v1_api_groups_url(@webhook.token, host: app_host)
        when 'stages'
          Rails.application.routes.url_helpers.integrations_webhook_v1_api_stages_url(@webhook.token, host: app_host)
        when 'tags'
          Rails.application.routes.url_helpers.integrations_webhook_v1_api_tags_url(@webhook.token, host: app_host)
        when 'user'
          Rails.application.routes.url_helpers.integrations_webhook_user_api_url(@client, @webhook.token, host: app_host)
        else
          ''
        end
      end

      def table_colspan
        7 + (self.campaigns_allowed? ? 2 : 0) + (self.groups_allowed? ? 1 : 0) + (self.stages_allowed? ? 1 : 0)
      end

      def webhook=(webhook)
        @webhook = case webhook
                   when ::Webhook
                     webhook
                   when Integer
                     @client.webhooks.find_by(id: webhook)
                   else
                     @client.webhooks.new
                   end
      end

      def webhook_fields
        ::Webhook.internal_key_hash(@client, 'contact', %w[personal phones]).map { |k, v| [v, k] } + [['Primary Phone', 'phone_primary'], ['OK to Text', 'ok2text'], ['OK to Email', 'ok2email']] + ::Webhook.internal_key_hash(@client, 'contact', %w[ext_references custom_fields user]).map { |k, v| [v, k] } + [['Last updated', 'last_updated'], ['Last contacted', 'last_contacted'], %w[Notes notes], %w[Tags tags], ['Trusted Form Token', 'trusted_form_token'], ['Trusted Form Certificate URL', 'trusted_form_cert_url'], ['Trusted Form PingURL', 'trusted_form_ping_url']]
      end

      def webhook_match_fields
        case @webhook&.data_type
        when 'contact'
          ::Webhook.internal_key_hash(@client, @webhook&.data_type).merge({ 'tag' => 'Tag', 'tags' => 'Tags (comma separated)', 'nested_fields' => 'Nested Fields' }).invert.sort
        when 'user'
          {
            'First Name'   => 'firstname',
            'Last Name'    => 'lastname',
            'Full Name'    => 'fullname',
            'Phone Number' => 'phone',
            'Email'        => 'email'
          }
        else
          {}
        end
      end

      def webhook_save_method(_webhook_id, webhook)
        webhook.blank? ? :post : :patch
      end

      def webhook_save_path(webhook_id, webhook)
        webhook.blank? ? Rails.application.routes.url_helpers.integrations_webhook_webhooks_path : Rails.application.routes.url_helpers.integrations_webhook_webhook_path(webhook_id)
      end
    end
  end
end
