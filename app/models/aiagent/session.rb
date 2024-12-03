# frozen_string_literal: true

# app/models/aiagent/session.rb
class Aiagent
  class Session < ApplicationRecord
    belongs_to :contact, optional: true
    belongs_to :aiagent, optional: true

    enum :ended_reason, %i[completed stopped over_limit help max_messages timeout]

    has_one :client, through: :aiagent
    has_many :messages, -> { order(:created_at) }, dependent: :nullify, class_name: '::Messages::Message', foreign_key: :aiagent_session_id, inverse_of: :aiagent_session
    has_many :aiagent_messages, -> { order(:created_at) }, dependent: :destroy, class_name: 'Aiagent::Message', foreign_key: :aiagent_session_id, inverse_of: :aiagent_session

    scope :active, -> { where.not(started_at: nil).where(ended_at: nil).where.not(aiagent_id: nil) }
    scope :inactive, -> { where.not(started_at: nil).where.not(ended_at: nil) }
    singleton_class.send(:alias_method, :ended, :inactive)
    scope :no_contact, -> { where(contact_id: nil) }
    scope :test_session, -> { where(type: 'Aiagent::TestSession') }
    scope :sms_session, -> { where(type: 'Aiagent::SmsSession') }

    validates :aiagent_type, :ended_reason, presence: true

    before_validation :ensure_aiagent_type
    before_validation :ensure_type
    after_validation :set_nil
    before_create :ensure_started_at
    after_create :ensure_system_message
    after_create :schedule_session_end, if: :timed?

    def ended?
      self.ended_at.present?
    end

    def initial_prompt_for_contact
      self.aiagent.initial_prompt
    end

    # find the last interaction with this session
    def last_interaction_at
      [self.aiagent_messages.last&.created_at, self.messages.last&.created_at, self.ended_at].compact_blank.max
    end

    def last_phone_used
      self.messages.where(msg_type: 'textin').last&.from_phone
    end

    def respond!
      # if we have reached the limit of this ai agent, then send error prompt
      return end_with_max_messages if self.aiagent_messages.from_assistant.count >= self.aiagent.max_messages

      # recharge credits if necessary
      self.client.recharge_credits

      # check available credits
      return unless (self.client.current_balance.to_d / 100) >= self.client.aiagent_message_credits.to_d

      res = self.aiagent.respond(conversation)

      # bill client
      self.client.charge_for_action(key: 'aiagent_message_credits', multiplier: self.aiagent.system_prompt_segments, aiagent_id: self.aiagent_id, aiagent_session_id: self.id, contact_id: self.contact_id)

      return end_with_max_messages(:over_limit) if res.dig(:choices, 0, :finish_reason) == 'length'

      return function_call(res) if res.dig(:choices, 0, :finish_reason) == 'function_call'

      return if res.dig(:choices, 0, :message, :content).blank?

      content = res.dig(:choices, 0, :message, :content)

      respond_with(content)

      self.aiagent_messages.create role: res.dig(:choices, 0, :message, :role), content:, raw_post: res
    end

    def respond_with_message!(message)
      # save new message from user
      self.aiagent_messages.create role: :user, content: message.message

      # associate message to session
      message.update aiagent_session_id: self.id

      respond!
    end

    def timed?
      self.aiagent.session_length.positive?
    end

    def stop!(ended_reason = :completed)
      self.update(ended_at: Time.current, ended_reason:) unless self.ended_at
    end

    def session_timeout!
      return unless self.stop!(:timeout)

      conversation_ended_with_session_length
    end

    private

    def client_api_integration
      self.aiagent.client.client_api_integrations.find_by(target: 'servicetitan', name: '')
    end

    def conversation
      [self.aiagent.to_openai] + self.aiagent_messages.map(&:to_openai)
    end

    def end_with_max_messages(reason = :max_messages)
      self.stop!(reason)

      content = self.aiagent.max_messages_prompt

      respond_with(content) if content.present?

      conversation_ended_with_session_length

      self.aiagent_messages.create role: :assistant, content:
    end

    def ensure_aiagent_type
      self.aiagent_type = aiagent.aiagent_type unless self.aiagent_type
    end

    def ensure_started_at
      self.started_at = Time.current unless self.started_at
    end

    def ensure_system_message
      self.aiagent_messages.create(self.aiagent.to_openai) unless self.aiagent_messages.system.any?
    end

    def ensure_type
      self.type = 'Aiagent::SmsSession' unless self.type
    end

    def function_call(last_res)
      content = last_res.dig(:choices, 0, :message, :content).presence || self.aiagent.ending_prompt.presence
      self.aiagent_messages.create role: last_res.dig(:choices, 0, :message, :role), content:, function_name: last_res.dig(:choices, 0, :message, :function_call, :name), function_params: last_res.dig(:choices, 0, :message, :function_call, :arguments), raw_post: last_res

      case last_res.dig(:choices, 0, :message, :function_call, :name)
      when 'available_appointments'
        # find available appointments
        raise 'AI attempted to run available_appointments function, but there is no ServiceTitan integration available.' unless client_api_integration

        arguments = JSON.parse(last_res.dig(:choices, 0, :message, :function_call, :arguments))

        time_blocks = st_client.multi_technician_availability(business_unit_id: self.aiagent.business_unit_id, job_type_id: self.aiagent.job_type_id, ext_tech_ids: self.aiagent.technician_ids, start_time: Time.current, days_of_month: arguments['days_of_month'], days_of_week: arguments['days_of_week'], hours_of_day: arguments['hours_of_day'])

        if st_client.success? && time_blocks.any?
          content = <<~CONTENT
            We have the following available appointments. Never tell the customer the technician ID.
            #{time_blocks.first(10).sample(3).sort_by { |a| a[:from] }.map { |time_block| "Between #{time_block[:from].strftime('%-m/%e at %l:%M%P')} and #{time_block[:to].strftime('%l:%M%P')} with #{time_block[:name]}. This appointment is with technician id: #{time_block[:ext_tech_id]}" }}
          CONTENT

          # create a new message with this functions reply
          self.aiagent_messages.create role: :function, content:, function_name: last_res.dig(:choices, 0, :message, :function_call, :name)

          # call openai with the available appointments
          self.respond!
        else
          # end the conversation if there are no available time slots
          self.stop!(:help)

          conversation_ended_with_help
        end
      when 'book_appointment'
        # book the appointment and end the session
        self.stop!

        arguments = JSON.parse(last_res.dig(:choices, 0, :message, :function_call, :arguments)).with_indifferent_access

        # save new contact/customer in ST if needed
        customer_id, location_id = st_customer_data(arguments)

        # book appointment in ST
        st_book_appointment(
          customer_id:,
          end_time:      Chronic.parse(arguments['end_time']),
          location_id:,
          start_time:    Chronic.parse(arguments['start_time']),
          technician_id: arguments['technician_id']
        )

        conversation_ended_with_function
      when 'existing_addresses'
        # find existing location/address data from ST

        # testing data
        # addresses = ['Main st', 'Baseball Ln', 'S Park Drive', 'Newberry Park', 'Theodore Ln', 'Technology Dr']
        # content = 'The customer has the following existing addresses:'
        # content += addresses.sample(3).map { |address| "#{1.upto(2_000).to_a.sample} #{address}" }.join("\n")

        st_client.locations(customer_id: self.contact.ext_references.find_by(target: 'servicetitan')&.ext_id)

        servicetitan_locations = if st_client.success?
                                   st_client.result.map { |lo| "#{lo[:address][:street]} with location ID: #{lo[:id]}" }
                                 else
                                   []
                                 end

        if servicetitan_locations.any?
          content = 'The customer has the following existing addresses. Never tell the customer the location id. If the customer tells you that one of the addresses is their address. Then save that location ID and use that in the book_appointment function.'
          content += servicetitan_locations.first(3).join("\n")
        else
          content = 'The customer has no existing addresses. You will need to ask the customer for their address.'
        end

        # create a new message with this functions reply
        self.aiagent_messages.create role: :function, content:, function_name: last_res.dig(:choices, 0, :message, :function_call, :name)

        # call openai with the available appointments
        self.respond!
      when 'extract_data'
        self.stop!

        save_extract_data(JSON.parse(last_res.dig(:choices, 0, :message, :function_call, :arguments)).with_indifferent_access) if last_res.dig(:choices, 0, :message, :function_call, :arguments).present?

        respond_with(content) if content.present?
        conversation_ended_with_function
      when 'end_conversation'
        self.stop!

        respond_with(content) if content.present?
        conversation_ended_with_function
      when 'get_help'
        self.stop!(:help)

        respond_with(content) if content.present?
        conversation_ended_with_help
      end
    end

    def set_nil
      self.from_phone = nil if self.from_phone.blank?
    end

    def schedule_session_end
      self.delay(
        run_at:              self.aiagent.session_length.hours.from_now,
        priority:            DelayedJob.job_priority('stop_aiagent_session'),
        queue:               DelayedJob.job_queue('stop_aiagent_session'),
        process:             'stop_aiagent_session',
        contact_id:          self.contact_id,
        user_id:             0,
        triggeraction_id:    0,
        contact_campaign_id: 0,
        data:                { aiagent_session_id: self.id, aiagent_id: self.aiagent.id }
      ).session_timeout!
    end

    def st_client
      unless defined?(@st_model)
        @st_model = Integration::Servicetitan::V2::Base.new(client_api_integration)
        @st_model.valid_credentials?
      end

      @st_client ||= Integrations::ServiceTitan::Base.new(client_api_integration.credentials)
    end

    def conversation_ended_with_function; end
    def conversation_ended_with_help; end
    def conversation_ended_with_session_length; end

    def save_extract_data(args); end
    def respond_with(content); end

    # book an appointment with ServiceTitan
    # paramaters:
    #   (req) start_time String
    #   (req) end_time String
    #   (req) location_id String
    #   (req) technician_id String
    #   (req) customer_id String
    def st_book_appointment(params = {}); end

    # save customer data and get customer_id and location_id in return
    # paramaters:
    #   (req) address1 String
    #   (req) address2 String
    #   (req) city String
    #   (req) state String
    #   (req) zipcode String
    def st_customer_data(params = {})
      [0, params[:location_id]]
    end
  end
end
