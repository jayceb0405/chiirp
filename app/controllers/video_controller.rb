# frozen_string_literal: true

# app/controllers/video_controller.rb
class VideoController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:callback]
  before_action :set_contact_user, only: [:callback]
  before_action :set_user, only: %i[send_invite join_video start_user]
  before_action :set_contact, only: %i[send_invite join_video start_user]

  # (POST) response from Twilio re Programmable Video Event
  # /video/callback
  # video_callback_path
  # video_callback_url
  def callback
    status_callback_event = params.dig(:StatusCallbackEvent).to_s
    room_sid              = params.dig(:RoomSid).to_s
    room_name             = params.dig(:RoomName).to_s
    account_sid           = params.dig(:AccountSid).to_s
    room_duration         = params.dig(:RoomDuration).to_i

    case status_callback_event
    when 'room-created'

      message = @contact.messages.find_or_create_by(msg_type: 'video', message_sid: room_sid)
      message.update(
        message:     "Video conversation with #{@contact.fullname}.",
        from_phone:  @contact.latest_client_phonenumber(default_ok: true, phone_numbers_only: true)&.phonenumber.to_s,
        message_sid: room_sid,
        account_sid:,
        status:      'room-created',
        msg_type:    'video'
      )
    when 'room-ended'

      message = @contact.messages.find_or_create_by(from_phone: 'video', msg_type: 'video', message_sid: room_sid, status: '')
      message.message = "Video conversation with #{@contact.fullname}." unless message.message
      length_string = " (length: #{ActionController::Base.helpers.distance_of_time_in_words(Time.current, Time.current + (message.num_segments + room_duration).seconds, { include_seconds: true })})"
      message.update(
        message:      message.message += length_string,
        from_phone:   @contact.latest_client_phonenumber(default_ok: true, phone_numbers_only: true)&.phonenumber.to_s,
        message_sid:  room_sid,
        account_sid:,
        status:       'room-ended',
        msg_type:     'video',
        num_segments: message.num_segments + room_duration
      )

      @contact.client.charge_for_action(key: 'video_call_credits', multiplier: room_duration, contact_id: @contact.id, message_id: message.id)
    when 'complete-room'
      Twilio::Video.close_room(room_name:)
    end

    render json: { message: 'Success!', status: 200 }
  end
  # StatusCallbackEvents
  # 	room-created
  # 	room-ended
  # 	track-added
  # 	track-removed
  # 	track-enabled
  # 	track-disabled
  # 	participant-connected
  # 	participant-disconnected
  # 	recording-started
  # 	recording-completed
  # 	recording-failed
  #
  # {
  # 	"RoomStatus"=>"in-progress",
  # 	"RoomType"=>"peer-to-peer",
  # 	"RoomSid"=>"RM72d33bb10578006f171f572342c52c61",
  # 	"RoomName"=>"13002991709",
  # 	"SequenceNumber"=>"0",
  # 	"StatusCallbackEvent"=>"room-created",
  # 	"Timestamp"=>"2020-05-19T16:01:42.608Z",
  # 	"AccountSid"=>"AC4af9e2c0a8ed64f5b8d9a8f1fdde90b8"
  # }

  # {
  # 	"RoomStatus"=>"in-progress",
  # 	"RoomType"=>"peer-to-peer",
  # 	"RoomSid"=>"RMacee8fc17465d4fbcd9a3a5d740d85f0",
  # 	"RoomName"=>"13002991709",
  # 	"ParticipantStatus"=>"connected",
  # 	"ParticipantIdentity"=>"Jake  Hill",
  # 	"SequenceNumber"=>"1",
  # 	"StatusCallbackEvent"=>"participant-connected",
  # 	"Timestamp"=>"2020-05-19T15:57:41.116Z",
  # 	"ParticipantSid"=>"PAf49798b27626799e8b5dfa9b5e64d4c9",
  # 	"AccountSid"=>"AC4af9e2c0a8ed64f5b8d9a8f1fdde90b8"
  # }

  # {
  # 	"RoomStatus"=>"in-progress",
  # 	"RoomSid"=>"RM72d33bb10578006f171f572342c52c61",
  # 	"RoomName"=>"13002991709",
  # 	"ParticipantStatus"=>"connected",
  # 	"ParticipantIdentity"=>"Jake  Hill",
  # 	"StatusCallbackEvent"=>"track-added",
  # 	"Timestamp"=>"2020-05-19T16:01:42.608Z",
  # 	"AccountSid"=>"AC4af9e2c0a8ed64f5b8d9a8f1fdde90b8",
  # 	"TrackKind"=>"audio",
  # 	"RoomType"=>"peer-to-peer",
  # 	"TrackSid"=>"MT6e716d8d6fddff5b1665fbdcfb77637e",
  # 	"SequenceNumber"=>"2",
  # 	"TrackName"=>"d53938b5-c502-4ab8-a592-faf85d0851f7",
  # 	"ParticipantSid"=>"PA5782526c1f1e4cb86c5dc66620ce3d31"
  # }

  # {
  # 	"RoomStatus"=>"completed",
  # 	"RoomType"=>"peer-to-peer",
  # 	"RoomSid"=>"RMacee8fc17465d4fbcd9a3a5d740d85f0",
  # 	"RoomName"=>"13002991709",
  # 	"RoomDuration"=>"227",
  # 	"SequenceNumber"=>"5",
  # 	"StatusCallbackEvent"=>"room-ended",
  # 	"Timestamp"=>"2020-05-19T16:01:28.625Z",
  # 	"AccountSid"=>"AC4af9e2c0a8ed64f5b8d9a8f1fdde90b8"
  # }

  # (POST) send invitation to Contact to join screen share
  # /video/send_invite
  # video_send_invite_path
  # video_send_invite_url
  def send_invite
    type    = (params.dig(:type) || 'email').to_s.downcase
    content = "Please click the link below to start your video conversation.\r\n \r\n#{video_join_video_url(@contact.id, @user.id)}"

    case type
    when 'email'
      @contact.send_email(
        from_email:           { email: @user.email, name: @user.fullname },
        reply_email:          { email: @user.email, name: @user.fullname },
        subject:              'Video Conference Invitation',
        email_template_yield: content,
        automated:            false
      )
    when 'text'
      @contact.send_text(
        content:,
        msg_type: 'textout',
        user:     @user
      )
    end

    respond_to do |format|
      format.json { render json: { message: 'Invitation sent.', status: 200 } }
      format.js { render js: "window.location = '#{root_path}'" }
      format.html { redirect_to root_path }
    end
  end

  # (GET) start Contact screen share
  # /video/join_video/:contact_id/:user_id
  # video_join_video_path(:contact_id, :user_id)
  # video_join_video_url(:contact_id, :user_id)
  def join_video
    room_name = "#{@user.id}_#{@contact.id}"

    token_result = Twilio::Video.get_token(room_name:, fullname: @contact.fullname)

    render 'video/start_contact', layout: false, locals: { room_name:, token: token_result[:token] }
  end

  # (GET) start User screen share
  # /video/start_user/:contact_id/:user_id
  # video_start_user_path(:contact_id, :user_id)
  # video_start_user_url(:contact_id, :user_id)
  def start_user
    room_name = "#{@user.id}_#{@contact.id}"

    room_result = Twilio::Video.create_room(room_name:, tenant: @user.client.tenant)

    token_result = if room_result[:success]
                     Twilio::Video.get_token(room_name:, fullname: @user.fullname)
                   else
                     { success: false }
                   end

    respond_to do |format|
      if token_result[:success]
        format.js { render partial: 'video/js/show', locals: { cards: %w[modal edit], room_name:, token: token_result[:token] } }
      else
        format.js { render js: "window.location = '#{root_path}'" }
      end

      format.html { redirect_to central_path }
    end
  end

  private

  def set_contact
    return if (@contact = Contact.find_by(id: params.permit(:contact_id).dig(:contact_id).to_i))

    sweetalert_error('Contact NOT found!', 'We were not able to access the Contact you requested.', '', { persistent: 'OK' })

    respond_to do |format|
      format.json { render json: { message: 'Unable to locate Contact.', status: 404 } and return false }
      format.js { render js: "window.location = '#{root_path}'" and return false }
      format.html { redirect_to root_path and return false }
    end
  end

  def set_contact_user
    @user    = nil
    @contact = nil

    if params.permit(:RoomName).dig(:RoomName).to_s.include?('_')
      room_name = params[:RoomName].to_s.split('_')

      @user    = User.find_by(id: room_name[0])
      @contact = @user.contacts.find_by(id: room_name[1]) if @user
    end

    render json: { message: 'Failed!', status: 404 } and return false if @user.nil? || @contact.nil?
  end

  def set_user
    return if (@user = User.find_by(id: params.permit(:user_id).dig(:user_id).to_i))

    sweetalert_error('User NOT found!', 'We were not able to access the User you requested.', '', { persistent: 'OK' })

    respond_to do |format|
      format.json { render json: { message: 'Unable to locate User.', status: 404 } and return false }
      format.js { render js: "window.location = '#{root_path}'" and return false }
      format.html { redirect_to root_path and return false }
    end
  end
end
