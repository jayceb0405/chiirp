# frozen_string_literal: true

# app/jobs/integrations/searchlight/v1/post_survey_job.rb
module Integrations
  module Searchlight
    module V1
      class PostSurveyJob < ApplicationJob
        # post a Survey to Searchlight for an action in Chiirp
        # Integrations::Searchlight::V1::PostSurveyJob.perform_now()
        # Integrations::Searchlight::V1::PostSurveyJob.set(wait_until: 1.day.from_now).perform_later()
        # Integrations::Searchlight::V1::PostSurveyJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
        def initialize(**args)
          super

          @process = (args.dig(:process).presence || 'searchlight_post').to_s
        end

        # perform the ActiveJob
        #   (req) action_at:        (DateTime)
        #   (req) client_id:        (Integer)
        #   (opt) contact_id:       (Integer)
        #   (req) survey_id:        (Integer)
        #   (opt) survey_result_id: (Integer)
        #   (req) survey_screen_id: (Integer)
        def perform(**args)
          super

          return unless Integer(args.dig(:client_id), exception: false).present? && (client = Client.find_by(id: args[:client_id].to_i)) &&
                        Integer(args.dig(:survey_id), exception: false).present? && Integer(args.dig(:survey_screen_id), exception: false).present? &&
                        args.dig(:action_at).present?

          Integration::Searchlight::V1::Base.new(client).post_survey(args.dig(:contact_id), args[:survey_id], args[:survey_screen_id], args.dig(:survey_result_id), args[:action_at])
        end
      end
    end
  end
end
