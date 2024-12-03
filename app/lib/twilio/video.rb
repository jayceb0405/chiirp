# frozen_string_literal: true

# app/lib/twilio/video.rb
module Twilio
  module Video
    def self.close_room(args)
      # close a room for video
      #
      # Example:
      # 	Twilio::Video.close_room( room_name: String )
      #
      # Required Arguments:
      # 	room_name: (String)
      #
      # Optional Arguments:
      #   none
      #
      room_name = args.dig(:room_name).to_s
      response  = { success: false, error_message: '' }

      unless room_name.empty?

        begin
          twilio_client = Twilio::REST::Client.new(Rails.application.credentials[:twilio][:sid], Rails.application.credentials[:twilio][:auth])

          twilio_client.video.rooms.list(status: 'in-progress', limit: 200).each do |room_in_progress|
            if room_in_progress.unique_name == room_name
              twilio_client.video.rooms(room_in_progress.sid).update(status: 'completed')
              response[:success] = true
            end
          end
        rescue Twilio::REST::RestError => e
          if e.respond_to?(:code) && e.code.to_i == 53_112
            # Raised in the REST API when Status is not valid or the Room is not in-progress
          else
            ProcessError::Report.send(
              error_code:    (e.respond_to?(:code) ? e.code : 'Unknown'),
              error_message: "Twilio::Video::CloseRoom: Twilio::REST::RestError: #{e.respond_to?(:error_message) ? e.error_message : 'Unknown'}",
              variables:     {
                e:                e.inspect,
                e_response:       (e.respond_to?(:response) ? e.response.inspect : 'Unknown'),
                e_message:        e.message,
                args:             args.inspect,
                room_name:        room_name.inspect,
                room_in_progress: (defined?(room_in_progress) ? room_in_progress.inspect : nil),
                file:             __FILE__,
                line:             __LINE__
              }
            )
          end
        rescue StandardError => e
          ProcessError::Report.send(
            error_code:    (e.respond_to?(:code) ? e.code : 'Unknown'),
            error_message: "Twilio::Video::CloseRoom: #{e.respond_to?(:error_message) ? e.error_message : 'Unknown'}",
            variables:     {
              e:                e.inspect,
              e_response:       (e.respond_to?(:response) ? e.response.inspect : 'Unknown'),
              e_message:        e.message,
              args:             args.inspect,
              room_name:        room_name.inspect,
              room_in_progress: (defined?(room_in_progress) ? room_in_progress.inspect : nil),
              file:             __FILE__,
              line:             __LINE__
            }
          )
        end
      end

      response
    end

    def self.create_room(args)
      # create a room for video
      #
      # Example:
      # 	Twilio::Video.create_room( room_name: String, tenant: String )
      #
      # Required Arguments:
      # 	room_name: (String)
      # 	tenant:    (String)
      #
      # Optional Arguments:
      #   none
      #
      room_name = args.include?(:room_name) ? args[:room_name].to_s : ''
      tenant    = args.include?(:tenant) ? args[:tenant].to_s : ''
      response  = { success: false, room_sid: '', error_message: '' }

      if !room_name.empty? && !tenant.empty?
        tenant_app_host     = I18n.with_locale(tenant) { I18n.t("tenant.#{Rails.env}.app_host") }
        tenant_app_protocol = I18n.with_locale(tenant) { I18n.t('tenant.app_protocol') }

        twilio_client = Twilio::REST::Client.new(Rails.application.credentials[:twilio][:sid], Rails.application.credentials[:twilio][:auth])

        begin
          room = twilio_client.video.rooms.create(
            max_participants: 2,
            status_callback:  Rails.application.routes.url_helpers.video_callback_url(host: tenant_app_host, protocol: tenant_app_protocol),
            type:             'peer-to-peer',
            unique_name:      room_name
          )

          response[:success]  = true
          response[:room_sid] = room.sid
        rescue Twilio::REST::RestError => e
          if e.code == 53_113
            # unable to create record
            Twilio::Video.close_room(room_name:)

            begin
              room = twilio_client.video.rooms.create(
                max_participants: 2,
                status_callback:  Rails.application.routes.url_helpers.video_callback_url(host: tenant_app_host, protocol: tenant_app_protocol),
                type:             'peer-to-peer',
                unique_name:      room_name
              )

              response[:success]  = true
              response[:room_sid] = room.sid
            rescue StandardError => e
              ProcessError::Report.send(
                error_code:    (e.respond_to?(:code) ? e.code : 'Unknown'),
                error_message: "Twilio::Video::CreateRoom: #{e.respond_to?(:error_message) ? e.error_message : 'Unknown'}",
                variables:     {
                  e:             e.inspect,
                  e_response:    (e.respond_to?(:response) ? e.response.inspect : 'Unknown'),
                  e_message:     e.message,
                  args:          args.inspect,
                  twilio_client: twilio_client.inspect,
                  room:          room.inspect,
                  response:      response.inspect,
                  file:          __FILE__,
                  line:          __LINE__
                }
              )
            end
          else
            ProcessError::Report.send(
              error_code:    (e.respond_to?(:code) ? e.code : 'Unknown'),
              error_message: "Twilio::Video::CreateRoom: #{e.respond_to?(:error_message) ? e.error_message : 'Unknown'}",
              variables:     {
                e:             e.inspect,
                e_response:    (e.respond_to?(:response) ? e.response.inspect : 'Unknown'),
                e_message:     e.message,
                args:          args.inspect,
                twilio_client: twilio_client.inspect,
                room:          room.inspect,
                response:      response.inspect,
                file:          __FILE__,
                line:          __LINE__
              }
            )
          end
        rescue StandardError => e
          ProcessError::Report.send(
            error_code:    (e.respond_to?(:code) ? e.code : 'Unknown'),
            error_message: "Twilio::Video::CreateRoom: #{e.respond_to?(:error_message) ? e.error_message : 'Unknown'}",
            variables:     {
              e:             e.inspect,
              e_response:    (e.respond_to?(:response) ? e.response.inspect : 'Unknown'),
              e_message:     e.message,
              args:          args.inspect,
              twilio_client: twilio_client.inspect,
              room:          room.inspect,
              response:      response.inspect,
              file:          __FILE__,
              line:          __LINE__
            }
          )
        end
      end

      response
    end
    # room =
    # <Twilio.Video.V1.RoomInstance
    # 	sid: RMd8790477cd39794e088433f0f49410ad
    # 	status: in-progress
    # 	date_created: 2020-05-20 16:01:56 UTC
    # 	date_updated: 2020-05-20 16:01:56 UTC
    # 	account_sid: AC4af9e2c0a8ed64f5b8d9a8f1fdde90b8
    # 	enable_turn: true
    # 	unique_name: DailyStandup
    # 	status_callback: https://dev.chiirp.com/video/callback
    # 	status_callback_method: POST
    # 	end_time:
    # 	duration:
    # 	type: peer-to-peer
    # 	max_participants: 10
    # 	record_participants_on_connect: false
    # 	video_codecs:
    # 	media_region:
    # 	url: https://video.twilio.com/v1/Rooms/RMd8790477cd39794e088433f0f49410ad
    # 	links: {
    # 		"recordings"=>"https://video.twilio.com/v1/Rooms/RMd8790477cd39794e088433f0f49410ad/Recordings",
    # 		"participants"=>"https://video.twilio.com/v1/Rooms/RMd8790477cd39794e088433f0f49410ad/Participants"
    # 	}
    # >

    def self.get_token(args)
      # generate a Twilio Video room token
      #
      # Example:
      # 	Twilio::Video.get_token( room_name: String, fullname: String )
      #
      # Required Arguments:
      # 	room_name: (Integer)
      # 	fullname:  (String)
      #
      # Optional Arguments:
      #   none
      #
      room_name = args.include?(:room_name) ? args[:room_name].to_s : ''
      fullname  = args.include?(:fullname) ? args[:fullname].to_s : ''
      response  = { success: false, token: '', error_message: '' }

      if !room_name.empty? && !fullname.empty?
        # Create an Access Token
        token = Twilio::JWT::AccessToken.new(
          Rails.application.credentials[:twilio][:sid],
          Rails.application.credentials[:twilio][:video_sid],
          Rails.application.credentials[:twilio][:video_secret],
          [],
          identity: fullname
        )

        # Create Video grant for our token
        grant = Twilio::JWT::AccessToken::VideoGrant.new
        grant.room = room_name
        token.add_grant(grant)

        response[:success]  = true
        response[:token]    = token.to_jwt
      else
        response[:error_message] = 'Invalid data received.'
      end

      response
    end
  end
end
