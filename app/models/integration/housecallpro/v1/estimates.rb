# frozen_string_literal: true

# app/models/Integration/housecallpro/v1/jobs.rb
module Integration
  module Housecallpro
    module V1
      module Estimates
        # return a string that may be used to inform the User how many more Housecall Pro estimates are remaining in the queue to be imported
        # hcp_model.estimate_imports_remaining_string
        def estimate_imports_remaining_string
          imports                  = [0, DelayedJob.where(process: 'housecallpro_import_estimates').where('data @> ?', { client_id: @client.id }.to_json).count - 1].max
          grouped_estimate_imports = [0, (DelayedJob.where(process: 'housecallpro_import_estimates_block').where('data @> ?', { client_id: @client.id }.to_json).count * self.import_block_size) - 1].max
          estimate_imports         = [0, DelayedJob.where(process: 'housecallpro_import_estimate').where('data @> ?', { client_id: @client.id }.to_json).count - 1].max

          if imports.positive?
            'Housecall Pro estimate imports are queued.'
          elsif (grouped_estimate_imports + estimate_imports).positive?
            "Housecall Pro estimates awaiting import: #{ActionController::Base.helpers.content_tag(:span, (grouped_estimate_imports + estimate_imports), class: 'badge badge-lg badge-success')}"
          else
            ''
          end
        end

        # import a Housecall Pro estimate
        # hcp_model.import_estimate()
        #   (opt) estimate: (Hash)
        #   (opt) actions:  (Hash)
        #   (opt) user_id:  (Integer)
        def import_estimate(args = {})
          JsonLog.info 'Integration::Housecallpro::V1::Base.import_estimate', { args: }

          return unless args.dig(:estimate).is_a?(Hash) && self.valid_credentials?

          self.update_estimate_imports_remaining_count(User.find_by(client_id: @client.id, id: args.dig(:user_id)))

          event = case args.dig(:estimate, :work_status).to_s.downcase
                  when 'scheduled'
                    'estimate.scheduled'
                  when 'in-progress'
                    'estimate.started'
                  when 'completed', 'complete unrated'
                    'estimate.completed'
                  when 'canceled', 'pro canceled', 'user canceled'
                    'estimate.canceled'
                  else # 'unscheduled'
                    'estimate.created'
                  end

          @hcp_client.parse_webhook(estimate: args.dig(:estimate), event:)

          return unless @hcp_client.success?

          contact = self.event_process(
            actions:    {},
            event:      @hcp_client.result,
            raw_params: {}
          )

          JsonLog.info 'Integration::Housecallpro::V1::Base.import_estimate', { result: @hcp_client.result }, contact_id: contact.id

          return unless contact
          return unless lead_sources_include?(args.dig(:lead_sources), contact.lead_source_id)
          return unless ext_tech_ids_include?(event.tr('.', '_'), args.dig(:ext_tech_ids), @hcp_client.result.dig(:technician, :id).to_s)
          return unless tag_ids_include?(args.dig(:tag_ids_include), @hcp_client.result.dig(:tags))
          return unless tag_ids_exclude?(args.dig(:tag_ids_exclude), @hcp_client.result.dig(:tags))
          return unless approval_status_matches?('estimate_sent', args.dig(:approval_statuses), @hcp_client.result.dig(:estimate, :options)&.map { |option| option.dig(:approval_status) } || [])

          contact.process_actions(
            campaign_id:         args.dig(:actions, :campaign_id).to_i,
            group_id:            args.dig(:actions, :group_id).to_i,
            stage_id:            args.dig(:actions, :stage_id).to_i,
            tag_id:              args.dig(:actions, :tag_id).to_i,
            stop_campaign_ids:   args.dig(:actions, :stop_campaign_ids),
            contact_job_id:      0,
            contact_estimate_id: contact.estimates.find_by(ext_id: @hcp_client.result.dig(:estimate, :id))&.id
          )
        end

        # import Housecall Pro estimates
        # hcp_model.import_estimates()
        #   (opt) page:                      (Integer)
        #   (opt) page_size:                 (Integer)
        #   (opt) user_id:                   (Integer)
        def import_estimates(args)
          JsonLog.info 'Integration::Housecallpro::V1::Base.import_estimates', { args: }
          page      = (args.dig(:page) || -1).to_i
          page_size = (args.dig(:page_size) || self.import_block_size).to_i

          return unless self.valid_credentials?

          self.update_estimate_imports_remaining_count(User.find_by(client_id: @client.id, id: args.dig(:user_id)))

          if page.negative?
            # break up HCP estimates into blocks
            @hcp_client.estimates_count(args)

            if @hcp_client.success?
              run_at = Time.current

              (1..(@hcp_client.result.to_f / page_size).ceil).each do |pp|
                data = args.merge({ page: pp })
                self.delay(
                  run_at:,
                  priority:            DelayedJob.job_priority('housecallpro_import_estimates_block'),
                  queue:               DelayedJob.job_queue('housecallpro_import_estimates_block'),
                  user_id:             args.dig(:user_id).to_i,
                  contact_id:          0,
                  triggeraction_id:    0,
                  contact_campaign_id: 0,
                  group_process:       1,
                  process:             'housecallpro_import_estimates_block',
                  data:
                ).import_estimates(data)
                run_at += 1.minute
              end
            end
          else
            # get the Housecall Pro estimate data for a specific page
            @hcp_client.estimates(args)

            if @hcp_client.success?
              run_at = Time.current

              # import estimates for Contact
              @hcp_client.result.each do |estimate|
                data = args.merge({ estimate: })
                self.delay(
                  run_at:,
                  priority:            DelayedJob.job_priority('housecallpro_import_estimate'),
                  queue:               DelayedJob.job_queue('housecallpro_import_estimate'),
                  user_id:             args.dig(:user_id).to_i,
                  contact_id:          0,
                  triggeraction_id:    0,
                  contact_campaign_id: 0,
                  group_process:       0,
                  process:             'housecallpro_import_estimate',
                  data:
                ).import_estimate(data)
                run_at += 1.5.seconds
              end
            end
          end
        end

        def update_estimate_imports_remaining_count(user)
          UserCable.new.broadcast(@client, user, { append: 'false', id: 'estimate_imports_remaining', html: self.estimate_imports_remaining_string })
        end
      end
    end
  end
end
