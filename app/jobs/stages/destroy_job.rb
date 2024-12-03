# frozen_string_literal: true

# app/jobs/stages/destroy_job.rb
module Stages
  class DestroyJob < ApplicationJob
    # remove all references to a destroyed Stage
    # Stages::DestroyJob.perform_now()
    # Stages::DestroyJob.set(wait_until: 1.day.from_now).perform_later()
    # Stages::DestroyJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()
    def initialize(**args)
      super

      @process = (args.dig(:process).presence || 'stage_destroy').to_s
    end

    # perform the ActiveJob
    #   (req) client_id:       (Integer)
    #   (req) stage_id:        (Integer)
    #   (req) stage_parent_id: (Integer)
    #   (req) sort_order:      (Integer
    def perform(**args)
      super

      return unless Integer(args.dig(:client_id), exception: false).present? && (client = Client.find_by(id: args[:client_id].to_i)) &&
                    Integer(args.dig(:stage_id), exception: false).present? && Integer(args.dig(:stage_parent_id), exception: false).present? &&
                    Integer(args.dig(:sort_order), exception: false).present?

      if (stage = client.stages.find_by(id: args[:stage_id].to_i)).present?
        stage.destroy
      end

      Campaigns::Destroyed::TriggeractionsJob.perform_later(client_id: client.id, stage_id: args[:stage_id])
      Campaigns::Destroyed::ClientApiIntegrationsJob.perform_later(client_id: client.id, stage_id: args[:stage_id])

      # rubocop:disable Rails/SkipsModelValidations
      Clients::Widget.where(stage_id: args[:stage_id]).update_all(stage_id: 0)
      Contact.where(stage_id: args[:stage_id]).update_all(stage_id: 0)
      Stage.where(stage_parent_id: args[:stage_parent_id]).where.not(id: args[:stage_id]).where('sort_order > ?', args[:sort_order]).update_all('sort_order = sort_order - 1')
      Tag.where(stage_id: args[:stage_id]).update_all(stage_id: 0)
      TrackableLink.where(stage_id: args[:stage_id]).update_all(stage_id: 0)
      UserContactForm.where(stage_id: args[:stage_id]).update_all(stage_id: 0)
      Webhook.where(stage_id: args[:stage_id]).update_all(stage_id: 0)
      # rubocop:enable Rails/SkipsModelValidations

      DelayedJob.where(process: 'group_add_stage', locked_at: nil).where('data @> ?', { add_stage_id: args[:stage_id] }.to_json).delete_all
      DelayedJob.where(process: 'add_stage', locked_at: nil).where('data @> ?', { stage_id: args[:stage_id] }.to_json).delete_all
    end
  end
end
