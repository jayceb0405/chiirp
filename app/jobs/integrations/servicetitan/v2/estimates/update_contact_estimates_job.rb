# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/estimates/update_contact_estimates_job.rb
module Integrations
  module Servicetitan
    module V2
      module Estimates
        class UpdateContactEstimatesJob < ApplicationJob
          # update existing open estimates attached to a job from ServiceTitan for a Client
          # Integrations::Servicetitan::V2::Estimates::UpdateContactEstimatesJob.set(wait_until: 1.day.from_now).perform_later()
          # Integrations::Servicetitan::V2::Estimates::UpdateContactEstimatesJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

          def initialize(**args)
            super

            @process          = (args.dig(:process).presence || 'servicetitan_update_contact_estimates').to_s
            @reschedule_secs  = 0
          end

          # perform the ActiveJob
          #   (req) contact_id:                     (Integer)
          #   (req) st_estimate_models:             (ServiceTitan Estimate models array)
          #       ~ or ~
          #   (req) st_job_model:                   (ServiceTitan Job model)
          #       ~ or ~
          #   (req) st_job_id:                      (Integer)
          #
          #   (opt) actions:                        (Hash)
          #     (opt) campaign_id:       (Integer / default: 0)
          #     (opt) group_id:          (Integer / default: 0)
          #     (opt) stage_id:          (Integer / default: 0)
          #     (opt) tag_id:            (Integer / default: 0)
          #     (opt) stop_campaign_ids: (Array of Integers / default: [])
          #   (opt) ok_to_process_estimate_actions: (Boolean)
          #   (opt) st_customer_model:              (ServiceTitan Customer model Hash)
          #   (opt) st_location_model:              (ServiceTitan Location model Hash)
          #   (opt) orphaned_estimate:              (Boolean)
          #   (opt) user_id:                        (Integer)
          def perform(**args)
            super

            return unless args.dig(:contact_id).to_i.positive? && (contact = Contact.find_by(id: args[:contact_id].to_i)) &&
                          (args.dig(:st_estimate_models).present? || args.dig(:st_job_model).present? || args.dig(:st_job_id).to_i.positive?) &&
                          (client_api_integration = ClientApiIntegration.find_by(client_id: contact.client_id, target: 'servicetitan', name: '')) &&
                          (st_model = Integration::Servicetitan::V2::Base.new(client_api_integration)) && st_model.valid_credentials? &&
                          (st_client = Integrations::ServiceTitan::Base.new(client_api_integration.credentials))

            st_job_model                      = args.dig(:orphaned_estimate).to_bool ? {} : args.dig(:st_job_model).presence || st_client.job(args.dig(:st_job_id).to_i)
            st_estimate_models                = args.dig(:st_estimate_models).presence || st_client.estimates(job_id: st_job_model&.dig(:id))
            contact_estimate                  = nil
            contact_job                       = nil
            sold_estimate                     = nil
            open_estimate                     = nil
            dismissed_estimate                = nil
            sold_estimate_status_changed      = false
            open_estimate_status_changed      = false
            dismissed_estimate_status_changed = false

            st_estimate_models.each do |st_estimate_model|
              unless args.dig(:orphaned_estimate).to_bool
                st_job_model = st_job_model.presence || st_client.job(st_estimate_model.dig(:jobId))
                contact_job  = contact_job.presence || st_model.update_contact_job_from_job_model(contact, st_job_model)
              end

              if st_estimate_model.dig(:id).to_i.positive? && (contact_estimate = contact.estimates.find_or_initialize_by(ext_source: 'servicetitan', ext_id: st_estimate_model[:id]))
                previous_estimate_status = contact_estimate.status
                contact_estimate.update(
                  job_id:          contact_job&.id || contact_estimate.job_id,
                  status:          (st_estimate_model.dig(:status, :name).presence || contact_estimate.status).to_s.downcase,
                  total_amount:    st_estimate_model.dig(:items)&.sum { |i| i.dig(:total).to_d }.to_d,
                  notes:           (st_estimate_model.dig(:summary).presence || st_estimate_model.dig(:name).presence).to_s,
                  estimate_number: st_estimate_model.dig(:jobNumber).to_s
                )

                st_estimate_model.dig(:items)&.each do |item|
                  if (lineitem = contact_estimate.lineitems.find_or_initialize_by(ext_id: item.dig(:id).to_s))
                    lineitem.update(name: item.dig(:sku, :displayName).to_s, total: item.dig(:total).to_d)
                  end
                end

                if (deleted_lineitems = contact_estimate.lineitems.pluck(:ext_id).map(&:to_i) - st_estimate_model.dig(:items).map { |item| item.dig(:id) }.compact_blank).present?
                  contact_estimate.lineitems.where(ext_id: deleted_lineitems).destroy_all
                end

                st_customer_model = if args.dig(:st_customer_model).is_a?(Hash) && args[:st_customer_model].present?
                                      args[:st_customer_model]
                                    else
                                      st_job_model.dig(:customer, :type).present? ? {} : st_client.customer(st_job_model[:customerId])
                                    end
                st_location_model = if st_job_model.present? || st_estimate_model.dig(:locationId).to_i.positive?
                                      if args.dig(:st_location_model).is_a?(Hash) && args[:st_location_model].present?
                                        args[:st_location_model]
                                      else
                                        st_job_model.dig(:location, :address).present? ? {} : st_client.location(st_job_model[:locationId])
                                      end
                                    else
                                      {}
                                    end

                if st_job_model.present?
                  update_contact_estimate_from_st_job_model(contact_estimate, st_client, st_customer_model, st_job_model, st_location_model)
                elsif st_estimate_model.dig(:locationId).to_i.positive?
                  update_contact_estimate_from_st_location_model(contact_estimate, st_customer_model, st_location_model)
                elsif st_estimate_model.dig(:customerId).to_i.positive?
                  update_contact_estimate_from_st_customer_model(contact_estimate, st_customer_model)
                end

                case st_estimate_model.dig(:status, :name).to_s.downcase
                when 'sold'

                  if contact_estimate.lineitems.where(ext_id: client_api_integration.ignore_sold_with_line_items || []).none?
                    sold_estimate = contact_estimate if sold_estimate.nil? || contact_estimate.total_amount > sold_estimate&.total_amount.to_d
                    sold_estimate_status_changed ||= previous_estimate_status != contact_estimate.status
                  end
                when 'open'
                  open_estimate = contact_estimate if open_estimate.nil? || contact_estimate.total_amount > open_estimate&.total_amount.to_d
                  open_estimate_status_changed ||= previous_estimate_status != contact_estimate.status
                when 'dismissed', 'expired'
                  dismissed_estimate = contact_estimate if dismissed_estimate.nil? || contact_estimate.total_amount > dismissed_estimate&.total_amount.to_d
                  dismissed_estimate_status_changed ||= previous_estimate_status != contact_estimate.status
                end
              end
            end

            st_model.expire_open_contact_estimates(contact_job&.id)

            contact.process_actions(
              campaign_id:         args.dig(:actions, :campaign_id),
              stop_campaign_ids:   args.dig(:actions, :stop_campaign_ids),
              contact_estimate_id: contact_estimate&.id,
              contact_job_id:      contact_job&.id,
              group_id:            args.dig(:actions, :group_id),
              stage_id:            args.dig(:actions, :stage_id),
              tag_id:              args.dig(:actions, :tag_id),
              user_id:             args.dig(:user_id)
            )

            return unless args.dig(:ok_to_process_estimate_actions).to_bool && (sold_estimate_status_changed || open_estimate_status_changed || dismissed_estimate_status_changed)

            Integrations::Servicetitan::V2::Events::ProcessActionsForEventJob.perform_later(
              contact_id:            contact.id,
              action_type:           'estimate',
              business_unit_id:      st_job_model.dig(:businessUnitId) || st_job_model.dig(:businessUnit, :id),
              contact_estimate_id:   sold_estimate&.id || open_estimate&.id || dismissed_estimate&.id,
              contact_job_id:        contact_job&.id,
              customer_type:         sold_estimate&.customer_type.presence || open_estimate&.customer_type.presence || dismissed_estimate&.customer_type.presence,
              dismissed_estimate_id: dismissed_estimate&.id,
              ext_tag_ids:           st_model.tag_names_to_ids(contact.tags.pluck(:name)),
              ext_tech_id:           [sold_estimate&.ext_tech_id || open_estimate&.ext_tech_id || dismissed_estimate&.ext_tech_id].compact_blank.first.to_i,
              job_type_id:           st_job_model.dig(:jobTypeId) || st_job_model.dig(:type, :id),
              open_estimate_id:      open_estimate&.id,
              orphaned_estimate:     st_job_model.blank?,
              sold_estimate_id:      sold_estimate&.id,
              total_amount:          [sold_estimate&.total_amount || open_estimate&.total_amount || dismissed_estimate&.total_amount].delete_if { |t| t.nil? || t.zero? }.first.to_d
            )
          end
          # example: st_estimate_model {
          #   :id=>131436803,
          #   :jobId=>nil,
          #   :projectId=>0,
          #   :locationId=>131414119,
          #   :customerId=>131414114,
          #   :name=>"Labor Only for 40 Gallon Electric",
          #   :jobNumber=>"",
          #   :status=>{:value=>0, :name=>"Open"},
          #   :summary=>"",
          #   :createdOn=>"2023-08-28T16:53:47.31272Z",
          #   :modifiedOn=>"2023-08-28T16:54:13.97096Z",
          #   :soldOn=>nil,
          #   :soldBy=>nil,
          #   :active=>true,
          #   :items=>[
          #     {
          #       :id=>131438331,
          #         :sku=>{
          #           :id=>71144547,
          #           :name=>"WATER HEATER DISCLAIMER",
          #           :displayName=>"WATER HEATER DISCLAIMER | 6181",
          #           :type=>"Service",
          #           :soldHours=>0.0,
          #           :generalLedgerAccountId=>59310334,
          #           :generalLedgerAccountName=>"Third Party : Installation|266",
          #           :modifiedOn=>"2023-08-02T18:02:19.7927581Z"
          #         },
          #         :skuAccount=>"Third Party : Installation|266",
          #         :description=>"Your new water heater with a 10 YEAR LABOR WARRANTY. Installation includes new water shut off valves and new drain pan.",
          #         :membershipTypeId=>nil,
          #         :qty=>1.0,
          #         :unitRate=>999.0,
          #         :total=>999.0,
          #         :unitCost=>0.0,
          #         :totalCost=>0.0,
          #         :itemGroupName=>nil,
          #         :itemGroupRootId=>nil,
          #         :createdOn=>"2023-08-28T16:53:55.5659729Z",
          #         :modifiedOn=>"2023-08-28T16:54:13.9709568Z"
          #     }
          #   ],
          #   :externalLinks=>[],
          #   :subtotal=>999.0
          # }

          private

          # update Contacts::Estimate from ServiceTitan Customer model
          # update_contact_estimate_from_st_customer_model()
          #   (req) contact_estimate:  (Contacts::Estimate)
          #   (req) st_customer_model: (ServiceTitan Customer model Hash
          def update_contact_estimate_from_st_customer_model(contact_estimate, st_customer_model)
            return unless contact_estimate.is_a?(Contacts::Estimate) && st_customer_model.is_a?(Hash)

            contact_estimate.update(
              customer_type: (st_customer_model.dig(:type).presence || contact_estimate.customer_type).to_s,
              address_01:    (st_customer_model.dig(:address, :street).presence || contact_estimate.address_01).to_s,
              address_02:    '',
              city:          (st_customer_model.dig(:address, :city).presence || contact_estimate.city).to_s,
              state:         (st_customer_model.dig(:address, :state).presence || contact_estimate.state).to_s,
              postal_code:   (st_customer_model.dig(:address, :zip).presence || contact_estimate.postal_code).to_s,
              country:       (st_customer_model.dig(:address, :country).presence || contact_estimate.country).to_s
            )
          end

          # update Contacts::Estimate from ServiceTitan Job model
          # update_contact_estimate_from_st_job_model()
          #   (req) contact_estimate:  (Contacts::Estimate)
          #   (req) st_client:         (Integrations::ServiceTitan::Base)
          #   (req) st_customer_model: (ServiceTitan Customer model Hash)
          #   (req) st_job_model:      (ServiceTitan Job model Hash)
          #   (req) st_location_model: (ServiceTitan Location model Hash)
          def update_contact_estimate_from_st_job_model(contact_estimate, st_client, st_customer_model, st_job_model, st_location_model)
            return unless contact_estimate.is_a?(Contacts::Estimate) && st_job_model.is_a?(Hash) && st_customer_model.is_a?(Hash) && st_location_model.is_a?(Hash)

            if (start = Chronic.parse(st_job_model.dig(:firstAppointment, :start))) && start.respond_to?(:strftime) && start > Time.current
              scheduled_start_at                = Chronic.parse(st_job_model.dig(:firstAppointment, :start))
              scheduled_end_at                  = Chronic.parse(st_job_model.dig(:firstAppointment, :end))
              scheduled_arrival_window_start_at = Chronic.parse(st_job_model.dig(:firstAppointment, :arrivalWindowStart))
              scheduled_arrival_window_end_at   = Chronic.parse(st_job_model.dig(:firstAppointment, :arrivalWindowEnd))
            elsif Chronic.parse(st_job_model.dig(:lastAppointment, :start)).respond_to?(:strftime)
              scheduled_start_at                = Chronic.parse(st_job_model.dig(:lastAppointment, :start))
              scheduled_end_at                  = Chronic.parse(st_job_model.dig(:lastAppointment, :end))
              scheduled_arrival_window_start_at = Chronic.parse(st_job_model.dig(:lastAppointment, :arrivalWindowStart))
              scheduled_arrival_window_end_at   = Chronic.parse(st_job_model.dig(:lastAppointment, :arrivalWindowEnd))
            else
              scheduled_start_at                = nil
              scheduled_end_at                  = nil
              scheduled_arrival_window_start_at = nil
              scheduled_arrival_window_end_at   = nil
            end

            contact_estimate.update(
              customer_type:                     (st_job_model.dig(:customer, :type).presence || st_customer_model.dig(:type).presence || contact_estimate.customer_type).to_s,
              address_01:                        (st_job_model.dig(:location, :address, :street).presence || st_location_model.dig(:address, :street).presence || contact_estimate.address_01).to_s,
              address_02:                        '',
              city:                              (st_job_model.dig(:location, :address, :city).presence || st_location_model.dig(:address, :city).presence || contact_estimate.city).to_s,
              state:                             (st_job_model.dig(:location, :address, :state).presence || st_location_model.dig(:address, :state).presence || contact_estimate.state).to_s,
              postal_code:                       (st_job_model.dig(:location, :address, :zip).presence || st_location_model.dig(:address, :zip).presence || contact_estimate.postal_code).to_s,
              country:                           (st_job_model.dig(:location, :address, :country).presence || st_location_model.dig(:address, :country).presence || contact_estimate.country).to_s,
              scheduled_start_at:,
              scheduled_end_at:,
              scheduled_arrival_window_start_at:,
              scheduled_arrival_window_end_at:,
              scheduled_arrival_window:          0,
              ext_tech_id:                       (st_client.parse_ext_tech_id_from_job_assignments_model(st_job_model.dig(:jobAssignments)).presence || contact_estimate.ext_tech_id).to_i
            )
          end

          # update Contacts::Estimate from ServiceTitan Location model
          # update_contact_estimate_from_st_location_model()
          #   (req) contact_estimate:  (Contacts::Estimate)
          #   (req) st_customer_model: (ServiceTitan Customer model Hash)
          #   (req) st_location_model: (ServiceTitan Location model Hash)
          def update_contact_estimate_from_st_location_model(contact_estimate, st_customer_model, st_location_model)
            return unless contact_estimate.is_a?(Contacts::Estimate) &&
                          st_location_model.is_a?(Hash) && st_location_model.present? &&
                          st_customer_model.is_a?(Hash) && st_customer_model.present?

            contact_estimate.update(
              customer_type: (st_customer_model.dig(:type).presence || contact_estimate.customer_type).to_s,
              address_01:    (st_location_model.dig(:address, :street).presence || contact_estimate.address_01).to_s,
              address_02:    '',
              city:          (st_location_model.dig(:address, :city).presence || contact_estimate.city).to_s,
              state:         (st_location_model.dig(:address, :state).presence || contact_estimate.state).to_s,
              postal_code:   (st_location_model.dig(:address, :zip).presence || contact_estimate.postal_code).to_s,
              country:       (st_location_model.dig(:address, :country).presence || contact_estimate.country).to_s
            )
          end
        end
      end
    end
  end
end
