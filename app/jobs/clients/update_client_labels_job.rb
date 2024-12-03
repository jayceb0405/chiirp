# frozen_string_literal: true

module Clients
  class UpdateClientLabelsJob < ApplicationJob
    # update client contact phone labels
    # Clients::UpdateClientLabelsJob.perform_now()
    # Clients::UpdateClientLabelsJob.set(wait_until: 1.day.from_now).perform_later()
    # Clients::UpdateClientLabelsJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
    def initialize(**args)
      super

      @process = (args.dig(:process).presence || 'update_client_labels').to_s
    end

    # perform the ActiveJob
    #   (req) client_id: (Integer)
    #   (opt) new_label: (String) the recently created record's label
    def perform(**args)
      super

      Client.find_by(id: args.dig(:client_id).to_i)&.update_client_labels(new_label: args.dig(:new_label))
    end
  end
end
