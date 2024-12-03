# frozen_string_literal: true

# app/models/messages/message.rb
module Messages
  class Message < ApplicationRecord
    class MessageError < StandardError; end

    self.table_name = 'messages'

    belongs_to :contact
    belongs_to :aiagent_session,  optional: true, class_name: '::Aiagent::Session'
    belongs_to :read_at_user,     optional: true, class_name: :User
    belongs_to :triggeraction,    optional: true
    belongs_to :user,             optional: true
    belongs_to :voice_recording,  optional: true

    has_many   :folder_assignments,    dependent: :delete_all, class_name: '::Messages::FolderAssignment'
    has_many   :folders,               through: :folder_assignments
    has_many   :attachments,           dependent: :destroy,     class_name: '::Messages::Attachment'
    has_one    :email,                 dependent: :destroy,     class_name: '::Messages::Email'
    has_one    :aiagent,               through: :aiagent_session

    validates :from_phone, presence: true

    accepts_nested_attributes_for :attachments

    before_save :before_save_process
    after_save  :after_save_process

    scope :emails_delivered_by_client, ->(client_id, from_date, to_date) {
      where(created_at: from_date..to_date)
        .where(status: 'sent')
        .where(msg_type: MSG_TYPES_EMAILOUT)
        .joins(:contact)
        .where(contacts: { client_id: })
    }
    scope :emails_delivered_by_user, ->(user_id, from_date, to_date) {
      where(created_at: from_date..to_date)
        .where(status: 'sent')
        .where(msg_type: MSG_TYPES_EMAILOUT)
        .joins(:contact)
        .where(contacts: { user_id: })
    }
    scope :emails_received_by_client, ->(client_id, from_date, to_date) {
      where(created_at: from_date..to_date)
        .where(msg_type: MSG_TYPES_EMAILIN)
        .joins(:contact)
        .where(contacts: { client_id: })
    }
    scope :emails_received_by_user, ->(user_id, from_date, to_date) {
      where(created_at: from_date..to_date)
        .where(msg_type: MSG_TYPES_EMAILIN)
        .joins(:contact)
        .where(contacts: { user_id: })
    }
    scope :emails_sent_by_client, ->(client_id, from_date, to_date) {
      where(created_at: from_date..to_date)
        .where(msg_type: MSG_TYPES_EMAILOUT)
        .joins(:contact)
        .where(contacts: { client_id: })
    }
    scope :emails_sent_by_user, ->(user_id, from_date, to_date) {
      where(created_at: from_date..to_date)
        .where(msg_type: MSG_TYPES_EMAILOUT)
        .joins(:contact)
        .where(contacts: { user_id: })
    }
    scope :requiring_updates, ->(past_days, past_hours) {
      where(status: nil)
        .or(Messages::Message.where(msg_type: MSG_TYPES_TEXT + MSG_TYPES_VOICE))
        .where(cost: 0)
        .or(Messages::Message.where(num_segments: 0))
        .where.not(msg_type: MSG_TYPES_VIDEO)
        .where.not(message_sid: nil)
        .where(account_sid: [Rails.application.credentials[:twilio][:sid], Rails.application.credentials[:bandwidth][:sid]])
        .where('created_at > ?', (Time.current - past_days.days - past_hours.hours).to_s)
        .where(error_code: nil)
    }
    scope :segments_delivered_by_client, ->(client_id, from_date, to_date) {
      texts_delivered_by_client(client_id, from_date, to_date)
        .select(:num_segments)
        .sum(:num_segments)
    }
    scope :segments_delivered_by_user, ->(user_id, from_date, to_date) {
      texts_delivered_by_user(user_id, from_date, to_date)
        .select(:num_segments)
        .sum(:num_segments)
    }
    scope :segments_received_by_client, ->(client_id, from_date, to_date) {
      texts_received_by_client(client_id, from_date, to_date)
        .select(:num_segments)
        .sum(:num_segments)
    }
    scope :segments_received_by_user, ->(user_id, from_date, to_date) {
      texts_received_by_user(user_id, from_date, to_date)
        .select(:num_segments)
        .sum(:num_segments)
    }
    scope :segments_sent_by_client, ->(client_id, from_date, to_date) {
      texts_sent_by_client(client_id, from_date, to_date)
        .select(:num_segments)
        .sum(:num_segments)
    }
    scope :segments_sent_by_user, ->(user_id, from_date, to_date) {
      texts_sent_by_user(user_id, from_date, to_date)
        .select(:num_segments)
        .sum(:num_segments)
    }
    scope :texts_delivered_by_client, ->(client_id, from_date, to_date) {
      where(created_at: from_date..to_date)
        .where(status: 'delivered')
        .where(msg_type: MSG_TYPES_TEXTOUT)
        .joins(:contact)
        .where(contacts: { client_id: })
    }
    scope :texts_delivered_by_user, ->(user_id, from_date, to_date) {
      where(created_at: from_date..to_date)
        .where(status: 'delivered')
        .where(msg_type: MSG_TYPES_TEXTOUT)
        .joins(:contact)
        .where(contacts: { user_id: })
    }
    scope :texts_received_by_client, ->(client_id, from_date, to_date) {
      where(created_at: from_date..to_date)
        .where(msg_type: MSG_TYPES_TEXTIN)
        .joins(:contact)
        .where(contacts: { client_id: })
    }
    scope :texts_received_by_user, ->(user_id, from_date, to_date) {
      where(created_at: from_date..to_date)
        .where(msg_type: MSG_TYPES_TEXTIN)
        .joins(:contact)
        .where(contacts: { user_id: })
    }
    scope :texts_sent_by_client, ->(client_id, from_date, to_date) {
      where(created_at: from_date..to_date)
        .where(msg_type: MSG_TYPES_TEXTOUT)
        .joins(:contact)
        .where(contacts: { client_id: })
    }
    scope :texts_sent_by_user, ->(user_id, from_date, to_date) {
      where(created_at: from_date..to_date)
        .where(msg_type: MSG_TYPES_TEXTOUT)
        .joins(:contact)
        .where(contacts: { user_id: })
    }
    scope :unread_messages_by_client, ->(client_id) {
      where(read_at: nil, automated: false)
        .joins(:contact)
        .where(contacts: { client_id: })
        .limit(250)
    }
    scope :unread_messages_by_contact, ->(contact_id) {
      where(read_at: nil, automated: false)
        .where(contact_id:)
    }
    scope :unread_messages_by_user, ->(user_id) {
      where(read_at: nil, automated: false)
        .joins(:contact)
        .where(contacts: { user_id: })
    }
    scope :voice_received_by_client, ->(client_id, from_date, to_date) {
      where(created_at: from_date..to_date)
        .where(msg_type: MSG_TYPES_VOICEIN)
        .joins(:contact)
        .where(contacts: { client_id: })
    }
    scope :voice_received_by_user, ->(user_id, from_date, to_date) {
      where(created_at: from_date..to_date)
        .where(msg_type: MSG_TYPES_VOICEIN)
        .joins(:contact)
        .where(contacts: { user_id: })
    }
    scope :voice_sent_by_client, ->(client_id, from_date, to_date) {
      where(created_at: from_date..to_date)
        .where(msg_type: MSG_TYPES_VOICEOUT)
        .joins(:contact)
        .where(contacts: { client_id: })
    }
    scope :voice_sent_by_user, ->(user_id, from_date, to_date) {
      where(created_at: from_date..to_date)
        .where(msg_type: MSG_TYPES_VOICEOUT)
        .joins(:contact)
        .where(contacts: { user_id: })
    }
    scope :voice_recordings_delivered, ->(id, from_date = 50.years.ago, to_date = Time.current) {
      where(status: 'delivered', created_at: from_date..to_date, voice_recording_id: id)
    }
    scope :voice_recordings_failed, ->(id, from_date = 50.years.ago, to_date = Time.current) {
      where(status: %w[failed Failure undelivered], created_at: from_date..to_date, voice_recording_id: id)
    }
    scope :voice_recordings_delivered_by_user, ->(id, user_id, from_date = 50.years.ago, to_date = Time.current) {
      joins(:contact)
        .where(status: 'delivered', created_at: from_date..to_date, voice_recording_id: id)
        .where(contacts: { user_id: })
    }
    scope :voice_recordings_failed_by_user, ->(id, user_id, from_date = 50.years.ago, to_date = Time.current) {
      joins(:contact)
        .where(status: %w[failed Failure undelivered], created_at: from_date..to_date, voice_recording_id: id)
        .where(contacts: { user_id: })
    }

    MSG_TYPES_EMAILOUT = %w[emailout].freeze
    MSG_TYPES_EMAILIN  = %w[emailin].freeze
    MSG_TYPES_EMAIL    = (MSG_TYPES_EMAILOUT + MSG_TYPES_EMAILIN).freeze
    MSG_TYPES_FBIN     = %w[fbin].freeze
    MSG_TYPES_FBOUT    = %w[fbout].freeze
    MSG_TYPES_FB       = (MSG_TYPES_FBIN + MSG_TYPES_FBOUT).freeze
    MSG_TYPES_GGLIN    = %w[gglin].freeze
    MSG_TYPES_GGLOUT   = %w[gglout].freeze
    MSG_TYPES_GGL      = (MSG_TYPES_GGLIN + MSG_TYPES_GGLOUT).freeze
    MSG_TYPES_PAYMENT  = %w[payment].freeze
    MSG_TYPES_RVM      = %w[rvmout].freeze
    MSG_TYPES_TEXTOUT  = %w[textout textoutuser textoutaiagent textoutother].freeze
    MSG_TYPES_TEXTIN   = %w[textin textinuser textinother].freeze
    MSG_TYPES_TEXT     = (MSG_TYPES_TEXTOUT + MSG_TYPES_TEXTIN).freeze
    MSG_TYPES_VOICEIN  = %w[voicein voicemail].freeze
    MSG_TYPES_VOICEOUT = %w[voiceout].freeze
    MSG_TYPES_VOICE    = (MSG_TYPES_VOICEIN + MSG_TYPES_VOICEOUT).freeze
    MSG_TYPES_VIDEO    = %w[video].freeze
    MSG_TYPES_WIDGET   = %w[widgetin].freeze
    MSG_TYPES          = (MSG_TYPES_TEXT + MSG_TYPES_FB + MSG_TYPES_GGL + MSG_TYPES_PAYMENT + MSG_TYPES_VOICE + MSG_TYPES_RVM + MSG_TYPES_EMAIL + MSG_TYPES_VIDEO + MSG_TYPES_WIDGET).freeze
    MSG_TYPES_OUT      = (MSG_TYPES_TEXTOUT + MSG_TYPES_FBOUT + MSG_TYPES_GGLOUT + MSG_TYPES_EMAILOUT + MSG_TYPES_VOICEOUT).freeze
    MSG_TYPES_IN       = (MSG_TYPES_TEXTIN + MSG_TYPES_FBIN + MSG_TYPES_GGLIN + MSG_TYPES_EMAILIN + MSG_TYPES_VOICEIN).freeze

    # apply an incoming text message to a Contact
    # Messages::Message.apply_incoming_text_message_to_contact(message)
    def self.apply_incoming_text_message_to_contact(new_message)
      to_phone   = new_message[:to_phone].delete_prefix('+1')
      from_phone = new_message[:from_phone].delete_prefix('+1')
      response   = { success: false, client_id: 0, message: nil, error_code: '', error_message: '' }

      contact_result = Messages::Message.find_or_initialize_contact_from_text(new_message)

      if contact_result[:success]
        response[:client_id] = contact_result[:contact].client_id

        if contact_result[:contact].update(
          firstname: (contact_result[:contact].firstname.present? || contact_result[:contact].lastname.present? ? contact_result[:contact].firstname : 'Friend'),
          # ok2text:   '1',
          sleep:     false
        )
          contact_is_visible = Users::RedisPool.new(contact_result[:contact].user_id).contact_visible_by_user_in_message_central?(contact_result[:contact].id)

          message = contact_result[:contact].messages.create(
            account_sid:     new_message[:account_sid],
            contact_id:      contact_result[:contact].id,
            from_city:       new_message[:from_city],
            from_phone:,
            from_state:      new_message[:from_state],
            from_zip:        new_message[:from_zip],
            message:         new_message[:content].clean_smart_quotes, # remove unwanted characters
            message_sid:     new_message[:message_sid],
            msg_type:        contact_result[:msg_type],
            num_segments:    new_message[:segment_count],
            read_at:         contact_is_visible ? Time.current : nil,
            read_at_user_id: contact_is_visible ? contact_result[:contact].user_id : nil,
            status:          'received',
            to_phone:
          )

          # update Messages::Message with received media
          # SMS::Router.attach_media(message: message, media_array: message[:media_array]) if message[:media_array].present?
          if new_message[:media_array].present?
            message.delay(
              priority:   DelayedJob.job_priority('message_attach_media'),
              queue:      DelayedJob.job_queue('message_attach_media'),
              contact_id: contact_result[:contact].id,
              user_id:    contact_result[:contact].user_id,
              process:    'message_attach_media',
              data:       { media_array: new_message[:media_array] }
            ).attach_media(new_message[:media_array])
          end

          # update Contact list in Message Central
          show_live_messenger = ShowLiveMessenger.new(message:)
          show_live_messenger.queue_broadcast_active_contacts
          show_live_messenger.queue_broadcast_message_thread_message

          # start Campaigns for Triggers that fire on incoming text messages
          active_campaigns = contact_result[:contact].active_campaigns
          dayofweek = Time.current.in_time_zone(contact_result[:contact].client.time_zone).strftime('%a').downcase
          minuteofday = (Time.current.in_time_zone(contact_result[:contact].client.time_zone).hour * 60) + Time.current.in_time_zone(contact_result[:contact].client.time_zone).min

          Trigger.where(trigger_type: 155, campaign_id: contact_result[:contact].client.campaigns).find_each do |trigger|
            if trigger.data.include?(:phone_number) && (trigger.data[:phone_number].to_s.empty? || trigger.data[:phone_number].to_s == to_phone) &&
               trigger.data.include?(:new_contacts_only) && (trigger.data[:new_contacts_only].to_i.zero? || contact_result[:contact].new_record?) &&
               trigger.data.include?(:process_times_a) && trigger.data.include?(:process_times_b) &&
               (minuteofday.between?(trigger.data[:process_times_a].split(';')[0].to_i, trigger.data[:process_times_a].split(';')[1].to_i) || minuteofday.between?(trigger.data[:process_times_b].split(';')[0].to_i, trigger.data[:process_times_b].split(';')[1].to_i)) &&
               trigger.data.include?(:"process_#{dayofweek}") && trigger.data[:"process_#{dayofweek}"].to_i == 1 && active_campaigns.exclude?(trigger.campaign_id.to_i)
              # criteria is met to start Campaign

              Contacts::Campaigns::StartJob.perform_later(
                campaign_id: trigger.campaign_id,
                client_id:   contact_result[:contact].client_id,
                contact_id:  contact_result[:contact].id,
                message_id:  message.id,
                user_id:     contact_result[:contact].user_id
              )
            end
          end

          response[:success] = true
          response[:message] = message
        else
          response[:error_message] = "Contact could NOT be created. To Phone: #{to_phone} / From Phone: #{from_phone}. #{contact_result[:contact].errors.full_messages.join(' ')}"
        end
      else
        response[:error_message] = "Contact could NOT be created. To Phone: #{to_phone} / From Phone: #{from_phone}. #{contact_result[:error_message]}"
      end

      response
    end

    def attach_media(media_array)
      SMS::Router.attach_media(message: self, media_array:)

      show_live_messenger = ShowLiveMessenger.new(message: self)
      show_live_messenger.queue_broadcast_active_contacts
      show_live_messenger.queue_broadcast_message_thread_message
    end

    # generate a message thread for a Contact
    # Messages::Message.contact_message_thread()
    #   (req) contact:              (Contact)
    #   (req) current_phone_number: (String)
    def self.contact_message_thread(contact:, current_phone_number:)
      return [] if current_phone_number.blank?

      message_thread = case current_phone_number
                       when 'all'
                         contact.messages
                       when 'email'
                         contact.messages.where(msg_type: Messages::Message::MSG_TYPES_EMAIL)
                       when 'fb'
                         contact.messages.where(msg_type: Messages::Message::MSG_TYPES_FB)
                       when 'ggl'
                         contact.messages.where(msg_type: Messages::Message::MSG_TYPES_GGL)
                       when 'widget'
                         contact.messages.where(msg_type: Messages::Message::MSG_TYPES_WIDGET)
                       else
                         contact.messages.where(to_phone: current_phone_number).or(contact.messages.where(from_phone: current_phone_number))
                       end

      message_thread = message_thread.includes({ attachments: :contact_attachment }, :folder_assignments, :user, { triggeraction: { trigger: :campaign } }).order(created_at: :asc)

      message_thread = message_thread.to_a

      if !contact.new_record? && contact.client.integrations_allowed.include?('google')
        Review.where(contact_id: contact.id).find_each do |review|
          message_thread << Messages::Message.new(
            message:            "Review: #{review.star_rating} Stars",
            contact_id:         review.contact_id,
            created_at:         review.target_created_at,
            updated_at:         review.target_updated_at,
            from_phone:         'review',
            to_phone:           '',
            status:             'received',
            num_segments:       0,
            msg_type:           'review',
            automated:          false,
            voice_recording_id: nil
          )
        end
      end

      if !contact.new_record? && (contact.client.integrations_allowed.include?('dope_marketing') || contact.client.integrations_allowed.include?('sendjim'))
        Postcard.where(contact_id: contact.id).find_each do |postcard|
          message_thread << Messages::Message.new(
            message:            "#{postcard.target.titleize} Automation: #{postcard.card_name}",
            contact_id:         postcard.contact_id,
            created_at:         postcard.created_at,
            updated_at:         postcard.updated_at,
            from_phone:         'postcard',
            to_phone:           '',
            status:             postcard.result.to_bool ? 'mailed' : 'failed',
            num_segments:       0,
            msg_type:           'postcard',
            automated:          false,
            voice_recording_id: nil
          )
        end
      end

      # add aiagent status changes
      contact.aiagent_sessions.includes(:aiagent_messages, :messages).find_each do |session|
        message_thread << Messages::Message.new(
          message:            'AI Agent Started',
          contact_id:         contact.id,
          created_at:         session.created_at,
          updated_at:         session.updated_at,
          from_phone:         '',
          to_phone:           '',
          status:             '',
          num_segments:       0,
          msg_type:           'aiagentstatus',
          automated:          false,
          voice_recording_id: nil
        )

        if session.ended_at
          # add a second to ensure status shows up after the last text message sent
          ended_at = session.last_interaction_at == session.ended_at ? session.last_interaction_at : session.last_interaction_at + 1.second

          message_thread << Messages::Message.new(
            message:            'AI Agent Ended',
            contact_id:         contact.id,
            created_at:         ended_at,
            updated_at:         session.ended_at,
            from_phone:         '',
            to_phone:           '',
            status:             session.ended_reason,
            num_segments:       0,
            msg_type:           'aiagentstatus',
            automated:          false,
            voice_recording_id: nil
          )
        end
      end

      message_thread.sort_by(&:created_at)
    end

    def email?
      MSG_TYPES_EMAIL.include?(self.msg_type)
    end

    def facebook?
      MSG_TYPES_FB.include?(self.msg_type)
    end

    # find a Contact or create one if possible
    # Messages::Message.find_or_initialize_contact_from_text(message)
    def self.find_or_initialize_contact_from_text(message)
      to_phone   = message.dig(:to_phone).to_s.delete_prefix('+1')
      from_phone = message.dig(:from_phone).to_s.delete_prefix('+1')
      response   = { success: false, client_id: 0, contact: nil, msg_type: 'textin', error_message: '' }

      if (twnumber = Twnumber.find_by(phonenumber: to_phone))
        # a Client owns the phone number texted to
        response[:client_id] = twnumber.client_id

        if (contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: twnumber.client_id, phones: { from_phone => 'mobile' }))
          response[:contact]       = contact
          response[:success]       = true
        else
          response[:error_message] = "Unable to locate or create new Contact with phone number (#{from_phone})."

          error = MessageError.new('Incompatible \'from_phone\'.')
          error.set_backtrace(BC.new.clean(caller))

          Appsignal.report_error(error) do |transaction|
            # Only needed if it needs to be different or there's no active transaction from which to inherit it
            Appsignal.set_action('Messages::Message.find_or_initialize_contact_from_text')

            # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
            Appsignal.add_params({ message: })

            Appsignal.set_tags(
              error_level: 'error',
              error_code:  0
            )
            Appsignal.add_custom_data(
              to_phone:   to_phone.inspect,
              from_phone: from_phone.inspect,
              response:   response.inspect,
              file:       __FILE__,
              line:       __LINE__
            )
          end
        end

        if response[:contact]&.new_record? && (twnumberuser = twnumber.twnumberusers.find_by(def_user: true))
          # if a default User is assigned to this phone number that will override the Client default User
          response[:contact].user_id = twnumberuser.user_id
        end
      else
        # no Client owns the phone number texted to
        # this should never happen
        response[:error_message] = "Text received from unknown phone number (#{to_phone})."
        JsonLog.info 'Messages::Message.find_or_initialize_contact_from_text', { from_phone: }
      end

      response
    end

    def google?
      MSG_TYPES_GGL.include?(self.msg_type)
    end

    def icon
      Messages::Message.message_icon(self.msg_type)
    end

    def mark_as_unread
      self.update(read_at: nil, read_at_user_id: nil)
    end

    def self.message_icon(msg_type)
      case msg_type
      when 'aiagentstatus'
        'fa fa-robot'
      when 'textin', 'textout', 'textinuser', 'textoutuser', 'textoutaiagent', 'textinother', 'textoutother'
        'fa fa-comment'
      when 'emailout', 'emailin'
        'fa fa-envelope'
      when 'fbin', 'fbout'
        'fab fa-facebook'
      when 'gglin', 'gglout'
        'fab fa-google'
      when 'payment'
        'fa fa-credit-card'
      when 'rvmout', 'voicemail'
        'fa fa-voicemail'
      when 'video'
        'fa fa-video'
      when 'voicein', 'voiceout'
        'fa fa-phone'
      when 'widgetin'
        'fa fa-cog'
      else
        'fa fa-question'
      end
    end

    # message.notify_users
    # send push notifications to all selected Users
    def notify_users
      return if self.contact.block

      user_ids = self.contact.user.notifications.dig('text', 'arrive')

      if (client_ids = Client.where(id: self.contact.client.my_agencies).where('data @> ?', { agency_access: true }.to_json).pluck(:id)).present?
        user_ids += User.where(client_id: client_ids).where('data @> ?', { notifications: { agency_clients: [self.contact.client_id] } }.to_json).pluck(:id)
      end

      User.where(id: user_ids).find_each do |user|
        if user.notifications.dig('text', 'on_contact') || !Users::RedisPool.new(user.id).contact_visible_by_user_in_message_central?(self.contact_id)
          app_host = I18n.with_locale(self.contact.client.tenant) { I18n.t("tenant.#{Rails.env}.app_host") }
          Users::SendPushJob.perform_later(
            contact_id: self.id,
            content:    "#{self.contact.fullname}: #{self.message}",
            title:      'Message Received',
            type:       'text',
            url:        Rails.application.routes.url_helpers.central_url(contact_id: self.contact_id, host: app_host),
            user_id:    user.id
          )
        end
      end
    end

    def rvm?
      MSG_TYPES_RVM.include?(self.msg_type)
    end

    # process an incoming text message for Campaigns to process
    # message.trigger_campaigns
    def trigger_campaigns
      Rails.logger.info "Messages::Message.trigger_campaigns: #{{ message: self }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"

      # send message to ai agent and stop processing; if there is an active aiagent_session
      return self.contact.aiagent_sessions.sms_session.active.first.respond_with_message!(self) if self.contact.aiagent_sessions.sms_session.active.any?

      # gather up all the Campaigns this Contact has not completed
      active_campaigns = self.contact.contact_campaigns.where(completed: false).order(created_at: :desc)
      Rails.logger.info "Messages::Message.trigger_campaigns: #{{ active_campaigns: active_campaigns.pluck(:campaign_id, :id) }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"

      active_campaigns.each do |contact_campaign|
        next unless contact_campaign.campaign.validate_lock_phone(contact: self.contact, phone_number: self.to_phone)

        # find last Triggeraction completed for this Campaign instance
        contact_campaign_triggeraction = contact_campaign.contact_campaign_triggeractions.order(:created_at).last

        # find the next Trigger of this Campaign instance for this Contact
        if (trigger = contact_campaign.campaign.triggers.where('step_numb > ?', (contact_campaign_triggeraction.nil? ? '0' : contact_campaign_triggeraction.trigger.step_numb.to_s)).order(:step_numb).first)
          trigger.fire(contact: self.contact, contact_campaign:, message: self)
          active_campaigns.where.not(id: contact_campaign.id).each(&:stop)
          return
        end
      end

      # self.contact.client.campaigns.where(active: true).includes(:triggers).references(:triggers).merge(Trigger.order(:step_numb)).find_each do |campaign|
      self.contact.client.campaigns.where(active: true).includes(:triggers).group(:id).order(created_at: :desc).each do |campaign|
        next unless campaign.validate_lock_phone(contact: self.contact, phone_number: self.to_phone)

        trigger = campaign.triggers.first

        if trigger && trigger.trigger_type == 110 && trigger.data && trigger.data.include?(:keyword) && (
            (((trigger.data.include?(:keyword_location) && trigger.data[:keyword_location].to_i == 1) || trigger.data.exclude?(:keyword_location)) && self.message.to_s.strip.casecmp?(trigger.data[:keyword].to_s.strip)) ||
            (trigger.data.include?(:keyword_location) && trigger.data[:keyword_location].to_i == 2 && self.message.to_s.strip[0, trigger.data[:keyword].to_s.strip.length].casecmp?(trigger.data[:keyword].to_s.strip)) ||
            (trigger.data.include?(:keyword_location) && trigger.data[:keyword_location].to_i == 3 && self.message.to_s.strip.downcase.include?(trigger.data[:keyword].to_s.strip.downcase))
          ) && ((campaign.allow_repeat && (campaign.allow_repeat_period == 'immediately' || self.contact.contact_campaigns.where(campaign_id: campaign.id).where('created_at > ?', campaign.allow_repeat_interval.send(campaign.allow_repeat_period).ago).blank?)) || !campaign.contact_campaigns.find_by(contact_id: self.contact.id, completed: true))
          # could start Contact in this Campaign

          trigger.fire(contact: self.contact, contact_campaign: campaign.contact_campaigns.find_by(contact_id: self.contact.id, completed: false)&.last, message: self)
          break
        end
      end
    end

    # scan through all Messages::Messages with status other than "delivered"
    # Messages::Message.update_all_message_status( past_days: 7, past_hours: 0 )
    def self.update_all_message_status(args = {})
      Messages::Message.requiring_updates((args.dig(:past_days) || 7).to_i, args.dig(:past_hours).to_i).find_each do |message|
        SMS::Router.update_status message
      end
    end

    def text?
      MSG_TYPES_TEXT.include?(self.msg_type)
    end

    def to_openai
      {
        role:    self.msg_type == 'textout' ? :assistant : :user,
        content: self.msg_type == 'textout' ? self.message.gsub(%r{^AI: }, '') : self.message
      }
    end

    def type_as_title
      if self.text?
        'Text Message'
      elsif self.email?
        'Email'
      elsif self.voice?
        'Phone Call'
      elsif self.rvm?
        'Ringless Voicemail'
      elsif self.video?
        'Video Conversation'
      elsif self.facebook?
        'Facebook Messenger'
      elsif self.google?
        'Google Messages'
      elsif self.widget?
        'SiteChat Response'
      else
        'Unknown'
      end
    end

    def video?
      MSG_TYPES_VIDEO.include?(self.msg_type)
    end

    def voice?
      MSG_TYPES_VOICE.include?(self.msg_type)
    end

    def widget?
      MSG_TYPES_WIDGET.include?(self.msg_type)
    end

    private

    def after_create_commit_actions
      super

      self.contact.client.charge_for_action(key: 'text_message_credits', multiplier: [self.num_segments, 1].max, contact_id: self.contact_id, message_id: self.id) if self.error_code.to_i != 1_000_001 && MSG_TYPES_TEXT.include?(self.msg_type)

      post_to_searchlight
      post_to_servicetitan
    end

    def after_save_process
      if [4_700, 4_720, 21_211, 21_408, 21_614, 30_005, 30_006].include?(error_code.to_i)
        # 4700  - (Bandwidth) Invalid Service Type
        # 4720  - (Bandwidth) Carrier Rejected as Invalid Destination Address
        # 21211 - (Twilio) Invalid 'To' Phone Number
        # 24408 - (Twilio) Permission to send an SMS has not been enabled for the region indicated by the 'To' number
        # 21614 - (Twilio) 'To' number is not a valid mobile number
        # 30005 - (Twilio) Unknown destination handset
        # 30006 - (Twilio) Landline or unreachable carrier
        self.contact.ok2text_off
        self.contact.apply_undeliverable_tag
      elsif [4_470, 4_750, 4_770, 30_007].include?(error_code.to_i)
        # 4470  - (Bandwidth) Rejected Spam Detected
        # 4750  - (Bandwidth) Destination Rejected Message
        # 4770  - (Bandwidth) Carrier Rejected as SPAM
        # 30007 - (Twilio) message was filtered (blocked) by Twilio or by the carrier
        self.contact.apply_carrier_violation_tag
      end
    end

    def after_update_commit_actions
      super

      post_to_searchlight
    end

    def before_save_process
      return unless %w[failed failure undelivered].include?(status.downcase) && message.include?('/tl/')

      # Messages::Message is "undelivered" and includes a TrackableLink
      trackable_short_links = []

      # create an array of TrackableShortLinks
      message.enum_for(:scan, %r{(?=/tl/)}).map { Regexp.last_match.offset(0).first }.each do |i|
        trackable_short_links << message[i + 4, 6]
      end

      # interate through TrackableShortLinks
      trackable_short_links.each do |short_code|
        if (trackable_short_link = TrackableShortLink.find_by(short_code:))
          # delete the TrackableShortLink and replace short_code in Messages::Message
          trackable_short_link.destroy
          self.message = message.gsub(short_code, 'xxxxxx')
        end
      end
    end

    def post_to_searchlight
      Integrations::Searchlight::V1::PostMessageJob.perform_later(
        client_id:        self.contact.client_id,
        user_id:          self.user_id,
        contact_id:       self.contact_id,
        triggeraction_id: self.triggeraction_id,
        message:          self,
        action_at:        Time.current
      )
    end

    def post_to_servicetitan
      Integrations::Servicetitan::V2::SendMessageAsNote.perform_later(
        message_id: self.id,
        contact_id: self.contact_id,
        user_id:    self.contact.user_id
      )
    end
  end
end
