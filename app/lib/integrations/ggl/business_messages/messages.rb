# frozen_string_literal: true

# app/lib/integrations/ggl/business_messages/messages.rb
module Integrations
  module Ggl
    module BusinessMessages
      # Google Messages methods called by Google Messages class
      # ggl_client = Integrations::Ggl::Base.new(token, I18n.t('tenant.id'))
      module Messages
        # send a message using Google Business Messages
        # ggl_client.send_message()
        # (req) message: (String)
        def send_message(args = {})
          reset_attributes
          @result = {}

          return @result if (args.dig(:content).blank? && args.dig(:media_url).blank?) || args.dig(:agent_id).blank? || args.dig(:conversation_id).blank?

          body = {
            messageId:      SecureRandom.uuid,
            representative: {
              representativeType: 'HUMAN'
            }
          }

          if args.dig(:content).present?
            body[:text] = args[:content].to_s
          elsif args.dig(:media_url).present?
            body[:image] = {
              contentInfo: {
                fileUrl: args[:media_url].to_s
              }
            }
          end

          self.google_request(
            body:,
            error_message_prepend: 'Integrations::Ggl::BusinessMessages::Messages.SendMessage',
            method:                'post',
            params:                nil,
            default_result:        @result,
            token:                 self.business_messages_token,
            url:                   "#{messages_base_url}/#{messages_base_version}/#{args[:conversation_id]}/messages"
          )
        end

        private

        def messages_base_url
          'https://businessmessages.googleapis.com'
        end

        def messages_base_version
          'v1'
        end
      end
    end
  end
end
