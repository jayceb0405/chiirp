# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/reports/results_contact_job.rb
module Integrations
  module Servicetitan
    module V2
      module Reports
        class ResultsContactJob < ApplicationJob
          # Integrations::Servicetitan::V2::Reports::ResultsContactJob.set(wait_until: 1.day.from_now).perform_later()
          # Integrations::Servicetitan::V2::Reports::ResultsContactJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

          def initialize(**args)
            super

            @process          = (args.dig(:process).presence || 'servicetitan_report_results_contact').to_s
            @reschedule_secs  = 0
          end

          # perform the ActiveJob
          #   (req) client_id: (Integer)
          #   (req) fields:    (Array)
          #   (req) report:    (String)
          #   (req) result:    (Array)
          def perform(**args)
            super

            return unless args.dig(:client_id).to_i.positive? && args.dig(:fields).is_a?(Array) && args.dig(:report).is_a?(Hash) && args.dig(:result).is_a?(Array) &&
                          (client = Client.find_by(id: args[:client_id].to_i))

            args[:report]  = args[:report].deep_symbolize_keys
            name_position  = args[:fields].index { |obj| obj.dig(:name) == 'CustomerName' }
            phone_position = args[:fields].index { |obj| %w[CustomerPhone PhoneNumber LocationPhone].include?(obj.dig(:name)) }
            email_position = args[:fields].index { |obj| %w[CustomerEmail Email].include?(obj.dig(:name)) }
            id_position    = args[:fields].index { |obj| obj.dig(:name) == 'CustomerId' }

            contact_data = { client_id: client.id }
            contact_data[:ext_refs] = { 'servicetitan' => args[:result][id_position].to_i.to_s } unless id_position.nil?
            contact_data[:phones]   = args[:result][phone_position]&.split(',')&.map(&:strip)&.map { |p| [p => ContactPhone.joins(:contact).where(contact: { client_id: client.id }).find_by(phone: p.to_s.clean_phone(client.primary_area_code))&.label || 'other'] }&.flatten&.reduce({}, :merge) unless phone_position.nil?
            contact_data[:emails]   = args[:result][email_position]&.split(',')&.map(&:strip) unless email_position.nil?

            return unless (contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(contact_data))

            if name_position.present? && args[:result][name_position].present?
              parsed_name = args[:result][name_position].parse_name
              contact.lastname  = parsed_name[:lastname] if parsed_name[:lastname].present?
              contact.firstname = parsed_name[:firstname] if parsed_name[:firstname].present?
            end

            contact.save
            contact.process_actions(args.dig(:report, :actions))
          end

          def max_attempts
            10
          end

          def reschedule_at(current_time, attempts)
            if @reschedule_secs.positive?
              current_time + @reschedule_secs.seconds
            else
              current_time + ProcessError::Backoff.full_jitter(base: 5, cap: 10, retries: attempts).minutes
            end
          end
        end
      end
    end
  end
end
