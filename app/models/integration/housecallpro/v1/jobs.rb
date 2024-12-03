# frozen_string_literal: true

# app/models/Integration/housecallpro/v1/jobs.rb
module Integration
  module Housecallpro
    module V1
      module Jobs
        # import a Housecall Pro job
        # hcp_model.import_job()
        #   (opt) actions:                   (Hash)
        #   (req) job:                       (Hash)
        #   (opt) process_events:            (Boolean)
        #   (opt) user_id:                   (Integer)
        def import_job(args = {})
          JsonLog.info 'Integration::Housecallpro::V1::Base.import_job', { args: }
          actions                   = args.dig(:actions) || {}
          job                       = args.dig(:job)
          process_events            = args.dig(:process_events).to_bool
          user_id                   = args.dig(:user_id).to_i

          return unless job.is_a?(Hash) && self.valid_credentials?

          self.update_job_imports_remaining_count(User.find_by(client_id: @client.id, id: args.dig(:user_id)))

          event = case job.dig(:work_status).to_s.downcase
                  when 'scheduled'
                    'job.scheduled'
                  when 'in-progress'
                    'job.started'
                  when 'completed'
                    'job.completed'
                  when 'canceled'
                    'job.canceled'
                  else # 'unscheduled'
                    'job.created'
                  end

          @hcp_client.parse_webhook(job:, event:)
          JsonLog.info 'Integration::Housecallpro::V1::Base.import_job', { result: @hcp_client.result }

          return unless @hcp_client.success?

          data = {
            actions:,
            event:          @hcp_client.result,
            process_events:,
            raw_params:     { job: }
          }
          JsonLog.info 'Integration::Housecallpro::V1::Base.import_job', { data: }
          self.delay(
            run_at:              Time.current,
            priority:            DelayedJob.job_priority('housecallpro_process_job'),
            queue:               DelayedJob.job_queue('housecallpro_process_job'),
            user_id:,
            contact_id:          0,
            triggeraction_id:    0,
            contact_campaign_id: 0,
            group_process:       0,
            process:             'housecallpro_process_job',
            data:
          ).event_process(data)
        end

        # import Housecall Pro jobs
        # hcp_model.import_jobs()
        # hcp_model.import_jobs(user_id: Integer, page: Integer, page_size: Integer)
        #   (opt) actions:                   (Hash)
        #   (opt) process_events:            (Boolean)
        #   (opt) customer_id:               (String)
        #   (opt) page:                      (Integer)
        #   (opt) page_size:                 (Integer)
        #   (opt) scheduled_end_max:         (DateTime)
        #   (opt) scheduled_end_min:         (DateTime)
        #   (opt) scheduled_start_max:       (DateTime)
        #   (opt) scheduled_start_min:       (DateTime)
        #   (opt) user_id:                   (Integer)
        #   (opt) work_status:               (String)
        def import_jobs(args)
          JsonLog.info 'Integration::Housecallpro::V1::Base.import_jobs', { args: }
          page      = (args.dig(:page) || -1).to_i
          page_size = (args.dig(:page_size) || self.import_block_size).to_i

          return unless self.valid_credentials?

          self.update_job_imports_remaining_count(User.find_by(client_id: @client.id, id: args.dig(:user_id)))

          if page.negative?
            # break up HCP Jobs into blocks
            @hcp_client.jobs_count(args)
            JsonLog.info 'Integration::Housecallpro::V1::Base.import_jobs', { result: @hcp_client.result }

            if @hcp_client.success?
              run_at = Time.current

              # generate DelayedJobs to import all Housecall Pro jobs
              (1..(@hcp_client.result.to_f / page_size).ceil).each do |pp|
                data = {
                  actions:             args.dig(:actions),
                  customer_id:         args.dig(:customer_id).to_s,
                  page:                pp,
                  page_size:,
                  process_events:      args.dig(:process_events).to_bool,
                  scheduled_end_max:   args.dig(:scheduled_end_max),
                  scheduled_end_min:   args.dig(:scheduled_end_min),
                  scheduled_start_max: args.dig(:scheduled_start_max),
                  scheduled_start_min: args.dig(:scheduled_start_min),
                  user_id:             args.dig(:user_id).to_i,
                  work_status:         args.dig(:work_status) # unscheduled, scheduled, in_progress, completed, canceled
                }
                JsonLog.info 'Integration::Housecallpro::V1::Base.import_jobs', { data: }
                self.delay(
                  run_at:,
                  priority:            DelayedJob.job_priority('housecallpro_import_jobs_block'),
                  queue:               DelayedJob.job_queue('housecallpro_import_jobs_block'),
                  user_id:             args.dig(:user_id),
                  contact_id:          0,
                  triggeraction_id:    0,
                  contact_campaign_id: 0,
                  group_process:       1,
                  process:             'housecallpro_import_jobs_block',
                  data:
                ).import_jobs(data)
                run_at += 1.minute
              end
            end
          else
            # get the Housecall Pro job data for a specific page
            @hcp_client.jobs(args)

            if @hcp_client.success?
              run_at = Time.current

              # import Jobs for Contact
              @hcp_client.result.each do |job|
                data = {
                  actions:        args.dig(:actions),
                  job:,
                  process_events: args.dig(:process_events).to_bool,
                  user_id:        args.dig(:user_id).to_i
                }
                JsonLog.info 'Integration::Housecallpro::V1::Base.import_jobs', { data: }
                self.delay(
                  run_at:,
                  priority:            DelayedJob.job_priority('housecallpro_import_job'),
                  queue:               DelayedJob.job_queue('housecallpro_import_job'),
                  user_id:             args.dig(:user_id),
                  contact_id:          0,
                  triggeraction_id:    0,
                  contact_campaign_id: 0,
                  group_process:       0,
                  process:             'housecallpro_import_job',
                  data:
                ).import_job(data)
                run_at += 5.seconds
              end
            end
          end
        end

        # return a string that may be used to inform the User how many more Housecall Pro jobs are remaining in the queue to be imported
        # hcp_model.job_imports_remaining_string
        def job_imports_remaining_string
          imports             = [0, DelayedJob.where(process: 'housecallpro_import_jobs').where('data @> ?', { client_id: @client.id }.to_json).count - 1].max
          grouped_job_imports = [0, (DelayedJob.where(process: 'housecallpro_import_jobs_block').where('data @> ?', { client_id: @client.id }.to_json).count * self.import_block_size) - 1].max
          job_imports         = [0, DelayedJob.where(process: 'housecallpro_import_job').where('data @> ?', { client_id: @client.id }.to_json).count - 1].max

          if imports.positive?
            'Housecall Pro job imports are queued.'
          elsif (grouped_job_imports + job_imports).positive?
            "Housecall Pro jobs awaiting import: #{ActionController::Base.helpers.content_tag(:span, (grouped_job_imports + job_imports), class: 'badge badge-lg badge-success')}"
          else
            ''
          end
        end

        def update_job_imports_remaining_count(user)
          UserCable.new.broadcast(@client, user, { append: 'false', id: 'job_imports_remaining', html: self.job_imports_remaining_string })
        end
      end
    end
  end
end
