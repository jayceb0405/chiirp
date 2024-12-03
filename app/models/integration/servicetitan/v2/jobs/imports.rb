# frozen_string_literal: true

# app/models/Integration/servicetitan/v2/jobs/cancel_reasons.rb
module Integration
  module Servicetitan
    module V2
      module Jobs
        module Imports
          # st_model.import_contact_jobs()
          #   (req) contact:   (Contact)
          #   (opt) page:      (Integer)
          #   (opt) page_size: (Integer)
          #   (opt) user_id:   (Integer)
          def import_contact_jobs(args = {})
            JsonLog.info 'Integration::Servicetitan::V2::Jobs::Imports.import_contact_jobs', { args: }
            page        = (args.dig(:page) || -1).to_i
            page_size   = (args.dig(:page_size) || self.import_block_count).to_i

            return unless args.dig(:contact).is_a?(Contact) && self.valid_credentials? &&
                          (customer_id = args[:contact].ext_references.find_by(target: 'servicetitan')&.ext_id).present?

            if page == -1
              # get the ServiceTitan job count
              @st_client.job_count(customer_id:)

              return unless @st_client.success?

              # generate DelayedJobs to import all ServiceTitan customers
              (1..(@st_client.result.to_f / page_size).ceil).each do |p|
                data = {
                  contact:   args[:contact],
                  page:      p,
                  page_size:,
                  user_id:   args.dig(:user_id).to_i
                }
                self.delay(
                  run_at:              Time.current,
                  priority:            DelayedJob.job_priority('servicetitan_import_jobs'),
                  queue:               DelayedJob.job_queue('servicetitan_import_jobs'),
                  user_id:             args.dig(:user_id).to_i,
                  contact_id:          args[:contact].id,
                  triggeraction_id:    0,
                  contact_campaign_id: 0,
                  group_process:       0,
                  process:             'servicetitan_import_jobs',
                  data:
                ).import_jobs(data)
              end
            else
              # get the ServiceTitan job data for a specific customer
              @st_client.jobs(customer_id:, page:, page_size:)

              return unless @st_client.success?

              # import Jobs for Contact
              @st_client.result.each do |job|
                self.delay(
                  run_at:              Time.current,
                  priority:            DelayedJob.job_priority('servicetitan_import_job'),
                  queue:               DelayedJob.job_queue('servicetitan_import_job'),
                  user_id:             args.dig(:user_id).to_i,
                  contact_id:          args[:contact].id,
                  triggeraction_id:    0,
                  contact_campaign_id: 0,
                  group_process:       0,
                  process:             'servicetitan_import_job',
                  data:                { job: }
                ).update_contact_from_job(st_job_model: job)
              end
            end
          end

          # import a ServiceTitan job
          # st_model.import_job()
          #   (req) job_id:                 (Integer)
          #   (req) user_id:                (Integer)
          #   (opt) account_sub_types:      (Integer)
          #   (opt) account_types:          (Array)
          #   (opt) ext_tech_ids:           (Array)
          def import_job(args = {})
            JsonLog.info 'Integration::Servicetitan::V2::Jobs::Imports.import_job', { args: }

            return unless args.dig(:job_id).to_s.present? && args.dig(:user_id).to_i.positive? && self.valid_credentials?

            self.update_job_imports_remaining_count(Client.find_by(id: @client_api_integration.client_id), User.find_by(client_id: @client_api_integration.client_id, id: args.dig(:user_id)))

            return if (job = @st_client.job(args[:job_id])).blank?

            JsonLog.info 'Integration::Servicetitan::V2::Jobs::Imports.import_job', { job: }

            self.update_contact_from_job(st_job_model: job)

            data = {
              client_api_integration_ids: [@client_api_integration.id],
              company_id:                 job.dig(:companyID),
              event_object:               'appointment',
              event_type:                 'OnCreated',
              params:                     job,
              process_events:             false,
              raw_params:                 {},
              webhook_id:                 ''
            }
            result = self.event_process(data)

            return unless (contact = Contact.joins(:ext_references).find_by(client_id: @client_api_integration.client_id, ext_references: { target: 'servicetitan', ext_id: result.dig(:contact, :id) }))
            return unless result.dig(:order, :type).to_s.sub('work ', '').casecmp?(args.dig(:order_type).to_s)
            return unless args.dig(:ext_tech_ids).blank? || args.dig(:ext_tech_ids).intersect?([result.dig(:appointment, :ext_tech_id)])
            return unless args.dig(:account_types).blank? || args.dig(:account_types).include?(result.dig(:contact, :account_type).to_s.downcase)
            return unless args.dig(:account_sub_types).blank? || args.dig(:account_sub_types).include?(result.dig(:contact, :account_subtype).to_s.downcase)
            return unless args.dig(:order_groups).blank? || args.dig(:order_groups).include?(result.dig(:order, :group).to_s.downcase)
            return unless args.dig(:order_subgroups).blank? || args.dig(:order_subgroups).include?(result.dig(:order, :subgroup).to_s.downcase)
            return unless args.dig(:appointment_status).blank? || args.dig(:appointment_status).include?(result.dig(:appointment, :status).to_s.downcase)
            return unless args.dig(:job_types).blank? || args.dig(:job_types).include?(result.dig(:appointment, :job_type).to_s.downcase)
            return unless (args.dig(:commercial).to_bool && result.dig(:contact, :commercial).to_bool) || (args.dig(:residential).to_bool && !result.dig(:contact, :commercial).to_bool)
            return unless self.line_items_include?(
              order_type:          result.dig(:order, :type).to_s.sub('work ', ''),
              event_object:        'appointment',
              line_items:          Contacts::Job.find_by(id: result.dig(:contact_job_id))&.lineitems&.pluck(:ext_id).presence || Contacts::Estimate.find_by(id: result.dig(:contact_estimate_id))&.lineitems&.pluck(:ext_id).presence || [],
              line_items_criteria: args.dig(:line_items)
            )
            return unless self.qualifying_total?(
              order_type:   result.dig(:order, :type).to_s.sub('work ', ''),
              event_object: 'appointment',
              total_amount: Contacts::Job.find_by(id: result.dig(:contact_job_id))&.total_amount.presence || Contacts::Estimate.find_by(id: result.dig(:contact_estimate_id))&.total_amount.presence || [],
              total_min:    args.dig(:total_min),
              total_max:    args.dig(:total_max)
            )

            contact.process_actions(campaign_id: args.dig(:actions, :campaign_id), group_id: args.dig(:actions, :group_id), stage_id: args.dig(:actions, :stage_id), tag_id: args.dig(:actions, :tag_id), contact_job_id: result.dig(:contact_job_id), contact_estimate_id: result.dig(:contact_estimate_id))
          end

          # import ServiceTitan jobs
          # st_model.import_jobs()
          #   (opt) page:                      (Integer)
          #   (opt) page_size:                 (Integer)
          #   (opt) user_id:                   (Integer)
          def import_jobs(args)
            JsonLog.info 'Integration::Servicetitan::V2::Jobs::Imports.import_jobs', { args: }
            page      = (args.dig(:page) || -1).to_i
            page_size = (args.dig(:page_size) || self.import_jobs_block_size).to_i

            return unless self.valid_credentials?

            if page.negative?
              # break up ST Jobs into blocks
              @st_client.jobs_count(args)

              if @st_client.success?

                # generate DelayedJobs to import all ServiceTitan jobs (appointments)
                (0..(@st_client.result.to_f / page_size).ceil).each do |pp|
                  data = args.merge({
                                      page:      pp,
                                      page_size:
                                    })
                  self.delay(
                    run_at:              Time.current,
                    priority:            DelayedJob.job_priority('servicetitan_import_jobs_block'),
                    queue:               DelayedJob.job_queue('servicetitan_import_jobs_block'),
                    user_id:             args.dig(:user_id).to_i,
                    contact_id:          0,
                    triggeraction_id:    0,
                    contact_campaign_id: 0,
                    group_process:       1,
                    process:             'servicetitan_import_jobs_block',
                    data:
                  ).import_jobs(data)
                end
              end
            else
              # get the ServiceTitan job data for a specific page
              @st_client.jobs(args.merge(page:, page_size:))

              if @st_client.success?

                # import Jobs for Contact
                @st_client.result.each do |job|
                  data = args.merge({ job_id: job.dig(:id) })
                  self.delay(
                    run_at:              Time.current,
                    priority:            DelayedJob.job_priority('servicetitan_import_job'),
                    queue:               DelayedJob.job_queue('servicetitan_import_job'),
                    user_id:             args.dig(:user_id).to_i,
                    contact_id:          0,
                    triggeraction_id:    0,
                    contact_campaign_id: 0,
                    group_process:       0,
                    process:             'servicetitan_import_job',
                    data:
                  ).import_job(data)
                end
              end
            end
          end

          def import_jobs_block_size
            25
          end

          # return a string that may be used to inform the User how many more ServiceTitan jobs are remaining in the queue to be imported
          # st_model.job_imports_remaining_string(Integer)
          def job_imports_remaining_string(client_id)
            imports             = [0, DelayedJob.where(process: 'servicetitan_import_jobs').where('data @> ?', { client_id: }.to_json).count].max
            grouped_job_imports = [0, DelayedJob.where(process: 'servicetitan_import_jobs_block').where('data @> ?', { client_id: }.to_json).count * self.import_jobs_block_size].max
            job_imports         = [0, DelayedJob.where(process: 'servicetitan_import_job').where('data @> ?', { client_id: }.to_json).count - 1].max

            if imports.positive?
              'ServiceTitan job imports are queued.'
            elsif (grouped_job_imports + job_imports).positive?
              "ServiceTitan jobs awaiting import: #{ActionController::Base.helpers.content_tag(:span, (grouped_job_imports + job_imports), class: 'badge badge-lg badge-success')}"
            else
              ''
            end
          end

          # load Jobs from ServiceTitan
          # st_model.load_jobs()
          #   (req) client:           (Client)
          #   (opt) completed_after:  (DateTime)
          #   (opt) completed_before: (DateTime)
          def load_jobs(args = {})
            completed_before = args.dig(:completed_before) && args[:completed_before].respond_to?(:strftime) ? args[:completed_after] : nil
            completed_after  = args.dig(:completed_after) && args[:completed_after].respond_to?(:strftime) ? args[:completed_after] : nil

            return unless args.dig(:client).is_a?(Client) && self.valid_credentials?

            jobs_args = {}
            jobs_args[:completed_before] = completed_before if completed_before
            jobs_args[:completed_after]  = completed_after if completed_after
            jobs_args[:page_size]        = self.import_block_count
            jobs_args[:page]             = 0

            @st_client.job_count(jobs_args)

            return unless @st_client.success?

            # generate DelayedJobs to import all ServiceTitan jobs
            (0..(@st_client.result.to_f / jobs_args[:page_size]).ceil).each do |page|
              jobs_args[:page] = page

              @st_client.jobs(jobs_args)

              if @st_client.success? && @st_client.result.present?

                @st_client.result.each do |job|
                  self.delay(
                    run_at:              Time.current,
                    priority:            DelayedJob.job_priority('servicetitan_update_contact_from_job'),
                    queue:               DelayedJob.job_queue('servicetitan_update_contact_from_job'),
                    user_id:             0,
                    contact_id:          0,
                    triggeraction_id:    0,
                    contact_campaign_id: 0,
                    group_process:       0,
                    process:             'servicetitan_update_contact_from_job',
                    data:                { job: }
                  ).update_contact_from_job(st_job_model: job)
                end
              end
            end
          end

          def update_job_imports_remaining_count(client, user)
            UserCable.new.broadcast(client, user, { append: 'false', id: 'job_imports_remaining', html: self.job_imports_remaining_string(client.id) })
          end
        end
      end
    end
  end
end
