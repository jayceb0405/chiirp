# frozen_string_literal: true

# app/controllers/integrations/outreach/integrations_controller.rb
module Integrations
  module Outreach
    # Support for all general Outreach integration endpoints used with Chiirp
    class IntegrationsController < ApplicationController
      skip_before_action :verify_authenticity_token, only: %i[endpoint]
      before_action :authenticate_user!, except: %i[endpoint]
      before_action :authorize_user!, except: %i[endpoint]
      before_action :client_api_integration, except: %i[endpoint]

      # (POST) Outreach endpoint for authorization
      # /integrations/outreach/integration/endpoint
      # integrations_outreach_integration_endpoint_path
      # integrations_outreach_integration_endpoint_url
      #
      # (POST) Outreach webhook endpoint
      # /integrations/outreach/integration/endpoint/:client_id
      # integrations_outreach_path(:client_id)
      # integrations_outreach_url(:client_id)
      def endpoint
        if params.dig(:client_id).to_i.positive? && (client = Client.find_by(id: params.permit(:client_id).dig(:client_id).to_i)) && (@client_api_integration = client.client_api_integrations.find_or_create_by(target: 'outreach'))
          outreach_client = Integrations::OutReach.new(@client_api_integration.token, @client_api_integration.refresh_token, @client_api_integration.expires_at, client.tenant)
          data = outreach_client.parse_webhook(@client_api_integration.api_key, request.headers, request.raw_post)

          if outreach_client.success?
            campaign_ids      = []
            group_ids         = []
            tag_ids           = []
            stage_ids         = []
            stop_campaign_ids = []

            case data.dig(:resource)
            when 'prospect'
              contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: client.id, phones: data.dig(:phones), emails: [data.dig(:contact, :email)], ext_refs: { 'outreach' => data.dig(:outreach_id) })
              contact.update(data.dig(:contact))

              data.dig(:phones).each { |phone, label| contact.contact_phones.find_or_create_by(phone:, label:) }

              data.dig(:tag_names).each do |tag_name|
                Contacts::Tags::ApplyByNameJob.perform_later(
                  contact_id: contact.id,
                  user_id:    contact.user_id,
                  tag_name:   tag_name
                )
              end

              @client_api_integration.webhook_actions.map(&:deep_symbolize_keys).find_all { |w| w.dig(:resource).to_s == data.dig(:resource) && w.dig(:action).to_s == data.dig(:action) }.each do |webhook|
                campaign_ids      << webhook.dig(:actions, :campaign_id).to_i
                group_ids         << webhook.dig(:actions, :group_id).to_i
                tag_ids           << webhook.dig(:actions, :tag_id).to_i
                stage_ids         << webhook.dig(:actions, :stage_id).to_i
                stop_campaign_ids << webhook.dig(:actions, :stop_campaign_ids)&.compact_blank
              end

              outreach_client.prospect(data.dig(:outreach_id).to_i)

              if outreach_client.success? && (outreach_user_id = outreach_client.result.dig(:outreach_user_id).to_i) && (user_id = @client_api_integration.users.invert.dig(outreach_user_id).to_i)
                contact.assign_user(user_id)
              end
            when 'call'
              contact = nil

              @client_api_integration.webhook_actions.map(&:deep_symbolize_keys).find_all { |w| w.dig(:resource).to_s == data.dig(:resource) && w.dig(:action).to_s == data.dig(:action) && (w.dig(:call_disposition_id).zero? || w.dig(:call_disposition_id) == data.dig(:call_disposition_id).to_i) }.each do |webhook|
                if contact.nil?
                  contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: client.id, phones: data.dig(:phones), emails: [data.dig(:contact, :email)], ext_refs: { 'outreach' => data.dig(:outreach_id) })
                  contact.update(data.dig(:contact))

                  outreach_client.call(data.dig(:outreach_id).to_i)

                  if outreach_client.success? && (outreach_user_id = outreach_client.result.dig(:relationships, :user, :data, :id).to_i) && (user_id = @client_api_integration.users.invert.dig(outreach_user_id).to_i)
                    contact.assign_user(user_id)
                  end
                end

                campaign_ids      << webhook.dig(:actions, :campaign_id).to_i
                group_ids         << webhook.dig(:actions, :group_id).to_i
                tag_ids           << webhook.dig(:actions, :tag_id).to_i
                stage_ids         << webhook.dig(:actions, :stage_id).to_i
                stop_campaign_ids << webhook.dig(:actions, :stop_campaign_ids)&.compact_blank
              end
            end

            stop_campaign_ids.flatten.uniq.each do |campaign_id|
              Contacts::Campaigns::StopJob.perform_later(
                campaign_id: campaign_id.zero? ? 'all' : campaign_id,
                contact_id:  contact.id
              )
            end

            campaign_ids.delete_if(&:zero?).each do |campaign_id|
              Contacts::Campaigns::StartJob.perform_later(
                campaign_id:,
                client_id:   contact.client_id,
                contact_id:  contact.id,
                user_id:     contact.user_id
              )
            end

            group_ids.delete_if(&:zero?).each do |group_id|
              Contacts::Groups::AddJob.perform_later(
                contact_id: contact.id,
                group_id:   group_id
              )
            end

            stage_ids.delete_if(&:zero?).each do |stage_id|
              Contacts::Stages::AddJob.perform_later(
                client_id:  contact.client_id,
                contact_id: contact.id,
                stage_id:   stage_id
              )
            end

            tag_ids.delete_if(&:zero?).each do |tag_id|
              Contacts::Tags::ApplyJob.perform_later(
                contact_id: contact.id,
                tag_id:     tag_id
              )
            end
          end
        end

        respond_to do |format|
          format.json { render json: { message: 'Success', status: 200 } }
          format.js   { render js: 'Success', layout: false, status: :ok }
          format.html { render 'Success', layout: false, status: :ok, formats: :html }
          format.all  { render 'Success', layout: false, status: :ok, formats: :html }
        end
      end
      # Call Disposition Webhook example
      # {
      #   :resource=>"call",
      #   :action=>"created",
      #   :outreach_id=>10,
      #   :call_disposition_id=>6,
      #   :contact=>{
      #     :firstname=>"Barbara",
      #     :lastname=>"Boxer",
      #     :address1=>"",
      #     :address2=>"",
      #     :city=>"",
      #     :state=>"",
      #     :zipcode=>"",
      #     :birthdate=>"",
      #     :email=>"bb@kevinneubert.com"
      #   },
      #   :phones=>{
      #     "8025551234"=>"mobile",
      #     "8025553456"=>"home"
      #   },
      #   :tag_names=>["asdf"]
      # }

      # (GET) show main Outreach integration screen
      # /integrations/outreach/integration
      # integrations_outreach_integration_path
      # integrations_outreach_integration_url
      def show
        respond_to do |format|
          format.js { render partial: 'integrations/outreach/js/show', locals: { cards: %w[overview] } }
          format.html { render 'integrations/outreach/show' }
        end
      end

      private

      def authorize_user!
        super

        return if current_user.access_controller?('integrations', 'user', session) && current_user.client.integrations_allowed.include?('outreach')

        sweetalert_error('Unathorized Access!', 'Your account is NOT authorized to access Outreach Integrations. Please contact your account admin.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def client_api_integration
        return if (@client_api_integration = current_user.client.client_api_integrations.find_or_create_by(target: 'outreach'))

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end
    end
  end
end