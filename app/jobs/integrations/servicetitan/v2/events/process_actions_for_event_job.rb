# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/events/process_actions_for_event_job.rb
module Integrations
  module Servicetitan
    module V2
      module Events
        class ProcessActionsForEventJob < ApplicationJob
          # Integrations::Servicetitan::V2::Events::ProcessActionsForEventJob.set(wait_until: 1.day.from_now).perform_later()
          # Integrations::Servicetitan::V2::Events::ProcessActionsForEventJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(

          def initialize(**args)
            super

            @process          = (args.dig(:process).presence || 'servicetitan_events_process_actions').to_s
            @reschedule_secs  = 0
          end

          # perform the ActiveJob
          #   (req) contact_id:            (Contact)
          #   (req) action_type:           (String) call_completed, estimate, job_complete, job_scheduled, job_rescheduled, technician_dispatched
          #   (opt) business_unit_id:      (Integer / default: nil)
          #   (opt) call_direction:        (String / default: nil)
          #   (opt) call_duration:         (Integer / default: nil)
          #   (opt) call_reason_id:        (Integer / default: nil)
          #   (opt) call_type:             (String / default: nil)
          #   (opt) campaign_id:           (Integer / default: nil)
          #   (opt) campaign_name:         (String / default: nil)
          #   (opt) contact_estimate_id:   (Integer / default: nil)
          #   (opt) contact_job_id:        (Integer / default: nil)
          #   (opt) customer_type:         (String / default: nil)
          #   (opt) dismissed_estimate_id: (Integer / default: nil)
          #   (opt) ext_tag_ids:           (Array / default: [])
          #   (opt) ext_tech_id:           (String / default: nil)
          #   (opt) job_cancel_reason_ids: (Array / default: [])
          #   (opt) job_status:            (String / default: nil)
          #   (opt) job_status_changed:    (Boolean / default: false)
          #   (opt) job_type_id:           (Integer / default: nil)
          #   (opt) location_id:           (Integer / default: nil)
          #   (opt) membership:            (Boolean / default: false)
          #   (opt) membership_days_prior: (Integer / default: nil)
          #   (opt) membership_type_id:    (Integer / default: nil)
          #   (opt) orphaned_estimate:     (Boolean / default: false)
          #   (opt) st_membership_id:      (Integer / default: nil)
          #   (opt) membership_types:      (Array / default: [])
          #   (opt) open_estimate_id:      (Integer / default: nil)
          #   (opt) sold_estimate_id:      (Integer / default: nil)
          #   (opt) st_customer:           (Hash / default: { no: true, yes: true })
          #   (opt) start_date_changed:    (Boolean / default: false)
          #   (opt) total_amount:          (BigDecimal / default: nil)
          #   (opt) test:                  (Boolean / default: false)
          def perform(**args)
            super

            Rails.logger.info "Integrations::Servicetitan::V2::Events::ProcessActionsForEventsJob (failed): #{{ contact_id: args.dig(:contact_id), args: }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }" if args.dig(:contact_id).to_i.zero?

            return unless args.dig(:contact_id).to_i.positive? && args.dig(:action_type).to_s.present? &&
                          (contact = Contact.find_by(id: args[:contact_id].to_i)) &&
                          (client_api_integration = contact.client.client_api_integrations.find_by(target: 'servicetitan', name: ''))

            args[:sold_estimate]       = args.dig(:sold_estimate_id).to_i.positive? ? contact.estimates.find_by(id: args[:sold_estimate_id].to_i) : nil
            args[:open_estimate]       = args.dig(:sold_estimate_id).to_i.positive? || args.dig(:open_estimate_id).to_i.zero? ? nil : contact.estimates.find_by(id: args[:open_estimate_id].to_i)
            args[:dismissed_estimate]  = args.dig(:sold_estimate_id).to_i.positive? || args.dig(:open_estimate_id).to_i.positive? || args.dig(:dismissed_estimate_id).to_i.zero? ? nil : contact.estimates.find_by(id: args[:dismissed_estimate_id].to_i)
            args[:contact_estimate_id] = (args.dig(:contact_estimate_id) || args.dig(:sold_estimate_id) || args.dig(:open_estimate) || args.dig(:dismissed_estimate)).to_i
            response = { failed: [], passed: [] }

            client_api_integration.events.deep_symbolize_keys.select { |_key, values| values[:action_type] == args[:action_type].to_s }.each do |key, action|
              if event_criteria_met?(action, args)
                response[:passed] << key.to_s
              else
                response[:failed] << key.to_s
                next
              end

              membership_stop_campaigns(action, args.dig(:membership_event_status), contact)

              unless args.dig(:test).to_bool
                user_id = action.dig(:assign_contact_to_user).to_bool ? client_api_integration.employees&.dig(args.dig(:ext_tech_id).to_s).to_i : 0

                Rails.logger.info "Integrations::Servicetitan::V2::Events::ProcessActionsForEventsJob.perform: #{{ contact_id: contact.id, user_id:, action: }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"

                contact.assign_user(user_id) unless user_id.zero?
                contact.process_actions(
                  campaign_id:                action[:campaign_id].to_i,
                  contact_estimate_id:        args.dig(:contact_estimate_id).to_i,
                  contact_job_id:             args.dig(:contact_job_id).to_i,
                  contact_location_id:        args.dig(:location_id).to_i,
                  contact_membership_type_id: args.dig(:membership_type_id).to_i,
                  group_id:                   action[:group_id].to_i,
                  st_membership_id:           args.dig(:st_membership_id).to_i,
                  stage_id:                   action[:stage_id].to_i,
                  stop_campaign_ids:          action[:stop_campaign_ids],
                  tag_id:                     action[:tag_id].to_i,
                  user_id:
                )
              end
            end

            response
          end

          private

          def event_criteria_met?(action, args)
            return false if action.dig(:action_type) == 'estimate' && action.dig(:orphaned_estimates).to_bool != args.dig(:orphaned_estimates).to_bool
            return false unless self.business_units_match?(action, args.dig(:business_unit_id).to_i, args.dig(:orphaned_estimate))
            return false unless self.call_direction_matches?(action, args.dig(:call_direction).to_s)
            return false unless self.call_duration_matches?(action, args.dig(:call_duration).to_i)
            return false unless self.call_reason_id_matches?(action, args.dig(:call_reason_id))
            return false unless self.call_types_match?(action, args.dig(:call_type).to_s)
            return false unless self.campaign_id_matches?(action, args.dig(:campaign_id))
            return false unless self.campaign_name_matches?(action, args.dig(:campaign_name))
            return false unless self.customer_type_matches?(action, args.dig(:customer_type))
            return false unless self.estimate_status_matches?(action, args.dig(:sold_estimate), args.dig(:open_estimate), args.dig(:dismissed_estimate))
            return false unless self.estimate_total_within_range?(action, args.dig(:sold_estimate), args.dig(:open_estimate), args.dig(:dismissed_estimate))
            return false unless self.ext_tech_ids_match?(action, args.dig(:ext_tech_id), args.dig(:orphaned_estimate))
            return false unless self.job_status_changed?(action, args.dig(:job_status), args.dig(:job_cancel_reason_ids), args.dig(:job_status_changed))
            return false unless self.job_type_matches?(action, args.dig(:job_type_id).to_i, args.dig(:orphaned_estimate))
            return false unless self.membership_days_prior_matches?(action, args.dig(:membership_days_prior))
            return false unless self.membership_matches?(action, args.dig(:membership).to_bool ? 'active' : 'inactive', args.dig(:orphaned_estimate))
            return false unless self.membership_type_matches?(action, args.dig(:membership_type_id))
            return false unless self.membership_event_status_matches?(action, args.dig(:membership_event_status))
            return false unless self.st_customer?(action, args.dig(:st_customer))
            return false unless self.start_date_changes_only?(action, args.dig(:start_date_changed))
            return false unless self.tag_ids_exclude?(action, (args.dig(:ext_tag_ids) || []))
            return false unless self.tag_ids_include?(action, (args.dig(:ext_tag_ids) || []))
            return false unless self.total_within_range?(action, args.dig(:total_amount).to_d)

            true
          end

          def business_units_match?(action, business_unit_id, orphaned_estimate)
            %w[estimate job_scheduled job_rescheduled job_status_changed job_complete membership_expiration membership_service_event technician_dispatched].exclude?(action.dig(:action_type)) || (action.dig(:action_type) == 'estimate' && orphaned_estimate.to_bool) || action.dig(:business_unit_ids).blank? || action[:business_unit_ids].include?(business_unit_id)
          end

          def call_direction_matches?(action, call_direction)
            action.dig(:action_type) != 'call_completed' || action.dig(:call_directions).blank? || action[:call_directions].include?(call_direction)
          end

          def call_duration_matches?(action, call_duration)
            action.dig(:action_type) != 'call_completed' || (action.dig(:call_duration).to_i.zero? && action.dig(:call_duration_from).to_i.zero? && action.dig(:call_duration_to).to_i.zero?) || (action[:call_duration].to_i.positive? && action[:call_duration] >= call_duration) || (action[:call_duration_from].to_i >= 0 && action[:call_duration_to].to_i.positive? && call_duration.between?(action[:call_duration_from].to_i, action[:call_duration_to].to_i))
          end

          def call_reason_id_matches?(action, call_reason_id)
            action.dig(:action_type) != 'call_completed' || action.dig(:call_reason_ids).blank? || action.dig(:call_reason_ids)&.include?(call_reason_id.to_i)
          end

          def call_types_match?(action, call_type)
            action.dig(:action_type) != 'call_completed' || action.dig(:call_types).blank? || action[:call_types].include?(call_type)
          end

          def campaign_id_matches?(action, campaign_id)
            action.dig(:action_type) != 'call_completed' || action.dig(:campaign_ids).blank? || action.dig(:campaign_ids)&.include?(campaign_id.to_i)
          end

          def campaign_name_matches?(action, campaign_name)
            action.dig(:action_type) != 'call_completed' || action.dig(:campaign_name, :segment).blank? ||
              (action.dig(:campaign_name, :start).to_bool && campaign_name&.starts_with?(action.dig(:campaign_name, :segment).to_s)) ||
              (action.dig(:campaign_name, :end).to_bool && campaign_name&.ends_with?(action.dig(:campaign_name, :segment).to_s)) ||
              (action.dig(:campaign_name, :contains).to_bool && campaign_name&.include?(action.dig(:campaign_name, :segment).to_s))
          end

          def customer_type_matches?(action, customer_type)
            %w[call_completed estimate job_scheduled job_rescheduled job_status_changed job_complete technician_dispatched].exclude?(action.dig(:action_type)) || action.dig(:customer_type).blank? || action[:customer_type].include?(customer_type.to_s.downcase)
          end

          def estimate_status_matches?(action, sold_estimate, open_estimate, dismissed_estimate)
            action.dig(:action_type) != 'estimate' || %w[sold open dismissed expired].exclude?(action.dig(:status).to_s.downcase) ||
              (action.dig(:status).to_s.casecmp?('sold') && sold_estimate.present?) ||
              (action.dig(:status).to_s.casecmp?('open') && open_estimate.present?) ||
              (%w[dismissed expired].include?(action.dig(:status).to_s.downcase) && dismissed_estimate.present?)
          end

          def estimate_total_within_range?(action, sold_estimate, open_estimate, dismissed_estimate)
            action.dig(:action_type) != 'estimate' || %w[sold open dismissed expired].exclude?(action.dig(:status).to_s.downcase) || action.dig(:total_min) == action.dig(:total_max) ||
              (action.dig(:status).to_s.casecmp?('sold') && sold_estimate.present? && sold_estimate.total_amount.between?(action.dig(:total_min).to_d, action.dig(:total_max).to_d + 0.99)) ||
              (action.dig(:status).to_s.casecmp?('open') && open_estimate.present? && open_estimate.total_amount.between?(action.dig(:total_min).to_d, action.dig(:total_max).to_d + 0.99)) ||
              (%w[dismissed expired].include?(action.dig(:status).to_s.downcase) && dismissed_estimate.present? && dismissed_estimate.total_amount.between?(action.dig(:total_min).to_d, action.dig(:total_max).to_d + 0.99))
          end

          def ext_tech_ids_match?(action, ext_tech_id, orphaned_estimate)
            %w[call_completed estimate job_scheduled job_rescheduled job_status_changed job_complete technician_dispatched].exclude?(action.dig(:action_type)) || (action.dig(:action_type) == 'estimate' && orphaned_estimate.to_bool) || action.dig(:ext_tech_ids).blank? || action[:ext_tech_ids].include?(ext_tech_id)
          end

          def job_status_changed?(action, job_status, job_cancel_reason_ids, job_status_changed)
            action.dig(:action_type) != 'job_status_changed' || (job_status_changed.to_bool && action.dig(:new_status)&.include?(job_status.to_s.downcase))
            return true unless action.dig(:action_type) == 'job_status_changed'
            return false unless job_status_changed.to_bool

            if action.dig(:new_status)&.include?(job_status.to_s.downcase)

              if job_status.casecmp?('canceled')
                action.dig(:job_cancel_reason_ids).blank? || (job_cancel_reason_ids.present? && action.dig(:job_cancel_reason_ids)&.intersect?(job_cancel_reason_ids))
              else
                true
              end
            else
              false
            end
          end

          def job_type_matches?(action, job_type_id, orphaned_estimate)
            %w[estimate job_scheduled job_rescheduled job_status_changed job_complete technician_dispatched].exclude?(action.dig(:action_type)) || (action.dig(:action_type) == 'estimate' && orphaned_estimate.to_bool) || action.dig(:job_types).blank? || action[:job_types].include?(job_type_id)
          end

          def membership_days_prior_matches?(action, membership_days_prior)
            %w[membership_expiration membership_service_event].exclude?(action.dig(:action_type)) || action.dig(:membership_days_prior).blank? || membership_days_prior.blank? || action.dig(:membership_days_prior).to_i == membership_days_prior.to_i
          end

          def membership_event_status_matches?(action, membership_event_status)
            action.dig(:action_type) != 'membership_service_event' || action.dig(:membership_campaign_stop_statuses).blank? || membership_event_status.blank? || action.dig(:membership_campaign_stop_statuses).exclude?(membership_event_status)
          end

          def membership_matches?(action, membership, orphaned_estimate)
            %w[call_completed estimate job_scheduled job_rescheduled job_status_changed job_complete technician_dispatched].exclude?(action.dig(:action_type)) || (action.dig(:action_type) == 'estimate' && orphaned_estimate.to_bool) || action.dig(:membership).blank? || action[:membership].include?(membership)
          end

          def membership_stop_campaigns(action, membership_event_status, contact)
            return unless action.dig(:action_type) == 'membership_service_event' && action.dig(:campaign_id).to_i.positive? && action.dig(:membership_campaign_stop_statuses).present? && membership_event_status.present? && action.dig(:membership_campaign_stop_statuses).include?(membership_event_status)

            Contacts::Campaigns::StopJob.perform_now(
              campaign_id: action.dig(:campaign_id),
              contact_id:  contact.id
            )
          end

          def membership_type_matches?(action, membership_type_id)
            %w[membership_expiration membership_service_event].exclude?(action.dig(:action_type)) || action.dig(:membership_types).blank? || action[:membership_types].include?(membership_type_id)
          end

          def st_customer?(action, st_customer)
            action.dig(:action_type) != 'call_completed' || (!action.dig(:st_customer, :yes).to_bool && !action.dig(:st_customer, :no).to_bool) || (st_customer && action.dig(:st_customer, :yes)) || (!st_customer && action.dig(:st_customer, :no))
          end

          def start_date_changes_only?(action, start_date_changed)
            action.dig(:action_type) != 'job_rescheduled' || !action.dig(:start_date_changes_only).to_bool || start_date_changed.to_bool
          end

          def tag_ids_include?(action, ext_tag_ids)
            %w[call_completed estimate job_scheduled job_rescheduled job_status_changed job_complete technician_dispatched].exclude?(action.dig(:action_type)) || action.dig(:tag_ids_include).blank? || action[:tag_ids_include].intersect?(ext_tag_ids)
          end

          def tag_ids_exclude?(action, ext_tag_ids)
            %w[call_completed estimate job_scheduled job_rescheduled job_status_changed job_complete technician_dispatched].exclude?(action.dig(:action_type)) || action.dig(:tag_ids_exclude).blank? || !action[:tag_ids_exclude].intersect?(ext_tag_ids)
          end

          def total_within_range?(action, total)
            %w[estimate job_complete].exclude?(action.dig(:action_type)) || (action.dig(:total_min).to_d.zero? && action.dig(:total_max).to_d.zero?) || total.between?(action.dig(:total_min).to_d, action.dig(:total_max).to_d + 0.99)
          end
        end
      end
    end
  end
end
