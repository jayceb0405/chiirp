# frozen_string_literal: true

# app/controllers/integrations/dropfunnels/integrations_controller.rb
module Integrations
  module Dropfunnels
    # general DropFunnels integration endpoints
    class IntegrationsController < ApplicationController
      skip_before_action :verify_authenticity_token, only: %i[endpoint]
      # rubocop:disable Rails/LexicallyScopedActionFilter
      before_action :authenticate_user!, only: %i[instructions show update]
      before_action :authorize_user!, only: %i[instructions show update]
      before_action :client_api_integration, only: %i[show update]
      # rubocop:enable Rails/LexicallyScopedActionFilter
      before_action :client_from_api_key, only: %i[endpoint]

      def endpoint
        # (POST) post data to Dropfunnel endpoint
        # /integrations/dropfunnels/endpoint/:api_key
        # integrations_dropfunnels_integration_endpoint_path(:api_key)
        # integrations_dropfunnels_integration_endpoint_url(:api_key)
        render json: { message: 'Invalid Content Type.', status: 415 } and return unless request.content_type == 'application/json'

        contact_hash = {
          firstname: params.dig(:data, :contact, :first_name).to_s,
          lastname:  params.dig(:data, :contact, :last_name).to_s,
          fullname:  params.dig(:data, :contact, :full_name).to_s,
          address1:  params.dig(:data, :order, :billing_fields).is_a?(Hash) ? params.dig(:data, :order, :billing_fields, :billing_address).to_s : '',
          city:      params.dig(:data, :order, :billing_fields).is_a?(Hash) ? params.dig(:data, :order, :billing_fields, :billing_city).to_s : '',
          state:     params.dig(:data, :order, :billing_fields).is_a?(Hash) ? params.dig(:data, :order, :billing_fields, :billing_state).to_s : '',
          zipcode:   params.dig(:data, :order, :billing_fields).is_a?(Hash) ? params.dig(:data, :order, :billing_fields, :billing_zipcode).to_s : '',
          email:     params.dig(:data, :contact, :user_email).to_s
        }

        if contact_hash[:fullname].present? && contact_hash[:firstname].blank? && contact_hash[:lastname].blank?
          fullname = contact_hash[:fullname].to_s.parse_name
          contact_hash[:firstname] = fullname[:firstname]
          contact_hash[:lastname]  = fullname[:lastname]
        end

        contact_hash.delete(:fullname)

        phone  = params.dig(:data, :contact, :phone).to_s.clean_phone(@client_api_integration.client.primary_area_code)
        phones = phone.present? ? { phone => 'Mobile' } : {}

        contact = if params.dig(:data, :contact, :lead_id).present? || phones.present? || contact_hash[:email].present?
                    # find or create new Contact with data received
                    Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: @client_api_integration.client_id, phones:, emails: [contact_hash[:email]], ext_refs: { 'dropfunnels' => params.dig(:data, :contact, :lead_id) })
                  else
                    @client_api_integration.client.contacts.new
                  end

        contact.update(contact_hash)

        campaign_id       = 0
        group_id          = 0
        tag_id            = 0
        stage_id          = 0
        stop_campaign_ids = []

        case params.dig(:data, :event).to_s
        when 'lead_create'
          campaign_id       = @client_api_integration.lead_create['campaign_id'].to_i
          group_id          = @client_api_integration.lead_create['group_id'].to_i
          tag_id            = @client_api_integration.lead_create['tag_id'].to_i
          stage_id          = @client_api_integration.lead_create['stage_id'].to_i
          stop_campaign_ids = @client_api_integration.lead_create['stop_campaign_ids']&.compact_blank
          # funnel_id       = params.dig(:data, :contact, :funnel_id).to_s
        when 'two_step_lead_create'
          campaign_id       = @client_api_integration.two_step_lead_create['campaign_id'].to_i
          group_id          = @client_api_integration.two_step_lead_create['group_id'].to_i
          tag_id            = @client_api_integration.two_step_lead_create['tag_id'].to_i
          stage_id          = @client_api_integration.two_step_lead_create['stage_id'].to_i
          stop_campaign_ids = @client_api_integration.two_step_lead_create['stop_campaign_ids']&.compact_blank
          # funnel_id       = params.dig(:data, :contact, :funnel_id).to_s
        when 'product_purchased_main'
          campaign_id       = @client_api_integration.product_purchased_main['campaign_id'].to_i
          group_id          = @client_api_integration.product_purchased_main['group_id'].to_i
          tag_id            = @client_api_integration.product_purchased_main['tag_id'].to_i
          stage_id          = @client_api_integration.product_purchased_main['stage_id'].to_i
          stop_campaign_ids = @client_api_integration.product_purchased_main['stop_campaign_ids']&.compact_blank
          # funnel_id       = params.dig(:data, :product, :funnel_id).to_s
        when 'product_purchased_order_bump'
          campaign_id       = @client_api_integration.product_purchased_order_bump['campaign_id'].to_i
          group_id          = @client_api_integration.product_purchased_order_bump['group_id'].to_i
          tag_id            = @client_api_integration.product_purchased_order_bump['tag_id'].to_i
          stage_id          = @client_api_integration.product_purchased_order_bump['stage_id'].to_i
          stop_campaign_ids = @client_api_integration.product_purchased_order_bump['stop_campaign_ids']&.compact_blank
          # funnel_id       = params.dig(:data, :product, :funnel_id).to_s
        when 'product_purchased_order_upsell'
          campaign_id       = @client_api_integration.product_purchased_order_upsell['campaign_id'].to_i
          group_id          = @client_api_integration.product_purchased_order_upsell['group_id'].to_i
          tag_id            = @client_api_integration.product_purchased_order_upsell['tag_id'].to_i
          stage_id          = @client_api_integration.product_purchased_order_upsell['stage_id'].to_i
          stop_campaign_ids = @client_api_integration.product_purchased_order_upsell['stop_campaign_ids']&.compact_blank
          # funnel_id       = params.dig(:data, :product, :funnel_id).to_s
        end

        contact.process_actions(
          campaign_id:,
          group_id:,
          stage_id:,
          tag_id:,
          stop_campaign_ids:
        )

        render json: { message: 'Success', status: 200 }
      end

      def instructions
        # (GET) show instructions page for DropFunnels integration
        # /integrations/dropfunnels/integration/instructions
        # integrations_dropfunnels_integration_instructions_path
        # integrations_dropfunnels_integration_instructions_url
        respond_to do |format|
          format.js { render partial: 'integrations/dropfunnels/js/show', locals: { cards: %w[instructions] } }
          format.html { redirect_to central_path }
        end
      end

      def show
        # (GET) show DropFunnels integration
        # /integrations/dropfunnels/integration
        # integrations_dropfunnels_integration_path
        # integrations_dropfunnels_integration_url
        respond_to do |format|
          format.js   { render partial: 'integrations/dropfunnels/js/show', locals: { cards: %w[overview] } }
          format.html { render 'integrations/dropfunnels/show', locals: { partial_to_show: params.dig(:card).present? ? "integrations/dropfunnels/#{params[:card]}/show" : '' } }
        end
      end

      private

      def authorize_user!
        super

        return if current_user.access_controller?('integrations', 'client', session) && current_user.client.integrations_allowed.include?('dropfunnels')

        sweetalert_error('Unathorized Access!', 'Your account is NOT authorized to access DropFunnels Integration. Please contact your account admin.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def client_api_integration
        @client_api_integration = current_user.client.client_api_integrations.find_or_create_by(target: 'dropfunnels')

        return if @client_api_integration.api_key.present?

        api_key_length = 36
        new_api_key = RandomCode.new.create(api_key_length)

        new_api_key = RandomCode.new.create(api_key_length) while ClientApiIntegration.find_by(target: 'dropfunnels', api_key: new_api_key)

        @client_api_integration.update(api_key: new_api_key)
      end

      def client_from_api_key
        # find a Client using the API key included in the URL of the request
        return if (@client_api_integration = ClientApiIntegration.find_by(target: 'dropfunnels', api_key: params.dig(:api_key).to_s))

        respond_to do |format|
          format.json { render json: { message: 'Invalid API Key.', status: 404 } and return false }
          format.html { render plain: 'Invalid API Key.', content_type: 'text/plain', layout: false, status: :not_found and return false }
        end
      end
    end
  end
end
