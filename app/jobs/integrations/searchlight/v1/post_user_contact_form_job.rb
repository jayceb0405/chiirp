# frozen_string_literal: true

# app/jobs/integrations/searchlight/v1/post_user_contact_form_job.rb
module Integrations
  module Searchlight
    module V1
      class PostUserContactFormJob < ApplicationJob
        # post a UserContactForm to Searchlight for an action in Chiirp
        # Integrations::Searchlight::V1::PostUserContactFormJob.perform_now()
        # Integrations::Searchlight::V1::PostUserContactFormJob.set(wait_until: 1.day.from_now).perform_later()
        # Integrations::Searchlight::V1::PostUserContactFormJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
        def initialize(**args)
          super

          @process = (args.dig(:process).presence || 'searchlight_post').to_s
        end

        # perform the ActiveJob
        #   (req) action_at:            (DateTime)
        #   (req) client_id:            (Integer)
        #   (req) contact_id:           (Integer)
        #   (req) user_contact_form_id: (Integer)
        def perform(**args)
          super

          return unless Integer(args.dig(:client_id), exception: false).present? && (client = Client.find_by(id: args[:client_id].to_i)) &&
                        Integer(args.dig(:contact_id), exception: false).present? && Integer(args.dig(:user_contact_form_id), exception: false).present? &&
                        args.dig(:action_at).present?

          Integration::Searchlight::V1::Base.new(client).post_user_contact_form(args[:contact_id], args[:user_contact_form_id], args[:action_at])
        end
      end
    end
  end
end
