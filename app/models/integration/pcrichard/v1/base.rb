# frozen_string_literal: true

# app/models/integration/pcrichard/v1/base.rb
module Integration
  module Pcrichard
    module V1
      class Base
        # pcrichard = Integration::Pcrichard::V1::Base.new(client_api_integration)
        # (req) client_api_integration: (ClientApiIntegration)
        def initialize(client_api_integration)
          self.client_api_integration = client_api_integration
        end

        def client_api_integration=(client_api_integration)
          @client_api_integration = case client_api_integration
                                    when ClientApiIntegration
                                      client_api_integration
                                    when Integer
                                      ClientApiIntegration.find_by(id: client_api_integration)
                                    else
                                      ClientApiIntegration.new(target: 'jobber', name: '')
                                    end
        end

        def contact_clear_custom_field_options(contact)
          # rubocop:disable Rails/SkipsModelValidations
          contact.contact_custom_fields.where(client_custom_field_id: custom_field_options_assignment_ids).update_all(var_value: '')
          # rubocop:enable Rails/SkipsModelValidations
        end

        def contact_custom_field_data(contact)
          contact_custom_fields = contact.contact_custom_fields.where(client_custom_field_id: custom_field_assignment_ids)
          custom_fields         = {}

          @client_api_integration.custom_fields.each do |key, value|
            custom_fields[key.to_sym] = contact_custom_fields.find { |x| x.client_custom_field_id == value }&.var_value.to_s.split(' - ').first.to_s
          end

          custom_fields
        end

        def contact_leads_custom_field_data(contact)
          contact_custom_fields = contact.contact_custom_fields.where(client_custom_field_id: leads_custom_field_assignment_ids)
          custom_fields         = {}

          @client_api_integration.leads.dig('custom_field_assignments').each do |key, value|
            custom_fields[key.to_sym] = contact_custom_fields.find { |x| x.client_custom_field_id == value }&.var_value
          end

          custom_fields
        end

        # return models selected by a Contact
        # pcrichard.contact_models_selected()
        # (req) contact: (Contact)
        def contact_models_selected(contact)
          contact_custom_field_data(contact).select { |k, _v| k.to_s[..6] == 'option_' }.values
        end

        def contact_orders_custom_field_data(contact)
          contact_custom_fields = contact.contact_custom_fields.where(client_custom_field_id: orders_custom_field_assignment_ids)
          custom_fields         = {}

          @client_api_integration.orders.dig('custom_field_assignments').each do |key, value|
            custom_fields[key.to_sym] = contact_custom_fields.find { |x| x.client_custom_field_id == value }&.var_value
          end

          custom_fields
        end

        # return a hash of all currently supported PC Richard models
        # pcrichard.currently_supported_models
        def currently_supported_models
          return [] unless (pcr_client = Integrations::PcRichard::V1::Base.new(@client_api_integration&.credentials))

          pcr_client.supported_models
        end

        def custom_field_assignment_ids
          @client_api_integration.custom_fields&.values || []
        end

        def custom_field_options_assignment_ids
          @client_api_integration.custom_fields.keep_if { |k, _v| k[..6] == 'option_' }.values
        end

        def leads_custom_field_assignment_ids
          @client_api_integration.leads.dig('custom_field_assignments')&.values || []
        end

        def orders_custom_field_assignment_ids
          @client_api_integration.orders.dig('custom_field_assignments')&.values || []
        end

        # submit completed data to PC Richard
        # pcrichard.submit_completed_to_pc_richard()
        #   (req) contact:             (Contact)
        #   (opt) contact_campaign_id: (Integer)
        #   (req) triggeraction:       (Triggeraction)
        def submit_completed_to_pc_richard(args = {})
          JsonLog.info 'Integration::Pcrichard::V1::Base.submit_completed_to_pc_richard', { args: }
          contact       = args.dig(:contact)
          triggeraction = args.dig(:triggeraction)

          return { success: false, message: 'Unable to create connection to PC Richard.' } unless (pcr_client = Integrations::PcRichard::V1::Base.new(@client_api_integration&.credentials))

          pcr_client.install_completed(
            invoice_number: contact.contact_custom_fields.find_by(client_custom_field_id: @client_api_integration.leads.dig('custom_field_assignments', 'invoice_number'))&.var_value,
            completed_date: Time.use_zone(contact.client.time_zone) { Chronic.parse(contact.contact_custom_fields.find_by(client_custom_field_id: triggeraction.completed.dig('date'))&.var_value) },
            notes:          contact.contact_custom_fields.find_by(client_custom_field_id: triggeraction.completed.dig('notes'))&.var_value,
            serial_number:  contact.contact_custom_fields.find_by(client_custom_field_id: triggeraction.completed.dig('serial_number'))&.var_value
          )

          return if pcr_client.success?

          contact.user.delay(
            priority: DelayedJob.job_priority('send_text_to_user'),
            queue:    DelayedJob.job_queue('send_text_to_user'),
            user_id:  contact.user_id,
            process:  'send_text_to_user'
          ).send_text(
            from_phone: 'user_number',
            content:    "PC Richard completed submittal for #{contact.fullname} failed! (#{pcr_client.message})"
          )
        end

        # change all selected models to '' and send 'invalid_zone' as first model
        # pcrichard.submit_invalid_zone_to_pc_richard()
        #   (req) contact:             (Contact)
        #   (opt) contact_campaign_id: (Integer)
        #   (opt) triggeraction_id:    (Integer)
        def submit_invalid_zone_to_pc_richard(args = {})
          JsonLog.info 'Integration::Pcrichard::V1::Base.submit_invalid_zone_to_pc_richard', { args: }

          return { success: false, message: 'Unable to create connection to PC Richard.' } unless (pcr_client = Integrations::PcRichard::V1::Base.new(@client_api_integration&.credentials))

          contact_clear_custom_field_options(args.dig(:contact))
          pcr_client.recommended_models(contact_custom_field_data(args.dig(:contact)).merge({ option_01: 'invalid_zone' }))

          { success: pcr_client.success?, message: pcr_client.message }
        end

        # submit suggested models & other data to PC Richard
        # pcrichard.submit_models_to_pc_richard()
        # (req) contact: (Contact)
        def submit_models_to_pc_richard(contact:)
          JsonLog.info 'Integration::Pcrichard::V1::Base.submit_models_to_pc_richard', contact_id: contact&.id
          return { success: false, message: 'Unable to create connection to PC Richard.' } unless (pcr_client = Integrations::PcRichard::V1::Base.new(@client_api_integration&.credentials))

          pcr_client.recommended_models(contact_custom_field_data(contact).merge(contact_leads_custom_field_data(contact)))

          contact.process_actions(
            campaign_id:       @client_api_integration.after_recommendations&.dig('campaign_id'),
            group_id:          @client_api_integration.after_recommendations&.dig('group_id'),
            stage_id:          @client_api_integration.after_recommendations&.dig('stage_id'),
            tag_id:            @client_api_integration.after_recommendations&.dig('tag_id'),
            stop_campaign_ids: @client_api_integration.after_recommendations&.dig('stop_campaign_ids')
          )

          { success: pcr_client.success?, message: pcr_client.message }
        end

        # submit scheduled data to PC Richard
        # pcrichard.submit_scheduled_to_pc_richard()
        #   (req) contact:             (Contact)
        #   (opt) contact_campaign_id: (Integer)
        #   (req) triggeraction:       (Triggeraction)
        def submit_scheduled_to_pc_richard(args = {})
          JsonLog.info 'Integration::Pcrichard::V1::Base.submit_scheduled_to_pc_richard', { args: }
          contact       = args.dig(:contact)
          triggeraction = args.dig(:triggeraction)

          return { success: false, message: 'Unable to create connection to PC Richard.' } unless (pcr_client = Integrations::PcRichard::V1::Base.new(@client_api_integration&.credentials))

          pcr_client.install_scheduled(
            invoice_number: contact.contact_custom_fields.find_by(client_custom_field_id: @client_api_integration.leads.dig('custom_field_assignments', 'invoice_number'))&.var_value,
            scheduled_date: Time.use_zone(contact.client.time_zone) { Chronic.parse(contact.contact_custom_fields.find_by(client_custom_field_id: triggeraction.scheduled.dig('date'))&.var_value) },
            notes:          contact.contact_custom_fields.find_by(client_custom_field_id: triggeraction.scheduled.dig('notes'))&.var_value
          )

          return if pcr_client.success?

          contact.user.delay(
            priority: DelayedJob.job_priority('send_text_to_user'),
            queue:    DelayedJob.job_queue('send_text_to_user'),
            user_id:  contact.user_id,
            process:  'send_text_to_user'
          ).send_text(
            from_phone: 'user_number',
            content:    "PC Richard schedule submittal for #{contact.fullname} failed! (#{pcr_client.message})"
          )
        end

        # update the selected ContactCustomField with the date the installation is completed
        # pcrichard.update_completed_installation_date(contact: Contact, completed_at: Date)
        #   (req) contact:      (Contact)
        #   (req) completed_at: (DateTime)
        def update_completed_installation_date(args = {})
          contact      = args.dig(:contact)
          completed_at = args.dig(:completed_at)

          return unless contact.is_a?(Contact) && completed_at.present? && completed_at.respond_to?(:iso8601) && contact.client.integrations_allowed.include?('pcrichard')

          Triggeraction.joins(trigger: :campaign).where(campaign: { client_id: contact.client_id }).where(action_type: 901).find_each do |triggeraction|
            contact.update_custom_fields(custom_fields: { triggeraction.completed.dig('date') => completed_at.utc.iso8601 }) if triggeraction.install_method == 'completed' && triggeraction.completed.dig('date').positive?
          end
        end

        # update selected Custom Fields with currently supported PC Richard model numbers
        # pcrichard.update_custom_fields_with_current_models
        def update_custom_fields_with_current_models
          return if (models = currently_supported_models.map { |m| "#{m.dig(:model)} - #{m.dig(:desc).delete(',')}" }.join(',')).blank?

          @client_api_integration.client.client_custom_fields.where(id: @client_api_integration.custom_fields.select { |k, _v| k[..6] == 'option_' }.values).each do |client_custom_field|
            client_custom_field.var_options[:string_options] = models
            client_custom_field.save
          end
        end

        def update_custom_fields_with_current_models_for_all_clients
          ClientApiIntegration.where(target: 'pcrichard', name: '').find_each do |client_api_integration|
            @client_api_integration = client_api_integration
            update_custom_fields_with_current_models
          end
        end

        # update the selected ContactCustomField with the date the installation is scheduled
        # pcrichard.update_scheduled_installation_date(contact: Contact, scheduled_at: Date)
        #   (req) contact:      (Contact)
        #   (req) completed_at: (DateTime)
        def update_scheduled_installation_date(args = {})
          contact      = args.dig(:contact)
          scheduled_at = args.dig(:scheduled_at)

          return unless contact.is_a?(Contact) && scheduled_at.present? && scheduled_at.respond_to?(:iso8601) && contact.client.integrations_allowed.include?('pcrichard')

          Triggeraction.joins(trigger: :campaign).where(campaign: { client_id: contact.client_id }).where(action_type: 901).find_each do |triggeraction|
            contact.update_custom_fields(custom_fields: { triggeraction.scheduled.dig('date') => scheduled_at.utc.iso8601 }) if triggeraction.install_method == 'scheduled' && triggeraction.scheduled.dig('date').positive?
          end
        end
      end
    end
  end
end
