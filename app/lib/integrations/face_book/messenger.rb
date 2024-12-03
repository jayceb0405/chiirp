# frozen_string_literal: true

# app/lib/integrations/face_book/messenger.rb
module Integrations
  module FaceBook
    module Messenger
      # send a message via Facebook Messenger
      # fb_client.messenger_send()
      # Integrations::FaceBook::Base.new.messenger_send()
      #   (req) page_token:     (String)
      #   (req) page_scoped_id: (String)
      #   (req) content:        (String)
      #   (opt) media_type:     (String)
      def messenger_send(**args)
        reset_attributes
        page_token     = args.dig(:page_token).to_s
        page_scoped_id = args.dig(:page_scoped_id).to_s
        content        = args.dig(:content).to_s
        media_type     = (args.dig(:media_type) || 'text').to_s
        response       = { recipient_id: '', message_id: '' }

        if page_token.empty?
          @message = 'Missing required Facebook Page token.'
          return response
        elsif page_scoped_id.empty?
          @message = 'Missing required Facebook User ID.'
          return response
        elsif content.empty? && media_type.empty?
          @message = 'Missing required Content.'
          return response
        end

        body = {
          messaging_type: 'RESPONSE',
          recipient:      {
            id: page_scoped_id
          },
          message:        {}
        }

        body[:message] = if media_type == 'text'
                           { text: content }
                         else
                           {
                             attachment: {
                               type:    media_type,
                               payload: {
                                 url:         content,
                                 is_reusable: true
                               }
                             }
                           }
                         end

        facebook_request(
          body:,
          error_message_prepend: 'Integrations::FaceBook::Messenger.messenger_send',
          method:                'post',
          params:                { access_token: page_token },
          default_result:        response,
          url:                   "#{self.base_api_url}/#{self.api_version}/me/messages"
        )

        @result = response unless self.success?

        @result
      end

      # look up a Facebook User by ID
      # fb_client.messenger_user()
      # Integrations::FaceBook::Base.new.messenger_user()
      #   (req) page_token:     (String)
      #   (req) page_scoped_id: (String)
      def messenger_user(page_token, page_scope_id)
        reset_attributes
        page_token    = page_token.to_s
        page_scope_id = page_scope_id.to_s
        response      = false

        if page_token.empty?
          @message = 'Missing required Facebook Page token.'
          return response
        elsif page_scope_id.empty?
          @message = 'Missing required Facebook User ID.'
          return response
        end

        facebook_request(
          body:                  nil,
          error_message_prepend: 'Integrations::FaceBook::Messenger.messenger_user',
          method:                'get',
          params:                { access_token: page_token, fields: 'first_name,last_name' },
          default_result:        response,
          url:                   "#{self.base_api_url}/#{page_scope_id}"
        )

        @result
      end
    end
  end
end
