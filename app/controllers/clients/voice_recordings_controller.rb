# frozen_string_literal: true

# app/controllers/clients/voice_recordings_controller.rb
module Clients
  # endpoints supporting general VoiceRecording actions
  class VoiceRecordingsController < Clients::ClientController
    skip_before_action :verify_authenticity_token, only: %i[record_voice_recording rvm_callback save_voice_recording]
    before_action :authenticate_user!, except: %i[record_voice_recording rvm_callback save_voice_recording]
    before_action :client, except: %i[rvm_callback]
    before_action :authorize_user!, except: %i[record_voice_recording rvm_callback save_voice_recording]
    before_action :set_voice_recording, only: %i[destroy edit new_voice_recording record_voice_recording save_audio_file save_voice_recording update]

    # (POST)
    # /client/:client_id/voice_recordings
    # client_voice_recordings_path(:client_id)
    # client_voice_recordings_url(:client_id)
    def create
      @voice_recording = current_user.client.voice_recordings.create(params_voice_recording)

      render partial: 'clients/voice_recordings/js/show', locals: { cards: %w[voice_recordings_edit] }
    end

    # (DELETE)
    # /client/:client_id/voice_recordings/:id
    # client_voice_recording_path(:client_id, :id)
    # client_voice_recording_url(:client_id, :id)
    def destroy
      @voice_recording.destroy
      @voice_recording = nil

      render partial: 'clients/voice_recordings/js/show', locals: { cards: %w[voice_recordings] }
    end

    # (GET)
    # /client/:client_id/voice_recordings/:id/edit
    # edit_client_voice_recording_path(:client_id, :id)
    # edit_client_voice_recording_url(:client_id, :id)
    def edit
      render partial: 'clients/voice_recordings/js/show', locals: { cards: %w[voice_recordings_edit] }
    end

    # (GET)
    # /client/:client_id/voice_recordings
    # client_voice_recordings_path(:client_id)
    # client_voice_recordings_url(:client_id)
    def index
      respond_to do |format|
        format.js { render partial: 'clients/voice_recordings/js/show', locals: { cards: %w[voice_recordings] } }
        format.html { render 'clients/show', locals: { client_page_section: 'voice_recordings' } }
      end
    end

    # (GET)
    # /client/:client_id/voice_recordings/new
    # new_client_voice_recording_path(:client_id)
    # new_client_voice_recording_url(:client_id)
    def new
      @voice_recording = @client.voice_recordings.create(recording_name: 'New Recording')

      render partial: 'clients/voice_recordings/js/show', locals: { cards: %w[voice_recordings voice_recordings_new] }
    end

    # (PATCH) create a new recording for a VoiceRecording
    # /client/:client_id/voice_recordings/:id/new_voice_recording
    # new_voice_recording_path(:client_id, :id)
    # new_voice_recording_url(:client_id, :id)
    def new_voice_recording
      @voice_recording.update(params_voice_recording)

      if @voice_recording.url.present?
        Voice::Router.delete_rvm(client: @client, media_sid: @voice_recording.sid, media_url: @voice_recording.url)
        @voice_recording.update(sid: '', url: '')
      end

      @voice_recording.audio_file.purge if @voice_recording.audio_file.attached?

      from_phone = current_user.latest_client_phonenumber(current_session: session)

      Voice::Router.call(phone_vendor: from_phone&.phone_vendor.to_s, to_phone: current_user.phone, from_phone: from_phone&.phonenumber.to_s, callback_url: record_voice_recording_url(@client, @voice_recording), answer_url: record_voice_recording_url(@client, @voice_recording))

      render partial: 'clients/voice_recordings/js/show', locals: { cards: %w[voice_recordings] }
    end

    # (POST) callback after call is placed to User
    # should initiate a recording session
    # /client/:client_id/voice_recordings/:id/record_voice_recording
    # record_voice_recording_path(:client_id, :id)
    # record_voice_recording_url(:client_id, :id)
    def record_voice_recording
      result = Voice::Router.recording_start(params.merge({ save_recording_url: save_voice_recording_url(@client, @voice_recording) }))

      render xml: result
    end

    # (POST) SlyBroadcast response after sending Remote Voicemail
    # /twvoice/rvm_callback
    # rvm_callback_voice_recording_path(:client_id, :id)
    # rvm_callback_voice_recording_url(:client_id, :id)
    def rvm_callback
      result = RinglessVoicemail.callback(params)

      if result[:success] && (message = Messages::Message.find_by(account_sid: result[:account_id], message_sid: result[:message_id]))
        message.update(
          status:        result[:status],
          error_message: result[:error_message],
          read_at:       result[:read_at]
        )

        UserCable.new.broadcast message.contact.client, message.contact.user, { id: message.id, msg_status: message.status }

        message.contact.client.charge_for_action(key: 'rvm_credits', contact_id: message.contact_id, message_id: message.id) if result[:status] == 'delivered'
      end

      render plain: 'ok'
    end
    # var example:
    # "Session ID" | "Call To" | "Status" | "Reason for Failure" | "Delivery Time" | "Carrier"
    # "1842028314|8502924380|OK||2019-12-09 14:55:42|t-mobile us:6529 - svr/2"

    # (PATCH) save VoiceRecording audio file
    # /client/:client_id/voice_recordings/:id/save_audio_file
    # save_audio_file_voice_recording_path(:client_id, :id)
    # save_audio_file_voice_recording_url(:client_id, :id)
    def save_audio_file
      @voice_recording.audio_file.purge
      audio_file = params.permit(:audio_file).dig(:audio_file)
      @voice_recording.update(url: '', audio_file:)

      render partial: 'clients/voice_recordings/js/show', locals: { cards: %w[voice_recordings_edit] }
    end

    # (POST) callback after a recording is completed
    # /client/:client_id/voice_recordings/:id/save_voice_recording
    # save_audio_file_voice_recording_path(:client_id, :id)
    # save_audio_file_voice_recording_url(:client_id, :id)
    def save_voice_recording
      result = Voice::Router.recording_complete(params)

      if result[:success]

        begin
          @voice_recording.audio_file.purge if @voice_recording.audio_file.attached?

          case result[:phone_vendor]
          when 'twilio'

            while (retries ||= 0) < 10
              retries       += 1
              uri            = URI(result[:recording_url])
              request        = Net::HTTP.new(uri.host)
              request_result = request.request_head(uri.path)

              break if request_result.code.to_i == 200

              sleep ProcessError::Backoff.full_jitter(retries:)
            end

            # rubocop:disable Security/Open
            @voice_recording.audio_file.attach(io: URI.open(result[:recording_url]), filename: "voice_recording_#{@voice_recording_id}_#{Time.current.to_i}.mp3", content_type: 'audio/mp3')
            # rubocop:enable Security/Open
          when 'bandwidth'
            # rubocop:disable Security/Open
            @voice_recording.audio_file.attach(io: URI.open(result[:recording_url], 'Authorization' => "Basic #{Base64.urlsafe_encode64("#{Rails.application.credentials[:bandwidth][:user_name]}:#{Rails.application.credentials[:bandwidth][:password]}").strip}"), filename: "voice_recording_#{@voice_recording_id}_#{Time.current.to_i}.mp3", content_type: 'audio/mp3')
            # rubocop:enable Security/Open
          end

          @voice_recording.update(sid: '', url: '')
        rescue StandardError => e
          e.set_backtrace(BC.new.clean(caller))

          Appsignal.report_error(e) do |transaction|
            # Only needed if it needs to be different or there's no active transaction from which to inherit it
            Appsignal.set_action('Clients::VoiceRecordingsController#save_voice_recording')

            # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
            Appsignal.add_params(params)

            Appsignal.set_tags(
              error_level: 'error',
              error_code:  0
            )
            Appsignal.add_custom_data(
              audio_file:      @voice_recording.audio_file.url,
              request:         defined?(request) ? request : 'Undefined',
              result:          result.inspect,
              retries:         defined?(retries) ? retries : 'Undefined',
              uri:             defined?(uri) ? uri : 'Undefined',
              voice_recording: @voice_recording,
              file:            __FILE__,
              line:            __LINE__
            )
          end
        end

        # recording_url = Voice::Router.recording_transfer(phone_vendor: result[:phone_vendor], client: twnumber.client, recording_url: result[:recording_url])
        # @voice_recording.update(sid: result[:recording_sid], url: recording_url)
      end

      render xml: result[:response]
    end

    # (PUT/PATCH)
    # /client/:client_id/voice_recordings/:id
    # client_voice_recording_path(:client_id, :id)
    # client_voice_recording_url(:client_id, :id)
    def update
      @voice_recording.update(params_voice_recording)

      render partial: 'clients/voice_recordings/js/show', locals: { cards: %w[voice_recordings_edit] }
    end

    private

    def authorize_user!
      super
      return if current_user.access_controller?('clients', 'voice_recordings', session)

      raise ExceptionHandlers::UserNotAuthorized.new('My Company Profile > Voice Recordings', root_path)
    end

    def params_voice_recording
      params.include?(:voice_recording) ? params.require(:voice_recording).permit(:recording_name) : {}
    end

    def set_voice_recording
      sanitized_params = params.permit(:id)
      @voice_recording = if sanitized_params.dig(:id).to_i.zero?
                           @client.voice_recordings.new
                         else
                           @client.voice_recordings.find_by(id: sanitized_params.dig(:id).to_i)
                         end

      return if @voice_recording

      sweetalert_error('Voice Recording NOT found!', 'We were not able to access the Voice Recording you requested.', '', { persistent: 'OK' })

      respond_to do |format|
        format.js { render js: "window.location = '#{client_voice_recordings_path(@client.id)}'" and return false }
        format.html { redirect_to client_voice_recordings_path(@client.id) and return false }
      end
    end
  end
end
