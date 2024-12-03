# frozen_string_literal: true

# app/controllers/integrations/webhook/apis_controller.rb
module Integrations
  module Webhook
    class ApisController < Webhook::IntegrationsController
      before_action :webhook, only: %i[destroy edit edit_option update testpost]

      # (POST) create a new Webhook
      # /integrations/webhook/apis
      # integrations_webhook_apis_path
      # integrations_webhook_apis_url
      def create
        case params.dig(:integration).to_s
        when 'scheduleonce'

          if params.include?(:webhook_event)

            if params[:webhook_event].to_s == 'api_key'
              render partial: 'webhooks/scheduleonce/js/show', locals: { elements: [2] } and return unless params.include?(:api_key)

              if @client.scheduleonce_api_key != params[:api_key].to_s

                if params[:api_key].empty?

                  so = ScheduleOnce.new
                  success = so.delete_webhook({ api_key: @client.scheduleonce_api_key, webhook_id: @client.scheduleonce_webhook_id })

                  if success
                    @client.scheduleonce_api_key    = ''
                    @client.scheduleonce_webhook_id = ''
                  end
                else

                  if @client.scheduleonce_api_key.present?
                    # do nothing
                  elsif @client.scheduleonce_webhook_id.present?

                    so = ScheduleOnce.new
                    so.delete_webhook({ api_key: @client.scheduleonce_api_key, webhook_id: @client.scheduleonce_webhook_id })

                    @client.scheduleonce_api_key    = ''
                    @client.scheduleonce_webhook_id = ''
                  end

                  webhook_token = ::Webhook.generate_webhook_token({ client_id: @client.id })
                  client_code   = @client.id.to_s + @client.id.to_s.split(%r{}).sum(&:to_i).to_s # convert Client id into a sum of the digits (123 = "6") then append to Client id (123 = "6" = "1236")
                  webhook_token[0..client_code.length - 1] = client_code

                  so = ScheduleOnce.new
                  webhook_id = so.create_webhook({ api_key: params[:api_key].to_s, webhook_url: integrations_webhook_client_api_url(@client.id, webhook_token), webhook_name: "#{I18n.t('tenant.name')} Webhook", webhook_events: ['booking'] }).to_s

                  unless webhook_id.empty?
                    @client.scheduleonce_webhook_id = webhook_id
                    @client.scheduleonce_api_key    = params[:api_key].to_s
                  end
                end

                @webhook.destroy
                @client.save
                @webhook = @client.webhooks.new
              end

              render partial: 'webhooks/scheduleonce/js/show', locals: { elements: [1, 20] } and return
            else
              webhook_event = params[:webhook_event].to_s

              render partial: 'webhooks/scheduleonce/js/show', locals: { elements: [3], event: webhook_event } and return unless params.include?(:campaign_id)

              campaign = @client.campaigns.find_by_id(params[:campaign_id].to_i)

              if campaign
                @client.send(:"scheduleonce_#{webhook_event}=", campaign.id)
              else
                @client.send(:"scheduleonce_#{webhook_event}=", '')
              end

              @webhook.destroy
              @client.save
              @webhook = @client.webhooks.new

              render partial: 'webhooks/scheduleonce/js/show', locals: { elements: [1, 20] }
            end
          end
        end

        render partial: 'integrations/webhooks/js/show', locals: { cards: %w[apis_list apis_edit apis_webhook_count_badge] }
      end

      # (DELETE) delete a Webhook
      # /integrations/webhook/apis/:id
      # integrations_webhook_api_path(:id)
      # integrations_webhook_api_url(:id)
      def destroy
        @webhook.destroy

        render partial: 'integrations/webhooks/js/show', locals: { cards: %w[apis_list apis_webhook_count_badge] }
      end

      # (GET) show edit screen for Webhook
      # /integrations/webhook/apis/:id/edit
      # edit_integrations_webhook_api_path(:id)
      # edit_integrations_webhook_api_url(:id)
      def edit
        render partial: 'integrations/webhooks/js/show', locals: { cards: %w[apis_edit] }
      end

      # (GET) show a webhook api key options
      # /integrations/webhook/apis/option/:id/:parent_key/:key/:internal_key
      # integrations_webhook_edit_option_path(:id, :parent_key, :key, :internal_key)
      # integrations_webhook_edit_option_url(:id, :parent_key, :key, :internal_key)
      def edit_option
        render partial: 'integrations/webhooks/js/show', locals: {
          cards:              %w[apis_option_key],
          internal_key:       params.dig(:internal_key).to_s,
          parent_key:         params.dig(:parent_key).to_s.gsub('_primary_', ''),
          option:             [params.dig(:key).to_s, @webhook.sample_data.dig(params.dig(:key).to_s)],
          variable_response:  @webhook.variable_response_from_internal_key?(@webhook.data_type, @webhook.client, params.dig(:internal_key).to_s).to_bool,
          variable_responses: @webhook.find_internal_key(params.dig(:key).to_s).to_s == params.dig(:internal_key).to_s ? @webhook.variable_responses_from_external_key(@webhook.data_type, @webhook.client, params.dig(:key).to_s) : @webhook.variable_responses_from_internal_key(@webhook.data_type, @webhook.client, params.dig(:internal_key).to_s),
          reserved_key:       @webhook.reserved_internal_key?(@webhook.data_type, @webhook.client, params.dig(:internal_key).to_s)
        }
      end

      # (GET) show Webhooks page
      # /integrations/webhook/apis
      # integrations_webhook_apis_path
      # integrations_webhook_apis_url
      def index
        render partial: 'integrations/webhooks/js/show', locals: { cards: %w[apis_index] }
      end

      # (GET) set up for a new Webhook
      # /integrations/webhook/apis/new
      # new_integrations_webhook_api_path
      # new_integrations_webhook_api_url
      def new
        @webhook = current_user.client.webhooks.find_or_create_by(name: 'New Webhook')
        @webhook.update(token: ::Webhook.generate_webhook_token({ client_id: current_user.client_id, webhook_id: @webhook.id })) unless @webhook.token.present?

        render partial: 'integrations/webhooks/js/show', locals: { cards: %w[apis_list apis_open_new apis_webhook_count_badge] }
      end

      # (GET) test a post to a webhook
      # /integrations/webhook/apis/test/:id
      # integrations_webhook_test_webhook_path(:id)
      # integrations_webhook_test_webhook_url(:id)
      def testpost
        render 'integrations/webhooks/apis/testpost'
      end

      # (PUT/PATCH) update a Webhook
      # /integrations/webhook/apis/:id
      # integrations_webhook_api_path(:id)
      # integrations_webhook_api_url(:id)
      def update
        render partial: 'integrations/webhooks/js/show', locals: { cards: %w[apis_form], key: params[:key], counter: params[:counter] } and return if params[:commit] == 'ar'

        @webhook.update(params_webhook)

        if params_webhook_keys.present?
          @webhook.webhook_maps.destroy_all

          params_webhook_keys.each do |k, v|
            self.create_webhook_map(k, v)
          end
        end

        if params.dig(:commit).to_s.casecmp?('Save Webhook API')
          render partial: 'integrations/webhooks/js/show', locals: { cards: %w[apis_list apis_edit apis_webhook_count_badge] }
        else
          render partial: 'integrations/webhooks/js/show', locals: { cards: %w[apis_edit apis_webhook_count_badge] }
        end
      end

      private

      def create_webhook_map(key, value)
        return unless value.present? && key.exclude?('_nested')

        webhook_map = @webhook.webhook_maps.create(external_key: key, internal_key: value)

        if params_webhook_response.include?(key)
          response = {}

          params_webhook_response[key].each_value do |value2|
            response[value2['response']] = "#{value2['campaign_id']},#{value2['tag_id']}" unless value2['response'].empty?
          end

          webhook_map.update(response:)
        end

        return unless value == 'nested_fields'

        params.dig('keys', "#{key}_nested")&.each do |key3, value3|
          self.create_webhook_map("#{key}:#{key3}", value3) if value3.present?
        end
      end

      def params_webhook
        sanitized_params = params.require(:webhook).permit(:name, :testing, :campaign_id, :tag_id, :group_id, :stage_id, :data_type, stop_campaign_ids: [])

        sanitized_params[:campaign_id]       = sanitized_params[:campaign_id].to_i if sanitized_params.include?(:campaign_id)
        sanitized_params[:tag_id]            = sanitized_params[:tag_id].to_i if sanitized_params.include?(:tag_id)
        sanitized_params[:group_id]          = sanitized_params[:group_id].to_i if sanitized_params.include?(:group_id)
        sanitized_params[:stage_id]          = sanitized_params[:stage_id].to_i if sanitized_params.include?(:stage_id)
        sanitized_params[:stop_campaign_ids] = sanitized_params[:stop_campaign_ids].compact_blank if sanitized_params.include?(:stop_campaign_ids)
        sanitized_params[:stop_campaign_ids] = [0] if sanitized_params[:stop_campaign_ids]&.include?('0')
        sanitized_params[:testing]           = 0 unless %w[contact user].include?(sanitized_params.dig(:data_type))

        sanitized_params
      end

      def params_webhook_keys
        params[:keys] || {}
      end

      def params_webhook_response
        params[:keyresponses] || {}
      end

      def webhook
        webhook_id = params.permit(:id).dig(:id).to_i

        @webhook = if webhook_id.zero?
                     current_user.client.webhooks.new
                   else
                     current_user.client.webhooks.find_by(id: webhook_id)
                   end

        return if @webhook

        sweetalert_error('Webhook NOT found!', 'We were not able to access the Webhook you requested.', '', { persistent: 'OK' })

        render js: "window.location = '#{integrations_webhook_integration_path}'" and return false
      end
    end
  end
end
