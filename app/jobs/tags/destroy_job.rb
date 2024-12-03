# frozen_string_literal: true

# app/jobs/tags/destroy_job.rb
module Tags
  class DestroyJob < ApplicationJob
    # remove all references to a destroyed Tag
    # Tags::DestroyJob.perform_now()
    # Tags::DestroyJob.set(wait_until: 1.day.from_now).perform_later()
    # Tags::DestroyJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()
    def initialize(**args)
      super

      @process = (args.dig(:process).presence || 'tag_destroy').to_s
    end

    # perform the ActiveJob
    #   (req) client_id: (Integer)
    #   (req) tag_id:  (Integer)
    def perform(**args)
      super

      return unless Integer(args.dig(:client_id), exception: false).present? && (client = Client.find_by(id: args[:client_id].to_i)) &&
                    Integer(args.dig(:tag_id), exception: false).present?

      if (tag = client.tags.find_by(id: args[:tag_id].to_i)).present?
        tag.destroy
      end

      Campaigns::Destroyed::TriggeractionsJob.perform_later(client_id: client.id, tag_id: args[:tag_id])
      Campaigns::Destroyed::ClientApiIntegrationsJob.perform_later(client_id: client.id, tag_id: args[:tag_id])

      # rubocop:disable Rails/SkipsModelValidations
      Clients::Widget.where(tag_id: args[:tag_id]).update_all(tag_id: 0)
      Tag.where(tag_id: args[:tag_id]).update_all(tag_id: 0)
      TrackableLink.where(tag_id: args[:tag_id]).update_all(tag_id: 0)
      UserContactForm.where(tag_id: args[:tag_id]).update_all(tag_id: 0)
      Webhook.where(tag_id: args[:tag_id]).update_all(tag_id: 0)
      # rubocop:enable Rails/SkipsModelValidations

      DelayedJob.where(process: 'group_add_tag', locked_at: nil).where('data @> ?', { add_tag_id: args[:tag_id] }.to_json).delete_all
      DelayedJob.where(process: 'add_tag', locked_at: nil).where('data @> ?', { tag_id: args[:tag_id] }.to_json).delete_all
    end
  end
end
