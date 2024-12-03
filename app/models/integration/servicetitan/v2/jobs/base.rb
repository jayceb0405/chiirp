# frozen_string_literal: true

# app/models/Integration/servicetitan/v2/jobs/base.rb
module Integration
  module Servicetitan
    module V2
      module Jobs
        module Base
          include Servicetitan::V2::Jobs::CancelReasons
          include Servicetitan::V2::Jobs::Imports
          include Servicetitan::V2::Jobs::JobTypes

          class ServiceTitanJobsError < StandardError; end

          # package a job booking and send it to ServiceTitan
          # st_model.package_job( contact: Contact, )
          #   (req) contact:              (Contact)
          #   (req) business_unit_id:     (String)
          #           ~ or ~
          #         business_unit_string: (String)
          #   (req) job_type_id:          (String)
          #           ~ or ~
          #         job_type_string:      (String)
          #   (req) ext_tech_id:          (String)
          #           ~ or ~
          #         technician_string:    (String)
          #   (req) campaign_id:          (String)
          #           ~ or ~
          #         campaign_string:      (String)
          #   (opt) tag_string:           (String)
          #   (opt) start_time:           (Time)
          #   (opt) end_time:             (Time)
          #   (opt) description:          (String)
          def package_post_job(args = {})
            JsonLog.info 'Integration::Servicetitan::V2::Jobs::Base.package_job', { args: }
            contact = args.dig(:contact)

            return unless contact.is_a?(Contact) && (customer_id = contact.ext_references.find_by(target: 'servicetitan')&.ext_id).present? &&
                          self.valid_credentials?

            business_unit_id     = args.dig(:business_unit_id).to_s
            business_unit_string = args.dig(:business_unit_string).to_s.strip

            if business_unit_id.blank? && business_unit_string.present?
              business_unit_id = @st_model.business_units.filter_map { |bu| bu[:name].strip == business_unit_string ? bu[:id] : nil }
              business_unit_id = business_unit_id.present? ? business_unit_id[0].to_s : ''
            end

            if business_unit_id.blank?
              error = ServiceTitanJobsError.new('Unable to create job. Missing ServiceTitan Business Unit ID.')
              error.set_backtrace(BC.new.clean(caller))

              Appsignal.report_error(error) do |transaction|
                # Only needed if it needs to be different or there's no active transaction from which to inherit it
                Appsignal.set_action('Integration::Servicetitan::V2::Jobs::Base.package_post_job')

                # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
                Appsignal.add_params(args)

                Appsignal.set_tags(
                  error_level: 'error',
                  error_code:  0
                )
                Appsignal.add_custom_data(
                  file: __FILE__,
                  line: __LINE__
                )
              end

              return
            end

            job_type_id     = args.dig(:job_type_id).to_s
            job_type_string = args.dig(:job_type_string).to_s.strip

            if job_type_id.blank? && job_type_string.present?
              job_type_id = @st_model.job_types.filter_map { |jt| jt[0].strip == job_type_string ? jt[1] : nil }
              job_type_id = job_type_id.present? ? job_type_id[0].to_s : ''
            end

            if job_type_id.blank?
              error = ServiceTitanJobsError.new('Unable to create job. Missing ServiceTitan Job Type ID.')
              error.set_backtrace(BC.new.clean(caller))

              Appsignal.report_error(error) do |transaction|
                # Only needed if it needs to be different or there's no active transaction from which to inherit it
                Appsignal.set_action('Integration::Servicetitan::V2::Jobs::Base.package_post_job')

                # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
                Appsignal.add_params(args)

                Appsignal.set_tags(
                  error_level: 'error',
                  error_code:  0
                )
                Appsignal.add_custom_data(
                  file: __FILE__,
                  line: __LINE__
                )
              end

              return
            end

            ext_tech_id       = args.dig(:ext_tech_id).to_s
            technician_string = args.dig(:technician_string).to_s.strip

            if ext_tech_id.blank? && technician_string.present?
              ext_tech_id = technicians.filter_map { |t| t.dig(:name).strip == technician_string ? t.dig(:id) : nil }
              ext_tech_id = ext_tech_id.present? ? ext_tech_id[0].to_s : ''
            end

            if ext_tech_id.blank?
              error = ServiceTitanJobsError.new('Unable to create job. Missing ServiceTitan Technician ID.')
              error.set_backtrace(BC.new.clean(caller))

              Appsignal.report_error(error) do |transaction|
                # Only needed if it needs to be different or there's no active transaction from which to inherit it
                Appsignal.set_action('Integration::Servicetitan::V2::Jobs::Base.package_post_job')

                # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
                Appsignal.add_params(args)

                Appsignal.set_tags(
                  error_level: 'error',
                  error_code:  0
                )
                Appsignal.add_custom_data(
                  file: __FILE__,
                  line: __LINE__
                )
              end

              return
            end

            campaign_id     = args.dig(:campaign_id).to_s
            campaign_string = args.dig(:campaign_string).to_s.strip

            if campaign_id.blank? && campaign_string.present?
              campaign_id = @st_model.campaigns(raw: true).filter_map { |c| c[:name].strip == campaign_string ? c[:id] : nil }
              campaign_id = campaign_id.present? ? campaign_id[0].to_s : ''
            end

            if campaign_id.blank?
              error = ServiceTitanJobsError.new('Unable to create job. Missing ServiceTitan Campaign ID.')
              error.set_backtrace(BC.new.clean(caller))

              Appsignal.report_error(error) do |transaction|
                # Only needed if it needs to be different or there's no active transaction from which to inherit it
                Appsignal.set_action('Integration::Servicetitan::V2::Jobs::Base.package_post_job')

                # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
                Appsignal.add_params(args)

                Appsignal.set_tags(
                  error_level: 'error',
                  error_code:  0
                )
                Appsignal.add_custom_data(
                  file: __FILE__,
                  line: __LINE__
                )
              end

              return
            end

            @st_client.locations(customer_id:)
            location_id = @st_client.success? ? @st_client.result&.first&.dig(:id).to_s : ''

            if location_id.blank?
              error = ServiceTitanJobsError.new('Unable to create job. Missing ServiceTitan Location ID.')
              error.set_backtrace(BC.new.clean(caller))

              Appsignal.report_error(error) do |transaction|
                # Only needed if it needs to be different or there's no active transaction from which to inherit it
                Appsignal.set_action('Integration::Servicetitan::V2::Jobs::Base.package_post_job')

                # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
                Appsignal.add_params(args)

                Appsignal.set_tags(
                  error_level: 'error',
                  error_code:  0
                )
                Appsignal.add_custom_data(
                  file: __FILE__,
                  line: __LINE__
                )
              end

              return
            end

            # location was found
            @st_client.create_job(
              business_unit_id:,
              campaign_id:,
              customer_id:,
              description:      args.dig(:description).to_s,
              end_time:         args.dig(:end_time) || 2.hours.from_now,
              ext_tech_id:,
              job_type_id:,
              location_id:,
              start_time:       args.dig(:start_time) || Time.current,
              tag_name:         args.dig(:tag_string).to_s
            )

            return if @st_client.success?

            error = ServiceTitanJobsError.new("Unable to create job. #{@st_client.message}")
            error.set_backtrace(BC.new.clean(caller))

            Appsignal.report_error(error) do |transaction|
              # Only needed if it needs to be different or there's no active transaction from which to inherit it
              Appsignal.set_action('Integration::Servicetitan::V2::Jobs::Base.package_post_job')

              # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
              Appsignal.add_params(args)

              Appsignal.set_tags(
                error_level: 'error',
                error_code:  0
              )
              Appsignal.add_custom_data(
                file: __FILE__,
                line: __LINE__
              )
            end
          end

          def scheduled_dates(first_appointment, last_appointment)
            if (start = Chronic.parse(first_appointment.dig(:start))) && start.respond_to?(:strftime) && start > Time.current
              scheduled_start_at                = Chronic.parse(first_appointment.dig(:start))
              scheduled_end_at                  = Chronic.parse(first_appointment.dig(:end))
              scheduled_arrival_window_start_at = Chronic.parse(first_appointment.dig(:arrivalWindowStart))
              scheduled_arrival_window_end_at   = Chronic.parse(first_appointment.dig(:arrivalWindowEnd))
            elsif Chronic.parse(last_appointment.dig(:start)).respond_to?(:strftime)
              scheduled_start_at                = Chronic.parse(last_appointment.dig(:start))
              scheduled_end_at                  = Chronic.parse(last_appointment.dig(:end))
              scheduled_arrival_window_start_at = Chronic.parse(last_appointment.dig(:arrivalWindowStart))
              scheduled_arrival_window_end_at   = Chronic.parse(last_appointment.dig(:arrivalWindowEnd))
            else
              scheduled_start_at                = nil
              scheduled_end_at                  = nil
              scheduled_arrival_window_start_at = nil
              scheduled_arrival_window_end_at   = nil
            end

            [scheduled_start_at, scheduled_end_at, scheduled_arrival_window_start_at, scheduled_arrival_window_end_at]
          end

          # receive JSON JobComplete data and update Contact
          # st_model.update_contact_from_job()
          #   (req) st_job_model:                   (Hash)
          #   (opt) st_customer_model:              (Hash)
          #   (opt) ok_to_process_estimate_actions: (Boolean)
          def update_contact_from_job(st_job_model:, st_customer_model: {}, ok_to_process_estimate_actions: false)
            JsonLog.info 'Integration::Servicetitan::V2::Jobs::Base.update_contact_from_job', { st_job_model:, st_customer_model:, ok_to_process_estimate_actions: }

            return nil unless st_job_model.present? && self.valid_credentials? &&
                              ((st_customer_model.present? && (contact = self.update_contact_from_customer(st_customer_model:))) ||
                               (st_job_model.dig(:customer).present? && (contact = self.update_contact_from_customer(st_customer_model: (st_customer_model = st_job_model[:customer])))) ||
                               (st_job_model.dig(:customerId).present? && (contact = self.update_contact_from_customer(st_customer_model: (st_customer_model = @st_client.customer(st_job_model[:customerId]))))))

            if contact.valid?
              Integrations::Servicetitan::V2::Estimates::UpdateContactEstimatesJob.set(wait_until: 2.minutes.from_now).perform_later(
                contact_id:                     contact.id,
                ok_to_process_estimate_actions:,
                st_customer_model:,
                st_job_model:
              )

              Contacts::Tags::ApplyByNameJob.perform_now(
                contact_id: contact.id,
                tag_name:   st_job_model.dig(:businessUnit, :name)
              )
              Contacts::Tags::ApplyByNameJob.perform_now(
                contact_id: contact.id,
                tag_name:   st_job_model.dig(:type, :name)
              )
            else
              JsonLog.info 'Integration::Servicetitan::V2::Jobs::Base.update_contact_from_job', { contact_errors: contact.errors.full_messages.join(' '), st_job_model:, ok_to_process_estimate_actions:, contact: }, client_id: @client.id, contact_id: contact&.id
              contact = nil
            end

            contact
          end

          # update Contact from incoming JobCompleted webhook
          # st_model.update_contact_from_job_completed_webhook()
          #   (opt) job_complete_params:    (Hash)
          def update_contact_from_job_completed_webhook(job_complete_params)
            method_description = 'Integration::Servicetitan::V2::Jobs::Base.update_contact_from_job_completed_webhook'
            valid_credentials  = self.valid_credentials?
            JsonLog.info method_description, { job_complete_params_class: job_complete_params.class, valid_credentials: }
            return unless (job_complete_params.is_a?(Hash) || job_complete_params.is_a?(ActionController::Parameters)) && valid_credentials

            job_complete_params = job_complete_params.deep_symbolize_keys

            contact = self.update_contact_from_job(st_job_model: job_complete_params, ok_to_process_estimate_actions: true)
            JsonLog.info method_description, { contact: }

            return unless contact

            contact_api_integration = self.update_contact_api_integration(contact, job_complete_params)

            # save/update Contact::Job after saving raw posts
            contact_job_id = self.update_contact_job_from_webhook(contact, job_complete_params).dig(:contact_job)&.id

            self.apply_servicetitan_tags(contact, job_complete_params.dig(:tags))

            if self.duplicate_webhook?(job_complete_params.dig(:historyItemId), contact_api_integration)
              JsonLog.info method_description, { duplicate_webhook: true }
              return
            end

            # save params to Contact::RawPosts
            raw_post = contact.raw_posts.create(ext_source: 'servicetitan', ext_id: 'jobcomplete', data: job_complete_params)
            jsonlog_with_raw_post(method_description:, raw_post:, contact:, data: job_complete_params)

            Integrations::Servicetitan::V2::Events::ProcessActionsForEventJob.perform_later(
              action_type:      'job_complete',
              business_unit_id: job_complete_params.dig(:businessUnit, :id),
              contact_id:       contact.id,
              contact_job_id:,
              customer_type:    job_complete_params.dig(:customer, :type),
              ext_tag_ids:      self.tag_names_to_ids((job_complete_params.dig(:tags)&.map { |t| t[:name] } || [])),
              ext_tech_id:      @st_client.parse_ext_tech_id_from_job_assignments_model(job_complete_params.dig(:jobAssignments)),
              job_type_id:      job_complete_params.dig(:type, :id),
              membership:       job_complete_params.dig(:customer, :hasActiveMembership),
              total_amount:     job_complete_params.dig(:invoice, :total)
            )
          end

          # update Contact data from a JobRescheduled webhook
          # st_model.update_contact_from_job_rescheduled_webhook()
          #   (opt) job_rescheduled_params: (Hash)
          def update_contact_from_job_rescheduled_webhook(job_rescheduled_params)
            method_description = 'Integration::Servicetitan::V2::Jobs::Base.update_contact_from_job_rescheduled_webhook'
            valid_credentials  = self.valid_credentials?
            JsonLog.info method_description, { job_rescheduled_params_class: job_rescheduled_params.class, valid_credentials: }
            return unless (job_rescheduled_params.is_a?(Hash) || job_rescheduled_params.is_a?(ActionController::Parameters)) && valid_credentials

            job_rescheduled_params = job_rescheduled_params.deep_symbolize_keys

            @st_client.parse_customer(st_customer_model: job_rescheduled_params.dig(:customer))
            contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: @client_api_integration.client_id, phones: @st_client.result[:phones], ext_refs: { 'servicetitan' => @st_client.result[:customer_id] })
            JsonLog.info method_description, { st_client_success: @st_client.success?, contact: }

            return unless @st_client.success? && contact

            if contact.update(@st_client.result[:contact])
              contact_api_integration = self.update_contact_api_integration(contact, job_rescheduled_params)

              if (contact_job_result = self.update_contact_job_from_webhook(contact, job_rescheduled_params)).dig(:contact_job)
                start_date_changed = contact_job_result.dig(:scheduled_start_at_changed)
                JsonLog.info method_description, { start_date_changed: }
              else
                start_date_changed = nil
              end

              self.update_contact_custom_fields(contact)
              self.apply_servicetitan_tags(contact, job_rescheduled_params.dig(:tags))

              if self.duplicate_webhook?(job_rescheduled_params.dig(:historyItemId), contact_api_integration)
                JsonLog.info method_description, { duplicate_webhook: true }
                return
              end

              # save params to Contact::RawPosts
              raw_post = contact.raw_posts.create(ext_source: 'servicetitan', ext_id: 'jobrescheduled', data: job_rescheduled_params)
              jsonlog_with_raw_post(method_description:, raw_post:, contact:, data: job_rescheduled_params)

              Integrations::Servicetitan::V2::Events::ProcessActionsForEventJob.perform_later(
                action_type:        'job_rescheduled',
                business_unit_id:   job_rescheduled_params.dig(:businessUnit, :id),
                contact_id:         contact.id,
                contact_job_id:     contact_job_result.dig(:contact_job)&.id,
                customer_type:      job_rescheduled_params.dig(:customer, :type),
                ext_tag_ids:        self.tag_names_to_ids((job_rescheduled_params.dig(:tags)&.map { |t| t[:name] } || [])),
                ext_tech_id:        @st_client.parse_ext_tech_id_from_job_assignments_model(job_rescheduled_params.dig(:jobAssignments)),
                job_type_id:        job_rescheduled_params.dig(:type, :id),
                membership:         job_rescheduled_params.dig(:customer, :hasActiveMembership),
                start_date_changed:,
                total_amount:       job_rescheduled_params.dig(:invoice, :total)
              )
            else
              JsonLog.info(method_description, { errors: contact.errors.full_messages })
            end
          end

          # update Contact data from a JobScheduled webhook
          # st_model.update_contact_from_job_scheduled_webhook()
          #   (opt) job_scheduled_params:   (Hash)
          def update_contact_from_job_scheduled_webhook(job_scheduled_params)
            method_description = 'Integration::Servicetitan::V2::Jobs::Base.update_contact_from_job_scheduled_webhook'
            valid_credentials  = self.valid_credentials?
            JsonLog.info method_description, { job_scheduled_params_class: job_scheduled_params.class, valid_credentials: }
            return unless (job_scheduled_params.is_a?(Hash) || job_scheduled_params.is_a?(ActionController::Parameters)) && valid_credentials

            job_scheduled_params = job_scheduled_params.deep_symbolize_keys

            @st_client.parse_customer(st_customer_model: job_scheduled_params.dig(:customer))
            contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: @client_api_integration.client_id, phones: @st_client.result[:phones], ext_refs: { 'servicetitan' => @st_client.result[:customer_id] })
            JsonLog.info method_description, { st_client_success: @st_client.success?, contact: }

            return unless @st_client.success? && contact

            if contact.update(@st_client.result[:contact])
              contact_api_integration = self.update_contact_api_integration(contact, job_scheduled_params)

              # save/update Contact::Job after saving raw posts
              contact_job_id = self.update_contact_job_from_webhook(contact, job_scheduled_params).dig(:contact_job)&.id

              self.update_contact_custom_fields(contact)
              self.apply_servicetitan_tags(contact, job_scheduled_params.dig(:tags))

              if self.duplicate_webhook?(job_scheduled_params.dig(:historyItemId), contact_api_integration)
                JsonLog.info method_description, { duplicate_webhook: true }
                return
              end

              # save params to Contact::RawPosts
              raw_post = contact.raw_posts.create(ext_source: 'servicetitan', ext_id: 'jobscheduled', data: job_scheduled_params)
              jsonlog_with_raw_post(method_description:, raw_post:, contact:, data: job_scheduled_params)

              Integrations::Servicetitan::V2::Events::ProcessActionsForEventJob.perform_later(
                action_type:      'job_scheduled',
                business_unit_id: job_scheduled_params.dig(:businessUnit, :id),
                contact_id:       contact.id,
                contact_job_id:,
                customer_type:    job_scheduled_params.dig(:customer, :type),
                ext_tag_ids:      self.tag_names_to_ids((job_scheduled_params.dig(:tags)&.map { |t| t[:name] } || [])),
                ext_tech_id:      @st_client.parse_ext_tech_id_from_job_assignments_model(job_scheduled_params.dig(:jobAssignments)),
                job_type_id:      job_scheduled_params.dig(:type, :id),
                membership:       job_scheduled_params.dig(:customer, :hasActiveMembership),
                total_amount:     job_scheduled_params.dig(:invoice, :total)
              )
            else
              JsonLog.info(method_description, { errors: contact.errors.full_messages })
            end
          end

          # update Contacts::Job from ServiceTitan job model
          # st_model.update_contact_job_from_job_model()
          #   (req) contact:      (Contact)
          #   (req) st_job_model: (Hash)
          def update_contact_job_from_job_model(contact, st_job_model)
            JsonLog.info 'Integration::Servicetitan::V2::Jobs::Base.update_contact_job_from_job_model', { st_job_model: }, contact_id: (contact.is_a?(Contact) ? contact.id : contact)
            return nil unless contact.is_a?(Contact) && st_job_model.is_a?(Hash) && st_job_model.dig(:id).present? &&
                              (contact_job = contact.jobs.find_or_initialize_by(ext_source: 'servicetitan', ext_id: st_job_model.dig(:id).to_s))

            contact_job.update(
              actual_completed_at: Chronic.parse(st_job_model.dig(:completedOn)) || contact_job.actual_completed_at,
              description:         (st_job_model.dig(:summary).presence || contact_job.description).to_s,
              status:              (st_job_model.dig(:jobStatus).presence || contact_job.status).to_s
            )

            contact_job
          end

          # st_model.update_contact_job_from_webhook()
          #   (req) contact:      (Contact)
          #   (req) event_params: (Hash)
          def update_contact_job_from_webhook(contact, event_params)
            JsonLog.info 'Integration::Servicetitan::V2::Jobs::Base.update_contact_job_from_webhook', { event_params: }, contact_id: (contact.is_a?(Contact) ? contact.id : contact)
            return nil unless event_params.dig(:id).present? && (contact_job = contact.jobs.find_or_initialize_by(ext_source: 'servicetitan', ext_id: event_params.dig(:id).to_s)) && self.valid_credentials?

            scheduled_start_at, scheduled_end_at, scheduled_arrival_window_start_at, scheduled_arrival_window_end_at = self.scheduled_dates(event_params.dig(:firstAppointment), event_params.dig(:lastAppointment))
            scheduled_start_at_changed = scheduled_start_at != contact_job.scheduled_start_at

            contact_job.update(
              actual_completed_at:               Chronic.parse(event_params.dig(:completedOn)) || contact_job.actual_completed_at,
              address_01:                        (event_params.dig(:location, :address, :street).presence || contact_job.address_01).to_s,
              address_02:                        '',
              business_unit_id:                  (event_params.dig(:businessUnit, :id).presence || contact_job.business_unit_id).to_s,
              city:                              (event_params.dig(:location, :address, :city).presence || contact_job.city).to_s,
              country:                           (event_params.dig(:location, :address, :country).presence || contact_job.country).to_s,
              customer_type:                     (event_params.dig(:customer, :type).presence || contact_job.customer_type).to_s,
              description:                       '',
              ext_invoice_id:                    (event_params.dig(:invoice, :id).presence || contact_job.ext_invoice_id).to_s,
              ext_tech_id:                       (@st_client.parse_ext_tech_id_from_job_assignments_model(event_params.dig(:jobAssignments)).presence || contact_job.ext_tech_id).to_i,
              invoice_date:                      (event_params.dig(:invoice, :invoicedOn).present? ? Chronic.parse(event_params.dig(:invoice, :invoicedOn)) : contact_job.invoice_date).to_s,
              invoice_number:                    (event_params.dig(:invoice, :number).presence || contact_job.invoice_number).to_s,
              job_type:                          (event_params.dig(:type, :name).presence || contact_job.job_type).to_s,
              notes:                             '',
              outstanding_balance:               (event_params.dig(:invoice, :balance).presence || contact_job.outstanding_balance).to_d,
              postal_code:                       (event_params.dig(:location, :address, :zip).presence || contact_job.postal_code).to_s,
              scheduled_arrival_window:          0,
              scheduled_arrival_window_end_at:,
              scheduled_arrival_window_start_at:,
              scheduled_end_at:,
              scheduled_start_at:,
              state:                             (event_params.dig(:location, :address, :state).presence || contact_job.state).to_s,
              status:                            (event_params.dig(:status).presence || contact_job.status).to_s,
              total_amount:                      (event_params.dig(:invoice, :total).presence || contact_job.total_amount).to_d
            )

            event_params.dig(:invoice, :items)&.each do |item|
              if (lineitem = contact_job.lineitems.find_or_initialize_by(ext_id: item.dig(:id).to_s))
                lineitem.update(name: item.dig(:sku, :displayName).to_s, total: item.dig(:total).to_d)
              end
            end

            if (deleted_lineitems = contact_job.lineitems.pluck(:ext_id).map(&:to_i) - event_params.dig(:invoice, :items).map { |item| item.dig(:id) }.compact_blank).present?
              contact_job.lineitems.where(ext_id: deleted_lineitems).destroy_all
            end

            { contact_job:, scheduled_start_at_changed: }
          end
        end
      end
    end
  end
end
