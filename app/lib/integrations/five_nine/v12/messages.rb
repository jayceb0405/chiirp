# frozen_string_literal: true

# app/lib/integrations/five_nine/v12/messages.rb
module Integrations
  module FiveNine
    module V12
      module Messages
        # send a Messages::Message to Five9 in Bandwidth format
        # Integrations::FiveNine.new(Client).send_message_to_five9(Messages::Message)
        def send_message_to_five9(message)
          @success = false

          return unless @client_api_integration&.text_passthrough

          begin
            result = Faraday.post(messaging_url) do |req|
              req.headers['Content-Type'] = 'application/json'
              req.body = format_message_for_five9(message).to_json
            end

            Rails.logger.info "Integrations::FiveNine::V12::Messages.send_message_to_five9: #{{ result: }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"

            @success = result.status == 200
          rescue StandardError => e
            ProcessError::Report.send(
              error_code:    result&.status || '',
              error_message: "Integrations::FiveNine::V12::Messages.send_message_to_five9 (StandardError): #{result&.reason_phrase || e.message}",
              variables:     {
                e:            e.inspect,
                success:      @success.inspect,
                result:       defined?(result) ? result.inspect : 'undefined',
                call_message: message.inspect
              },
              file:          __FILE__,
              line:          __LINE__
            )
          end
        end
        # (POST) html JSON parameters
        # {
        #   "_json"=>[
        #     {
        #       "time"=>"2021-03-03T09:45:15.964Z",
        #       "type"=>"message-received",
        #       "to"=>"+18022898010",
        #       "description"=>"Incoming message received",
        #       "message"=>{
        #         "id"=>"421aaa7d-4be8-4cbb-9914-ff3aec2c3050",
        #         "owner"=>"+18022898010",
        #         "applicationId"=>"5e8b5ec9-65bf-4342-a18e-27b3fc355e65",
        #         "time"=>"2021-03-03T09:45:15.861Z",
        #         "segmentCount"=>1,
        #         "direction"=>"in",
        #         "to"=>["+18022898010"],
        #         "from"=>"+18023455136",
        #         "text"=>"Incoming 01",
        #         "media"=>[
        #           "https://messaging.bandwidth.com/api/v2/users/5007421/media/f612f6b1-20d2-4855-bbb0-d060231e7561/0/0.smil",
        #           "https://messaging.bandwidth.com/api/v2/users/5007421/media/f612f6b1-20d2-4855-bbb0-d060231e7561/1/IMG_4099.png"
        #         ]
        #       }
        #     }
        #   ],
        #   "message"=>{}
        # }

        private

        # format Messages::Message as Bandwidth JSON format
        # data = format_message_for_five9
        def format_message_for_five9(message = {})
          media = []

          message.attachments.each do |message_attachment|
            media << message_attachment.contact_attachment.image.url(secure: true) unless message_attachment.contact_attachment&.image&.nil?
          end

          [{
            time:        message.created_at.iso8601,
            type:        'message-received',
            to:          "+1#{message.to_phone}",
            description: 'Incoming message received',
            message:     {
              id:            message.message_sid,
              owner:         "+1#{message.to_phone}",
              applicationId: 'unassigned',
              time:          message.created_at.iso8601,
              segmentCount:  message.num_segments,
              direction:     'in',
              to:            ["+1#{message.to_phone}"],
              from:          "+1#{message.from_phone}",
              text:          message.message,
              media:
            }
          }]
        end
      end
    end
  end
end
