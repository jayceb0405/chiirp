# frozen_string_literal: true

# app/controllers/integrations/housecall/webhooks_controller.rb
module Integrations
  module Housecall
    class WebhooksController < Housecall::IntegrationsController
      # (PATCH/PUT)
      # /integrations/housecall/webhooks/:id/activate/:event
      # integrations_housecall_webhook_activate_path(:id, :event)
      # integrations_housecall_webhook_activate_url(:id, :event)
      def activate
        toggle_active_webhook

        render partial: 'integrations/housecall/js/show', locals: { cards: %w[webhooks_index] }
      end

      # (POST)
      # /integrations/housecall/webhooks
      # integrations_housecall_webhooks_path
      # integrations_housecall_webhooks_url
      def create
        create_new_webhook

        render partial: 'integrations/housecall/js/show', locals: { cards: %w[webhooks_index] }
      end

      # (DELETE)
      # /integrations/housecall/webhooks/:id
      # integrations_housecall_webhooks_path(:id)
      # integrations_housecall_webhooks_url(:id)
      def destroy
        destroy_webhook

        render partial: 'integrations/housecall/js/show', locals: { cards: %w[webhooks_index] }
      end

      # (GET)
      # /integrations/housecall/webhooks/:id/edit
      # edit_integrations_housecall_webhooks_path(:id)
      # edit_integrations_housecall_webhooks_url(:id)
      def edit
        @webhook = find_webhook_by_id(params.permit(:id).dig(:id))

        render partial: 'integrations/housecall/js/show', locals: { cards: %w[webhooks_edit] }
      end

      # (GET)
      # /integrations/housecall/webhooks
      # integrations_housecall_webhooks_path
      # integrations_housecall_webhooks_url
      def index
        render partial: 'integrations/housecall/js/show', locals: { cards: %w[webhooks_index] }
      end

      # (GET)
      # /integrations/housecall/webhooks/new
      # new_integrations_housecall_webhooks_path
      # new_integrations_housecall_webhooks_url
      def new
        event_id = create_new_event_id
        @client_api_integration.webhooks[''] = [{ 'active' => true, 'actions' => { 'tag_id' => 0, 'group_id' => 0, 'stage_id' => 0, 'campaign_id' => 0 }, 'criteria' => { 'event_new' => true, 'event_updated' => true }, 'event_id' => event_id }]
        @client_api_integration.save

        @webhook = find_webhook_by_id(event_id)

        render partial: 'integrations/housecall/js/show', locals: { cards: %w[webhooks_index webhooks_open_new] }
      end

      # (GET) refresh HCP technicians
      # /integrations/housecall/webhooks/refresh_technicians
      # integrations_housecall_webhooks_refresh_technicians_path
      # integrations_housecall_webhooks_refresh_technicians_url
      def refresh_technicians
        @webhook = find_webhook_by_id(params.permit(:webhook_id).dig(:webhook_id))
        Integration::Housecallpro::V1::Base.new(@client_api_integration).refresh_technicians
      end

      # (PATCH/PUT) update webhooks
      # /integrations/housecall/webhooks/:id
      # integrations_housecall_webhook_path(:id)
      # integrations_housecall_webhook_url(:id)
      def update
        destroy_webhook
        create_new_webhook

        if @client_api_integration.webhooks.present?
          # we only need to provision webhooks if any are assigned to actions
          Integrations::HousecallPro::Base.new(@client_api_integration.credentials).provision_webhooks
        else
          Integrations::HousecallPro::Base.new(@client_api_integration.credentials).deprovision_webhooks
        end

        respond_to do |format|
          format.js { render partial: 'integrations/housecall/js/show', locals: { cards: %w[webhooks_index] } }
          format.html { redirect_to integrations_housecall_path }
        end
      end

      private

      def create_new_event_id
        event_id = RandomCode.new.create(20)
        event_id = RandomCode.new.create(20) while @client_api_integration.webhooks.map { |_k, v| v.map { |e| e.dig('event_id') } }.flatten.include?(event_id)
        event_id
      end

      def create_new_webhook
        sanitized_params = webhook_params

        return unless sanitized_params.dig(:event).present? && sanitized_params.dig(:actions).present? && sanitized_params.dig(:criteria).present?

        @client_api_integration.webhooks[sanitized_params.dig(:event)] = [] unless @client_api_integration.webhooks.dig(sanitized_params.dig(:event))
        @client_api_integration.webhooks[sanitized_params.dig(:event)] << {
          actions:  sanitized_params.dig(:actions),
          criteria: sanitized_params.dig(:criteria),
          event_id: create_new_event_id
        }

        @client_api_integration.save
      end

      def destroy_webhook
        sanitized_params = params.permit(:id, :event)

        return if sanitized_params.dig(:id).to_s.blank?

        @client_api_integration.webhooks[sanitized_params[:event].to_s].delete_if { |x| x['event_id'] == sanitized_params[:id].to_s }
        @client_api_integration.save
      end

      def find_webhook_by_id(webhook_id)
        [find_webhook_event_by_id(webhook_id).first, find_webhook_event_by_id(webhook_id).second&.find { |w| w.dig('event_id') == webhook_id }]
      end

      def find_webhook_event_by_id(webhook_id)
        @client_api_integration.webhooks.find { |_k, v| v.find { |e| e.dig('event_id') == webhook_id } } || []
      end

      def toggle_active_webhook
        sanitized_params = params.permit(:id, :event)

        return unless sanitized_params.dig(:id).to_s.present? && sanitized_params.dig(:event).to_s.present?

        if (event = @client_api_integration.webhooks[sanitized_params.dig(:event).to_s]&.find { |e| e.dig('event_id') == sanitized_params.dig(:id).to_s })
          event['active'] = event.dig('active').nil? ? false : !event['active']
        end

        @client_api_integration.save
      end

      def webhook_params
        sanitized_params = params.require(:webhook).permit(:event, criteria: [:event_new, :event_updated, :start_date_updated, :tech_updated,
                                                                              { approval_status: [], ext_tech_ids: [], lead_sources: [], line_items: [], tag_ids_exclude: [], tag_ids_include: [] }],
                                                                   actions:  %i[assign_user campaign_id group_id stage_id tag_id] + [{ stop_campaign_ids: [] }])

        sanitized_params[:actions] = {
          assign_user:       sanitized_params.dig(:actions, :assign_user).to_bool,
          campaign_id:       sanitized_params.dig(:actions, :campaign_id).to_i,
          stop_campaign_ids: sanitized_params.dig(:actions, :stop_campaign_ids)&.compact_blank,
          group_id:          sanitized_params.dig(:actions, :group_id).to_i,
          stage_id:          sanitized_params.dig(:actions, :stage_id).to_i,
          tag_id:            sanitized_params.dig(:actions, :tag_id).to_i
        }
        sanitized_params[:actions][:stop_campaign_ids]   = [0] if sanitized_params[:actions][:stop_campaign_ids]&.include?('0')
        sanitized_params[:criteria][:approval_status]    = sanitized_params[:criteria][:approval_status].compact_blank if sanitized_params.dig(:criteria, :approval_status)
        sanitized_params[:criteria][:event_new]          = sanitized_params[:criteria][:event_new].to_bool if sanitized_params.dig(:criteria, :event_new)
        sanitized_params[:criteria][:event_updated]      = sanitized_params[:criteria][:event_updated].to_bool if sanitized_params.dig(:criteria, :event_updated)
        sanitized_params[:criteria][:ext_tech_ids]       = sanitized_params[:criteria][:ext_tech_ids].compact_blank if sanitized_params.dig(:criteria, :ext_tech_ids)
        sanitized_params[:criteria][:lead_sources]       = sanitized_params[:criteria][:lead_sources].compact_blank.map(&:to_i) if sanitized_params.dig(:criteria, :lead_sources)
        sanitized_params[:criteria][:line_items]         = sanitized_params[:criteria][:line_items].compact_blank if sanitized_params.dig(:criteria, :line_items)
        sanitized_params[:criteria][:start_date_updated] = sanitized_params[:criteria][:start_date_updated].to_bool if sanitized_params.dig(:start_date_updated)
        sanitized_params[:criteria][:tag_ids_exclude]    = sanitized_params[:criteria][:tag_ids_exclude].compact_blank.map(&:to_i) if sanitized_params.dig(:criteria, :tag_ids_exclude)
        sanitized_params[:criteria][:tag_ids_include]    = sanitized_params[:criteria][:tag_ids_include].compact_blank.map(&:to_i) if sanitized_params.dig(:criteria, :tag_ids_include)
        # sanitized_params[:criteria][:tech_updated]       = sanitized_params[:criteria][:tech_updated].to_bool if sanitized_params.dig(:criteria, :tech_updated)

        sanitized_params
      end
    end
  end
end
