# frozen_string_literal: true

# app/jobs/integrations/searchlight/v1/post_message_job.rb
module Integrations
  module Searchlight
    module V1
      class PostMessageJob < ApplicationJob
        # post a Message to Searchlight for an action in Chiirp
        # Integrations::Searchlight::V1::PostMessageJob.perform_now()
        # Integrations::Searchlight::V1::PostMessageJob.set(wait_until: 1.day.from_now).perform_later()
        # Integrations::Searchlight::V1::PostMessageJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
        def initialize(**args)
          super

          @process = (args.dig(:process).presence || 'searchlight_post').to_s
        end

        # perform the ActiveJob
        #   (req) action_at: (DateTime)
        #   (req) client_id: (Integer)
        #   (req) message:   (Messages::Message)
        def perform(**args)
          super

          return nil unless Integer(args.dig(:client_id), exception: false).present? && args.dig(:message).present? && args.dig(:action_at).present? &&
                            (client = Client.find_by(id: args[:client_id].to_i))

          Integration::Searchlight::V1::Base.new(client).post_message(args[:message], args[:action_at])
        end
      end
    end
  end
end
