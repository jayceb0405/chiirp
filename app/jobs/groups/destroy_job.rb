# frozen_string_literal: true

# app/jobs/groups/destroy_job.rb
module Groups
  class DestroyJob < ApplicationJob
    # remove all references to a destroyed Group
    # Groups::DestroyJob.perform_now()
    # Groups::DestroyJob.set(wait_until: 1.day.from_now).perform_later()
    # Groups::DestroyJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()
    def initialize(**args)
      super

      @process = (args.dig(:process).presence || 'group_destroy').to_s
    end

    # perform the ActiveJob
    #   (req) client_id: (Integer)
    #   (req) group_id:  (Integer)
    def perform(**args)
      super

      return unless Integer(args.dig(:client_id), exception: false).present? && (client = Client.find_by(id: args[:client_id].to_i)) &&
                    Integer(args.dig(:group_id), exception: false).present?

      if (group = client.groups.find_by(id: args[:group_id].to_i)).present?
        group.destroy
      end

      Campaigns::Destroyed::TriggeractionsJob.perform_later(client_id: client.id, group_id: args[:group_id])
      Campaigns::Destroyed::ClientApiIntegrationsJob.perform_later(client_id: client.id, group_id: args[:group_id])

      # rubocop:disable Rails/SkipsModelValidations
      Clients::Widget.where(group_id: args[:group_id]).update_all(group_id: 0)
      Contact.where(group_id: args[:group_id]).update_all(group_id: 0)
      Tag.where(group_id: args[:group_id]).update_all(group_id: 0)
      TrackableLink.where(group_id: args[:group_id]).update_all(group_id: 0)
      UserContactForm.where(group_id: args[:group_id]).update_all(group_id: 0)
      Webhook.where(group_id: args[:group_id]).update_all(group_id: 0)
      # rubocop:enable Rails/SkipsModelValidations

      DelayedJob.where(process: 'group_add_group', locked_at: nil).where('data @> ?', { add_group_id: args[:group_id] }.to_json).delete_all
      DelayedJob.where(process: 'add_group', locked_at: nil).where('data @> ?', { group_id: args[:group_id] }.to_json).delete_all
    end
  end
end
