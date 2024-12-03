# frozen_string_literal: true

# app/presenters/integrations/sendjim/v3/presenter.rb
module Integrations
  module Sendjim
    module V3
      # variables required by SendJim views
      class Presenter
        attr_accessor :push_contact
        attr_reader   :sendjim_webhook, :client_api_integration

        def initialize(args = {})
          self.client_api_integration = args.dig(:client_api_integration)
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

          @client               = @client_api_integration.client
          @push_contact         = nil
          @sendjim_quick_sends  = nil
          @sj_client            = Integrations::SendJim::V3::Sendjim.new(@client_api_integration.token)
          @sorted_push_contacts = nil
        end

        def connection_valid?
          Integration::Sendjim::V3::Sendjim.valid_token?(@client_api_integration)
        end

        def contact_imports_remaining(user_id)
          Integration::Sendjim::V3::Sendjim.contact_imports_remaining_string(user_id)
        end

        def push_contact_id
          @push_contact&.dig(:id).to_s
        end

        def push_contact_neighbor_count
          @push_contact&.dig(:neighbor_count).to_i
        end

        def push_contact_quick_send_id
          @push_contact&.dig(:quick_send_id).to_i
        end

        def push_contacts_quick_send_id_options
          self.sendjim_quick_sends&.map { |qs| ["#{qs.dig(:Name)} (#{qs.dig(:QuickSendSequences).sum { |qss| qss.dig(:CreditsCost).to_d }} Credits)", qs.dig(:QuickSendID)] }
        end

        def push_contact_quick_send_name
          self.sendjim_quick_sends&.find { |qs| qs[:QuickSendID] == @push_contact&.dig(:quick_send_id).to_i }&.dig(:Name).to_s
        end

        def push_contact_quick_send_type
          @push_contact&.dig(:quick_send_type).to_s.presence || 'quick_send_mailing'
        end

        def push_contact_radius
          @push_contact&.dig(:radius).to_f
        end

        def push_contact_same_street_only
          @push_contact&.dig(:same_street_only)&.to_bool
        end

        def push_contact_send_tags
          @push_contact&.dig(:send_tags)&.to_bool
        end

        def push_contact_tag
          @client.tags.find_by(id: self.push_contact_tag_id) || @client.tags.new
        end

        def push_contact_tag_id
          @push_contact&.dig(:tag_id).to_i
        end

        def push_contacts
          @client_api_integration.push_contacts&.map(&:deep_symbolize_keys) || []
        end

        def sendjim_quick_sends
          @sendjim_quick_sends ||= @sj_client.quick_sends
        end

        def sendjim_mailings_count
          Postcard.where(client_id: @client.id, target: 'sendjim', result: 'true').count
        end

        def sendjim_push_tag_count
          @client_api_integration.push_contacts.length
        end

        def sendjim_reference_count
          Contacts::ExtReference.joins(:contact).where(target: 'sendjim').where(contact: { client_id: @client.id }).count
        end

        def sorted_push_contacts
          unless @sorted_push_contacts
            tags = Tag.where(id: self.push_contacts.map { |pc| pc.dig(:tag_id) }).pluck(:id, :name)
            @sorted_push_contacts = self.push_contacts.map { |pc| pc.merge(tag_name: tags.select { |t| t.first == pc.dig(:tag_id) }&.flatten&.last.to_s) }.sort_by { |pc| pc.dig(:tag_name) }
          end

          @sorted_push_contacts
        end
      end
    end
  end
end
