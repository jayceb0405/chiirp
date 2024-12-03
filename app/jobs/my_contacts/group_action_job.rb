# frozen_string_literal: true

# app/jobs/my_contacts/group_action_job.rb
module MyContacts
  class GroupActionJob < ApplicationJob
    # process a group action on Contacts
    # MyContacts::GroupActionJob.set(wait_until: 1.day.from_now).perform_later()
    # MyContacts::GroupActionJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
    #   user_id:             Integer,
    #   triggeraction_id:    Integer,
    #   contact_campaign_id: Integer,
    #   process:             String,
    #   group_process:       Integer,
    #   group_uuid:          SecureRandom.uuid,
    #   data:                Hash
    # )

    def initialize(**args)
      super

      @process = (args.dig(:process).presence || 'my_contacts_group_action').to_s
    end

    # perform the ActiveJob
    #   (req) data:, action:      (String)
    #   (req) data:, contacts:    (Array)
    #   (req) user_id:            (Integer)
    #
    #   (opt) add_group_id:       (Integer)
    #   (opt) add_stage_id:       (Integer)
    #   (opt) add_tag_id:         (Integer)
    #   (opt) apply_campaign_id:  (Integer)
    #   (opt) file_attachments:   (Array)
    #   (opt) from_phones:        (Array)
    #   (opt) lead_source_id:     (Integer)
    #   (opt) message:            (String)
    #   (opt) remove_tag_id:      (Integer)
    #   (opt) remove_stage_id:    (Integer)
    #   (opt) run_at:             (DateTime / default: Time.current)
    #   (opt) selected_number:    (String)
    #   (opt) stop_campaign_id:   (Integer)
    #   (opt) target_time:        (Time)
    #   (opt) to_label:           (String)
    #   (opt) voice_recording_id: (Integer)
    def perform(**args)
      super

      @args = args.deep_symbolize_keys

      return if @args.dig(:data, :action).blank?
      return unless @args.dig(:data, :contacts).present? && @args[:data][:contacts].is_a?(Array)
      return unless @args.dig(:user_id).to_i.positive? && (@user = User.find_by(id: @args[:user_id]))

      @args = @args.merge(client: @user.client)

      # if @user is an Admin & the Client that the first Contact belongs to is active
      # the Client may not be active after the Client is deactivated by a SuperAdmin
      if @user.admin? && Contact.find_by(id: @args[:data][:contacts].first)&.client&.active?
        # add new message to div
        group_actions_count = DelayedJob.scheduled_actions(@user.id, Time.current.beginning_of_month, Time.current.end_of_month + 12.months).count
        UserCable.new.broadcast @user.client, @user, { id: "mycontacts_group_action_count_#{@user.id}", append: 'false', scrollup: 'false', html: group_actions_count.to_s }
      end

      @run_at = @args.dig(:run_at).respond_to?(:strftime) ? @args[:run_at] : Time.current

      send(@args[:data][:action])
    end

    private

    def add_group
      @args[:data][:contacts].each do |contact_id|
        Contacts::Groups::AddJob.set(wait_until: @run_at).perform_later(
          contact_campaign_id: @args.dig(:contact_campaign_id),
          contact_id:,
          group_id:            @args.dig(:data, :add_group_id),
          group_process:       @args.dig(:group_process),
          group_uuid:          @args.dig(:group_uuid),
          triggeraction_id:    @args.dig(:triggeraction_id),
          user_id:             @user.id
        )
      end
    end

    def add_stage
      @args[:data][:contacts].each do |contact_id|
        Contacts::Stages::AddJob.set(wait_until: @run_at).perform_later(
          client_id:           @user.client_id,
          contact_campaign_id: @args.dig(:contact_campaign_id),
          contact_id:,
          group_process:       @args.dig(:group_process),
          group_uuid:          @args.dig(:group_uuid),
          stage_id:            @args.dig(:data, :add_stage_id),
          triggeraction_id:    @args.dig(:triggeraction_id),
          user_id:             @user.id
        )
      end
    end

    def add_tag
      @args[:data][:contacts].each do |contact_id|
        Contacts::Tags::ApplyJob.set(wait_until: @run_at).perform_later(
          contact_campaign_id: @args.dig(:contact_campaign_id),
          contact_id:,
          group_process:       @args.dig(:group_process),
          group_uuid:          @args.dig(:group_uuid),
          triggeraction_id:    @args.dig(:triggeraction_id),
          user_id:             @user.id,
          tag_id:              @args.dig(:data, :add_tag_id)
        )
      end
    end

    def assign_lead_source
      @args[:data][:contacts].each do |contact_id|
        Contacts::LeadSources::AssignJob.set(wait_until: @run_at).perform_later(
          contact_campaign_id: @args.dig(:contact_campaign_id),
          contact_id:,
          lead_source_id:      @args.dig(:data, :lead_source_id),
          group_process:       @args.dig(:group_process),
          group_uuid:          @args.dig(:group_uuid),
          triggeraction_id:    @args.dig(:triggeraction_id),
          user_id:             @user.id
        )
      end
    end

    def assign_user
      @args[:data][:contacts].each do |contact_id|
        Contacts::AssignUserJob.set(wait_until: @run_at).perform_later(
          contact_campaign_id: @args.dig(:contact_campaign_id),
          contact_id:,
          group_process:       @args.dig(:group_process),
          group_uuid:          @args.dig(:group_uuid),
          new_user_id:         @args.dig(:data, :user_id),
          triggeraction_id:    @args.dig(:triggeraction_id),
          user_id:             @user.id
        )
      end
    end

    def contact_awake
      @args[:data][:contacts].each do |contact_id|
        Contacts::AwakeJob.set(wait_until: @run_at).perform_later(
          contact_campaign_id: @args.dig(:contact_campaign_id),
          contact_id:,
          group_process:       @args.dig(:group_process),
          group_uuid:          @args.dig(:group_uuid),
          triggeraction_id:    @args.dig(:triggeraction_id),
          user_id:             @user.id
        )
      end
    end

    def contact_delete
      run_at = @run_at

      @args[:data][:contacts].each do |contact_id|
        Contacts::DeleteJob.set(wait_until: run_at).perform_later(
          user_id:             @user.id,
          triggeraction_id:    @args.dig(:triggeraction_id),
          contact_campaign_id: @args.dig(:contact_campaign_id),
          group_process:       @args.dig(:group_process),
          group_uuid:          @args.dig(:group_uuid),
          contact_id:
        )
        run_at += 1.5.seconds
      end
    end

    def contact_sleep
      @args[:data][:contacts].each do |contact_id|
        Contacts::SleepJob.set(wait_until: @run_at).perform_later(
          contact_campaign_id: @args.dig(:contact_campaign_id),
          contact_id:,
          group_process:       @args.dig(:group_process),
          group_uuid:          @args.dig(:group_uuid),
          triggeraction_id:    @args.dig(:triggeraction_id),
          user_id:             @user.id
        )
      end
    end

    def group_action_common_args
      JsonLog.info 'MyContacts::GroupActionJob.group_action_common_args', { args: @args }
      {
        time_zone:     @args.dig(:client)&.time_zone,
        reverse:       false,
        delay_months:  0,
        delay_days:    0,
        delay_hours:   0,
        delay_minutes: 0,
        safe_start:    (@args.dig(:data, :common_args, :safe_start) || 480).to_i,
        safe_end:      (@args.dig(:data, :common_args, :safe_end) || 1200).to_i,
        safe_sun:      @args.dig(:data, :common_args).to_h.fetch(:safe_sun, true),
        safe_mon:      @args.dig(:data, :common_args).to_h.fetch(:safe_mon, true),
        safe_tue:      @args.dig(:data, :common_args).to_h.fetch(:safe_tue, true),
        safe_wed:      @args.dig(:data, :common_args).to_h.fetch(:safe_wed, true),
        safe_thu:      @args.dig(:data, :common_args).to_h.fetch(:safe_thu, true),
        safe_fri:      @args.dig(:data, :common_args).to_h.fetch(:safe_fri, true),
        safe_sat:      @args.dig(:data, :common_args).to_h.fetch(:safe_sat, true),
        holidays:      if @args.dig(:data, :common_args).to_h.fetch(:honor_holidays, true).to_bool
                         @args.dig(:client)&.holidays.to_h { |h| [h.occurs_at, (h.action == 'before' ? 'after' : h.action)] }
                       else
                         {}
                       end,
        ok2skip:       false
      }
    end

    def ok2text_off
      @args[:data][:contacts].each do |contact_id|
        Contacts::Ok2textOffJob.set(wait_until: @run_at).perform_later(
          contact_campaign_id: @args.dig(:contact_campaign_id),
          contact_id:,
          group_process:       @args.dig(:group_process),
          group_uuid:          @args.dig(:group_uuid),
          triggeraction_id:    @args.dig(:triggeraction_id),
          user_id:             @user.id
        )
      end
    end

    def ok2text_on
      @args[:data][:contacts].each do |contact_id|
        Contacts::Ok2textOnJob.set(wait_until: @run_at).perform_later(
          contact_campaign_id: @args.dig(:contact_campaign_id),
          contact_id:,
          group_process:       @args.dig(:group_process),
          group_uuid:          @args.dig(:group_uuid),
          triggeraction_id:    @args.dig(:triggeraction_id),
          user_id:             @user.id
        )
      end
    end

    def remove_group
      @args[:data][:contacts].each do |contact_id|
        Contacts::Groups::RemoveJob.set(wait_until: @run_at).perform_later(
          contact_campaign_id: @args.dig(:contact_campaign_id),
          contact_id:,
          group_id:            @args.dig(:data, :remove_group_id),
          group_process:       @args.dig(:group_process),
          group_uuid:          @args.dig(:group_uuid),
          triggeraction_id:    @args.dig(:triggeraction_id),
          user_id:             @user.id
        )
      end
    end

    def remove_stage
      Contact.where(id: @args[:data][:contacts], stage_id: @args.dig(:data, :remove_stage_id)).find_each do |contact|
        Contacts::Stages::RemoveJob.set(wait_until: @run_at).perform_later(
          contact_campaign_id: @args.dig(:contact_campaign_id),
          contact_id:          contact.id,
          group_process:       @args.dig(:group_process),
          group_uuid:          @args.dig(:group_uuid),
          stage_id:            @args.dig(:data, :remove_stage_id),
          triggeraction_id:    @args.dig(:triggeraction_id),
          user_id:             @user.id
        )
      end
    end

    def remove_tag
      @args[:data][:contacts].each do |contact_id|
        Contacts::Tags::RemoveJob.set(wait_until: @run_at).perform_later(
          contact_campaign_id: @args.dig(:contact_campaign_id),
          contact_id:,
          group_process:       @args.dig(:group_process),
          group_uuid:          @args.dig(:group_uuid),
          triggeraction_id:    @args.dig(:triggeraction_id),
          user_id:             @user.id,
          tag_id:              @args.dig(:data, :remove_tag_id)
        )
      end
    end

    def send_email
      run_at = AcceptableTime.new(group_action_common_args).new_time(@run_at)

      return if run_at.blank?

      Contact.where(id: @args[:data][:contacts]).find_each do |contact|
        contact.delay(
          run_at:,
          priority:            DelayedJob.job_priority('send_email'),
          queue:               DelayedJob.job_queue('send_email'),
          user_id:             @user.id,
          contact_id:          contact.id,
          triggeraction_id:    @args.dig(:triggeraction_id).to_i,
          contact_campaign_id: @args.dig(:contact_campaign_id).to_i,
          group_process:       @args.dig(:group_process),
          group_uuid:          @args.dig(:group_uuid),
          process:             'send_email',
          data:                { email_template_id: @args.dig(:data, :email_template_id), contact:, user: @user }
        ).send_email(
          email_template_id: @args.dig(:data, :email_template_id).to_i,
          content:           @args.dig(:data, :email_template_yield),
          subject:           @args.dig(:data, :email_template_subject),
          from_email:        @user.email,
          file_attachments:  @args.dig(:data, :file_attachments),
          payment_request:   @args.dig(:data, :payment_request).to_f
        )
      end
    end

    def send_rvm
      voice_recording = @user.client.voice_recordings.find_by(id: @args.dig(:data, :voice_recording_id).to_i)

      return unless voice_recording

      run_at = AcceptableTime.new(group_action_common_args).new_time(@run_at)

      return unless run_at.present?

      voice_recording_url = if voice_recording.audio_file.attached?
                              "#{Cloudinary::Utils.cloudinary_url(voice_recording.audio_file.key, resource_type: 'video', secure: true)}.mp3"
                            else
                              voice_recording.url
                            end

      Contact.where(id: @args[:data][:contacts]).find_each do |contact|
        contact_phones = if @args[:data].include?(:to_label) && !@args[:data][:to_label].to_s.strip.empty?
                           contact.contact_phones.where(label: @args[:data][:to_label]).pluck(:phone)
                         else
                           contact.contact_phones.where(primary: true).pluck(:phone)
                         end

        contact_phones.each do |to_phone|
          JsonLog.info 'MyContacts::GroupActionJob.send_rvm', { run_at: }
          data = {
            from_phone:          @args.dig(:data, :selected_number),
            message:             voice_recording.recording_name,
            to_phone:,
            user:                @user,
            voice_recording_id:  voice_recording.id,
            voice_recording_url:
          }
          contact.delay(
            run_at:,
            priority:            DelayedJob.job_priority('send_rvm'),
            queue:               DelayedJob.job_queue('send_rvm'),
            user_id:             @user.id,
            contact_id:          contact.id,
            triggeraction_id:    @args.dig(:triggeraction_id).to_i,
            contact_campaign_id: @args.dig(:contact_campaign_id).to_i,
            group_process:       @args.dig(:group_process),
            group_uuid:          @args.dig(:group_uuid),
            process:             'send_rvm',
            data:
          ).send_rvm(data)

          run_at += @user.client.text_delay.seconds
        end
      end
    end

    def send_text
      run_at = AcceptableTime.new(group_action_common_args).new_time(@run_at)

      return if run_at.blank?

      from_phones_element = 0

      Contact.where(id: @args[:data][:contacts]).find_each do |contact|
        image_id_array = []

        @args.dig(:data, :file_attachments).each do |fa|
          fa.deep_symbolize_keys!

          case fa[:type].to_s
          when 'user'
            file_attachment = @user.user_attachments.find_by(id: fa[:id])
          when 'contact'
            file_attachment = contact.contact_attachments.find_by(id: fa[:id])
          end

          if file_attachment

            case fa[:type].to_s
            when 'user'
              begin
                contact_attachment = contact.contact_attachments.new
                contact_attachment.remote_image_url = file_attachment.image.url(secure: true)
                contact_attachment.save
                image_id_array << contact_attachment.id
              rescue Cloudinary::CarrierWave::UploadError => e
                e.set_backtrace(BC.new.clean(caller))

                Appsignal.report_error(e) do |transaction|
                  # Only needed if it needs to be different or there's no active transaction from which to inherit it
                  Appsignal.set_action('MyContacts::GroupActionJob.send_text')

                  # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
                  Appsignal.add_params(@args)

                  Appsignal.set_tags(
                    error_level: 'error',
                    error_code:  0
                  )
                  Appsignal.add_custom_data(
                    client_id:                    contact.client_id,
                    contact_id:                   contact.id,
                    fa:,
                    file_attachment:,
                    user_action_file_attachments: @args[:data][:file_attachments],
                    contact_attachment:           defined?(contact_attachment) ? contact_attachment : 'Undefined',
                    file:                         __FILE__,
                    line:                         __LINE__
                  )
                end
              rescue ActiveRecord::RecordInvalid => e
                e.set_backtrace(BC.new.clean(caller))

                Appsignal.report_error(e) do |transaction|
                  # Only needed if it needs to be different or there's no active transaction from which to inherit it
                  Appsignal.set_action('MyContacts::GroupActionJob.send_text')

                  # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
                  Appsignal.add_params(@args)

                  Appsignal.set_tags(
                    error_level: 'error',
                    error_code:  0
                  )
                  Appsignal.add_custom_data(
                    client_id:                    contact.client_id,
                    contact_id:                   contact.id,
                    fa:,
                    file_attachment:,
                    user_action_file_attachments: @args[:data][:file_attachments],
                    contact_attachment:           defined?(contact_attachment) ? contact_attachment : 'Undefined',
                    file:                         __FILE__,
                    line:                         __LINE__
                  )
                end
              rescue StandardError => e
                e.set_backtrace(BC.new.clean(caller))

                Appsignal.report_error(e) do |transaction|
                  # Only needed if it needs to be different or there's no active transaction from which to inherit it
                  Appsignal.set_action('MyContacts::GroupActionJob.send_text')

                  # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
                  Appsignal.add_params(@args)

                  Appsignal.set_tags(
                    error_level: 'error',
                    error_code:  0
                  )
                  Appsignal.add_custom_data(
                    client_id:                    contact.client_id,
                    contact_id:                   contact.id,
                    fa:,
                    file_attachment:,
                    user_action_file_attachments: @args[:data][:file_attachments],
                    contact_attachment:           defined?(contact_attachment) ? contact_attachment : 'Undefined',
                    file:                         __FILE__,
                    line:                         __LINE__
                  )
                end
              end
            when 'contact'
              image_id_array << file_attachment.id
            end
          end
        end

        contact_phones = if @args[:data].include?(:to_label) && !@args[:data][:to_label].to_s.strip.empty?
                           contact.contact_phones.where(label: @args[:data][:to_label]).pluck(:phone)
                         else
                           contact.contact_phones.where(primary: true).pluck(:phone)
                         end

        contact_phones.each do |to_phone|
          from_phone = if @args.dig(:data, :from_phones).blank? || @args.dig(:data, :from_phones)&.include?('last')

                         if (message = contact.messages.where(to_phone:).or(contact.messages.where(from_phone: to_phone)).order(created_at: :desc).limit(1).first)
                           message.to_phone == to_phone ? message.from_phone : message.to_phone
                         elsif @args.dig(:data, :from_phones) & [from_phones_element] == 'last' && @args.dig(:data, :from_phones)&.length.to_i > 1
                           @args[:data][:from_phones][from_phones_element = from_phones_element + 1 == @args[:data][:from_phones].length ? 0 : from_phones_element + 1]
                         else
                           @user.default_from_twnumber&.phonenumber.to_s
                         end
                       else
                         @args[:data][:from_phones][from_phones_element]
                       end

          JsonLog.info 'MyContacts::GroupActionJob.send_text', { message: 'From Phone Number Empty', from_phone:, args: @args }, user_id: @user.id, contact_id: contact.id if from_phone.blank?

          run_at = PhoneNumberReservations.new(from_phone).reserve(group_action_common_args.merge(action_time: run_at)) if from_phone.present?
          JsonLog.info 'MyContacts::GroupActionJob.send_text', { contact_id: contact.id, run_at: }

          if run_at.present?
            data = {
              action:         @args.dig(:data, :action),
              automated:      true,
              common_args:    @args.dig(:data, :common_args),
              content:        @args.dig(:data, :message),
              from_phone:,
              image_id_array:,
              msg_type:       'textout',
              to_phone:,
              user:           @user
            }
            contact.delay(
              run_at:,
              priority:            DelayedJob.job_priority('send_text'),
              queue:               DelayedJob.job_queue('send_text'),
              user_id:             @user.id,
              contact_id:          contact.id,
              triggeraction_id:    @args.dig(:triggeraction_id).to_i,
              contact_campaign_id: @args.dig(:contact_campaign_id).to_i,
              group_process:       @args.dig(:group_process),
              group_uuid:          @args.dig(:group_uuid),
              process:             'send_text',
              data:
            ).send_text(data)
          end
        end

        from_phones_element = from_phones_element + 1 == @args.dig(:data, :from_phones)&.length.to_i ? 0 : from_phones_element + 1
      end
    end

    def start_campaign
      run_at = AcceptableTime.new(group_action_common_args).new_time(@run_at)
      JsonLog.info 'MyContacts::GroupActionJob.start_campaign', { run_at: }

      return if run_at.blank?

      Contact.where(id: @args[:data][:contacts]).find_each do |contact|
        Contacts::Campaigns::StartJob.set(wait_until: run_at).perform_later(
          campaign_id:         @args.dig(:data, :apply_campaign_id),
          client_id:           contact.client_id,
          contact_campaign_id: @args.dig(:contact_campaign_id),
          contact_id:          contact.id,
          group_process:       @args.dig(:group_process),
          group_uuid:          @args.dig(:group_uuid),
          target_time:         @args.dig(:data, :target_time),
          triggeraction_id:    @args.dig(:triggeraction_id),
          user_id:             @user.id
        )

        run_at += @args[:client].text_delay.to_i.seconds
      end
    end

    def stop_campaign
      @args[:data][:contacts].each do |contact_id|
        Contacts::Campaigns::StopJob.set(wait_until: @run_at).perform_later(
          campaign_id:         @args.dig(:data, :stop_campaign_id),
          contact_campaign_id: @args.dig(:contact_campaign_id),
          contact_id:,
          group_process:       @args.dig(:group_process),
          group_uuid:          @args.dig(:group_uuid),
          triggeraction_id:    @args.dig(:triggeraction_id),
          user_id:             @user.id
        )
      end
    end
  end
end
