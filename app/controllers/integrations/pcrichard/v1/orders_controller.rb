# frozen_string_literal: true

# app/controllers/integrations/pcrichard/v1/orders_controller.rb
module Integrations
  module Pcrichard
    module V1
      class OrdersController < Pcrichard::V1::IntegrationsController
        before_action :validate_params, only: %i[new]
        before_action :validate_customer_id, only: %i[new]
        before_action :find_contact, only: %i[new]
        before_action :validate_model_selected, only: %i[new]

        # (GET) edit configuration used to receive new PC Richard orders
        # /integrations/pcrichard/v1/orders/edit
        # edit_integrations_pcrichard_v1_orders_path
        # edit_integrations_pcrichard_v1_orders_url
        def edit
          render partial: 'integrations/pcrichard/v1/js/show', locals: { cards: %w[orders_edit] }
        end

        # (POST) receive a new PC Richard customer
        # /integrations/pcrichard/v1/orders/new/:api_key
        # integrations_pcrichard_v1_new_orders_path(:api_key)
        # integrations_pcrichard_v1_new_orders_url(:api_key)
        def new
          sanitized_params = params_orders_new

          # save params to Contact::RawPosts
          @contact.raw_posts.create(ext_source: 'pcrichard', ext_id: 'new_order', data: params.except(:integration))

          custom_fields = {}
          custom_fields[@client_api_integration.leads['custom_field_assignments']['invoice_number']] = sanitized_params[:invoiceNumber] if sanitized_params.dig(:invoiceNumber) && @client_api_integration.leads.dig('custom_field_assignments', 'invoice_number')
          custom_fields[@client_api_integration.orders['custom_field_assignments']['model_number']] = sanitized_params[:modelNumber] if sanitized_params.dig(:modelNumber) && @client_api_integration.orders.dig('custom_field_assignments', 'model_number')
          custom_fields[@client_api_integration.orders['custom_field_assignments']['sold_at']] = sanitized_params[:soldAt] if sanitized_params.dig(:soldAt) && @client_api_integration.orders.dig('custom_field_assignments', 'sold_at')
          @contact.update_custom_fields(custom_fields:)
          @contact.process_actions(
            campaign_id:       @client_api_integration.orders.dig('campaign_id'),
            group_id:          @client_api_integration.orders.dig('group_id'),
            stage_id:          @client_api_integration.orders.dig('stage_id'),
            tag_id:            @client_api_integration.orders.dig('tag_id'),
            stop_campaign_ids: @client_api_integration.orders.dig('stop_campaign_ids')
          )

          render plain: 'ok', content_type: 'text/plain', layout: false, status: :ok
        end

        # (PATCH/PUT) update configuration used to receive new PC Richard orders
        # /integrations/pcrichard/v1/orders
        # integrations_pcrichard_v1_orders_path
        # integrations_pcrichard_v1_orders_url
        def update
          @client_api_integration.update(orders: params_orders_edit)

          render partial: 'integrations/pcrichard/v1/js/show', locals: { cards: %w[orders_edit] }
        end

        private

        def find_contact
          sanitized_params = params_orders_new

          return if (@contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: @client_api_integration.client_id, phones: {}, emails: [], ext_refs: { 'pcrichard' => sanitized_params.dig(:customerId) }))

          respond_to do |format|
            format.json { render json: { message: 'Customer not found using customerId.', status: 406 } and return false }
            format.js   { render js: 'Customer not found using customerId.', layout: false, status: :not_acceptable and return false }
            format.all  { render 'Customer not found using customerId.', layout: false, status: :not_acceptable, formats: :html and return false }
          end
        end

        def params_orders_edit
          sanitized_params = params.require(:orders).permit(:campaign_id, :group_id, :stage_id, :tag_id, custom_field_assignments: %i[model_number sold_at], stop_campaign_ids: [])

          sanitized_params[:campaign_id] = sanitized_params.dig(:campaign_id).to_i
          sanitized_params[:group_id]    = sanitized_params.dig(:group_id).to_i
          sanitized_params[:stage_id]    = sanitized_params.dig(:stage_id).to_i
          sanitized_params[:tag_id]      = sanitized_params.dig(:tag_id).to_i
          sanitized_params[:stop_campaign_ids] = sanitized_params.dig(:stop_campaign_ids)&.compact_blank
          sanitized_params[:stop_campaign_ids] = [0] if sanitized_params.dig(:stop_campaign_ids)&.include?('0')
          sanitized_params[:custom_field_assignments][:model_number] = sanitized_params.dig(:custom_field_assignments, :model_number).to_i
          sanitized_params[:custom_field_assignments][:sold_at]      = sanitized_params.dig(:custom_field_assignments, :sold_at).to_i

          sanitized_params
        end

        def params_orders_new
          params.permit(:customerId, :invoiceNumber, :modelNumber, :soldAt)
        end

        def validate_customer_id
          sanitized_params = params_orders_new

          return if @client_api_integration.client.contacts.joins(:ext_references).where(ext_references: { target: 'pcrichard', ext_id: sanitized_params.dig(:customerId) })

          respond_to do |format|
            format.json { render json: { message: 'Customer must be found using customerId.', status: 404 } and return false }
            format.js   { render js: 'Customer must be found using customerId.', layout: false, status: :not_found and return false }
            format.all  { render 'Customer must be found using customerId.', layout: false, status: :not_found, formats: :html and return false }
          end
        end

        def validate_model_selected
          sanitized_params = params_orders_new

          return if Integration::Pcrichard::V1::Base.new(@client_api_integration).contact_models_selected(@contact).include?(sanitized_params.dig(:modelNumber))
          return if Rails.env.development? || @contact.user.access_controller?('users', 'permissions', session)

          respond_to do |format|
            format.json { render json: { message: 'Selected Model must match a recommended model.', status: 404 } and return false }
            format.js   { render js: 'Selected Model must match a recommended model.', layout: false, status: :not_found and return false }
            format.all  { render 'Selected Model must match a recommended model.', layout: false, status: :not_found, formats: :html and return false }
          end
        end

        def validate_params
          sanitized_params = params_orders_new
          response         = []

          response << 'Customer ID must be received.' if sanitized_params.dig(:customerId).blank?
          response << 'Invoice number must be received.' if sanitized_params.dig(:invoiceNumber).blank?
          response << 'Model number must be received.' if sanitized_params.dig(:modelNumber).blank?
          response << 'Valid Date Sold must be received.' unless Time.use_zone('Eastern Time (US & Canada)') { Chronic.parse(sanitized_params.dig(:soldAt)) }.is_a?(Time)

          return if response.empty?

          respond_to do |format|
            format.json { render json: { message: response.join(', '), status: 406 } and return false }
            format.js   { render js: response.join(', '), layout: false, status: :not_acceptable and return false }
            format.all  { render response.join(', '), layout: false, status: :not_acceptable, formats: :html and return false }
          end
        end
      end
    end
  end
end
