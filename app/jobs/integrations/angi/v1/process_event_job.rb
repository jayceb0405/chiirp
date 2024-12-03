# frozen_string_literal: true

# app/jobs/integrations/angi/v1/process_event_job.rb
module Integrations
  module Angi
    module V1
      class ProcessEventJob < ApplicationJob
        # description of this job
        # Integrations::Angi::V1::ProcessEventJob.perform_now()
        # Integrations::Angi::V1::ProcessEventJob.set(wait_until: 1.day.from_now).perform_later()
        # Integrations::Angi::V1::ProcessEventJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
        def initialize(**args)
          super

          @process = (args.dig(:process).presence || 'angi_process_event').to_s
        end

        # perform the ActiveJob
        #   (req) client_api_integration_id: (Integer)
        #   (req) client_id:                 (Integer)
        #   (req) event_id:                  (String)
        #   (opt) process_events:            (Boolean / default: false)
        #   (req) raw_params:                (Hash)
        def perform(**args)
          super

          return unless Integer(args.dig(:client_api_integration_id), exception: false).present? && Integer(args.dig(:client_id), exception: false).present? &&
                        args.dig(:event_id).to_s.present? && args.dig(:raw_params).present? &&
                        (client_api_integration = ClientApiIntegration.find_by(client_id: args.dig(:client_id).to_i, target: 'angi', name: '')) &&
                        (event = client_api_integration.client.client_api_integrations.find_by(target: 'angi', name: 'events')&.events&.dig(args[:event_id])&.deep_symbolize_keys) &&
                        (ag_model = Integration::Angi::V1::Base.new(client_api_integration)) && ag_model.valid_credentials? &&
                        (contact = ag_model.contact(raw_params: args.dig(:raw_params), client_id: args[:client_id]))

          # save params to Contact::RawPosts
          contact.raw_posts.create(ext_source: 'angi', ext_id: event.dig(:criteria, :event_type), data: args.dig(:raw_params))

          contact.messages.create({
                                    automated:  false,
                                    from_phone: contact.primary_phone&.phone.to_s.strip.presence || 'angi',
                                    message:    collect_message(**args, event_type: event.dig(:criteria, :event_type)),
                                    msg_type:   'textinother',
                                    status:     'received',
                                    to_phone:   contact.latest_client_phonenumber(default_ok: true, phone_numbers_only: true)&.phonenumber.to_s
                                  })

          Integrations::Angi::V1::ProcessActionsForEventJob.perform_later(
            client_api_integration_id: client_api_integration.id,
            client_id:                 args[:client_id],
            contact_id:                contact.id,
            event_id:                  args[:event_id],
            process_events:            args.dig(:process_events),
            raw_params:                args[:raw_params]
          )
        end

        private

        def collect_message(**args)
          return 'Unable to parse Angi data.' unless args[:event_type].present?

          case args[:event_type].to_s
          when 'ads'
            [
              "Source: #{args.dig(:raw_params, :Source)}",
              "Description: #{args.dig(:raw_params, :Description)}",
              "Category: #{args.dig(:raw_params, :Category)}"
            ].join("\r\n")
          when 'leads'
            response = [
              "Task Name: #{args.dig(:raw_params, :taskName)}",
              "Comments: #{args.dig(:raw_params, :comments)}"
            ]

            args.dig(:raw_params, :interview).each do |question|
              response << "#{question[:question]}: #{question[:answer]}"
            end

            response.join("\r\n")
          else
            'Invalid Angi event type.'
          end
        end
      end
    end
  end
end
