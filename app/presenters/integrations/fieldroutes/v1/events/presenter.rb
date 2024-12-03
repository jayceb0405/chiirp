# frozen_string_literal: true

# app/presenters/integrations/fieldroutes/v1/events/presenter.rb
module Integrations
  module Fieldroutes
    module V1
      module Events
        class Presenter < Integrations::Fieldroutes::V1::Presenter
          attr_accessor :event
          attr_reader :client_api_integration_events, :event_id

          # Integrations::Fieldroutes::V1::Events::Presenter.new(client_api_integration: @client_api_integration)
          #   (req) client_api_integration: (ClientApiIntegration) or (Integer)

          def initialize(args = {})
            super

            @client_api_integration_events = @client.client_api_integrations.find_by(target: 'fieldroutes', name: 'events')
            @event                         = nil
            @event_id                      = nil
          end

          def campaign
            campaign_id.positive? ? Campaign.find_by(client_id: @client.id, id: campaign_id) : nil
          end

          def campaigns_allowed?
            @client.campaigns_count.positive?
          end

          def campaign_id
            @event&.dig(:actions, :campaign_id).to_i
          end

          def ext_tech_ids_for_select
            @fr_model.employees.select { |e| e.dig(:active) == '1' }.sort_by { |e| ["#{[e[:lname], e[:fname]].join(' ')}"] }.map { |e| ["#{[e[:fname], e[:lname]].join(' ')} (#{Integration::Fieldroutes::V1::Base::EMPLOYEE_TYPES[e[:type]]})", e[:employeeID]] }
          end

          def event_from_id=(event_id)
            @event_id = event_id
            @event    = (@client_api_integration_events.events[event_id] || {}).deep_symbolize_keys
          end

          def event_type_name
            Integration::Fieldroutes::V1::Base::EVENT_TYPE_OPTIONS.find { |et| et.second == event.dig(:criteria, :event_type) }&.first.to_s
          end

          def events
            @client_api_integration_events.events
          end

          def group
            @client.groups.find_by(id: group_id) || @client.groups.new
          end

          def groups_allowed?
            @client.groups_count.positive?
          end

          def group_id
            @event&.dig(:actions, :group_id).to_i
          end

          def range_max
            (@event&.dig(:criteria, :range_max) || 1_000).to_i
          end

          def request_body_appointment_status_change
            {
              client_id:          @client_api_integration.client_id,
              event_id:           @event_id,
              event:              'appointment_status_change',
              customerID:         '{{customerID}}',
              fname:              '{{fname}}',
              lname:              '{{lname}}',
              companyName:        '{{companyName}}',
              address:            '{{address}}',
              city:               '{{city}}',
              state:              '{{state}}',
              zip:                '{{zip}}',
              email:              '{{email}}',
              billingCompanyName: '{{billingCompanyName}}',
              billingFName:       '{{billingFName}}',
              billingLName:       '{{billingLName}}',
              billingAddress:     '{{billingAddress}}',
              billingCity:        '{{billingCity}}',
              billingState:       '{{billingState}}',
              billingZip:         '{{billingZip}}',
              totalDue:           '{{totalDue}}',
              age:                '{{age}}',
              serviceType:        '{{serviceType}}',
              serviceDate:        '{{serviceDate}}',
              description:        '{{description}}',
              serviceDescription: '{{serviceDescription}}',
              phone1:             '{{phone1}}',
              phone2:             '{{phone2}}',
              officeID:           '{{officeID}}',
              servicedBy:         '{{servicedBy}}',
              serviceStartTime:   '{{serviceStartTime}}',
              serviceEndTime:     '{{serviceEndTime}}',
              building:           '{{building}}',
              unitNumber:         '{{unitNumber}}',
              salesRep:           '{{salesRep}}',
              salesRep2:          '{{salesRep2}}',
              salesRep3:          '{{salesRep3}}',
              techName:           '{{techName}}',
              appointmentID:      '{{appointmentID}}',
              techPhone:          '{{techPhone}}',
              techEmail:          '{{techEmail}}',
              officeName:         '{{officeName}}',
              subscriptionID:     '{{subscriptionID}}'
            }.to_json
          end

          def request_body_subscription_status
            {
              client_id:          @client_api_integration.client_id,
              event_id:           @event_id,
              event:              'subscription_status',
              customerID:         '{{customerID}}',
              customerNumber:     '{{customerNumber}}',
              fname:              '{{fname}}',
              lname:              '{{lname}}',
              companyName:        '{{companyName}}',
              address:            '{{address}}',
              city:               '{{city}}',
              state:              '{{state}}',
              zip:                '{{zip}}',
              email:              '{{email}}',
              billingCompanyName: '{{billingCompanyName}}',
              billingFName:       '{{billingFName}}',
              billingLName:       '{{billingLName}}',
              billingAddress:     '{{billingAddress}}',
              billingCity:        '{{billingCity}}',
              billingState:       '{{billingState}}',
              billingZip:         '{{billingZip}}',
              totalDue:           '{{totalDue}}',
              age:                '{{age}}',
              customerID:         '{{customerID}}',
              subscriptionID:     '{{subscriptionID}}',
              description:        '{{description}}',
              dateCancelled:      '{{dateCancelled}}',
              dateAdded:          '{{dateAdded}}',
              agreementLink:      '{{agreementLink}}',
              contractValue:      '{{contractValue}}',
              annualValue:        '{{annualValue}}',
              phone1:             '{{phone1}}',
              phone2:             '{{phone2}}',
              conditions30:       '{{conditions30}}'
            }.to_json
          end

          def sorted_event_ids
            events.sort_by { |_key, value| [value['event_type']] }.map { |event_id, criteria| event_id }
          end

          def stage
            stage_id.positive? ? Stage.for_client(@client.id).find_by(id: stage_id) : nil
          end

          def stages_allowed?
            @client.stages_count.positive?
          end

          def stage_id
            @event&.dig(:actions, :stage_id).to_i
          end

          def stop_campaign_ids
            @event&.dig(:actions, :stop_campaign_ids).presence || []
          end

          def tag
            @client.tags.find_by(id: tag_id) || @client.tags.new
          end

          def tag_id
            @event&.dig(:actions, :tag_id).to_i
          end

          def total_max
            (@event&.dig(:criteria, :total_max) || range_max).to_i
          end

          def total_min
            (@event&.dig(:criteria, :total_min) || 0).to_i
          end

          def total_due_max
            (@event&.dig(:criteria, :total_due_max) || range_max).to_i
          end

          def total_due_min
            (@event&.dig(:criteria, :total_due_min) || 0).to_i
          end
        end
      end
    end
  end
end
