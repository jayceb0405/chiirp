# frozen_string_literal: true

class Aiagent < ApplicationRecord
  AIAGENT_TYPES = %w[gpt-4o-mini gpt-3.5-turbo].freeze
  PRE_PROMPTS = {
    booking_st:     nil,
    conversation:   nil,
    extract_data:   <<~PROMPT.strip,
      Your name is "AI Agent".
      You need to get the information included in the extract_data function. Do not make this information up.
      If the contact asks for a customer service represenatative, a human, or a phone call then call the get_help function.
    PROMPT
    quick_response: nil
  }.with_indifferent_access.freeze
  POST_PROMPTS = {
    booking_st:     <<~PROMPT.strip,
      You are a customer service representantive. Your job is to book an appointment with a customer.
      In order to book the appointment you need to use the available_appointments function to find available time slots. Each time you call this function ask the customer if any of those time slots will work for them. If they do not, then you can call the function again to get more time slots to check.
      If the customer offers a time slot that is not on the list, you can also call the function to see if that time slot will work.

      Once you have a time slot that works for the customer and was also available in the available_appointments function, then you need to find out the customer's address.
      You then need to find out the customer's address. You can call the existing_addresses function to get a list of known addresses for the customer. If any are available then offer those addresses to the customer. If the customer indicates that none of those are the correct address, then you will need to ask the customer for their address, city, state, and zipcode.

      Once the customer has a time slot selected and you know the customer's confirmed address, you need to call the book_appointment function to book the appointment.
    PROMPT
    conversation:   nil,
    extract_data:   <<~PROMPT.strip,
      You can complete the request by calling the extract_data function with the information you collected from the client.
    PROMPT
    quick_response: nil
  }.with_indifferent_access.freeze
  SEGMENT_LENGTH = BigDecimal('500.0')

  belongs_to :client

  belongs_to :campaign, optional: true
  belongs_to :group,    optional: true
  belongs_to :stage,    optional: true
  belongs_to :tag,      optional: true

  belongs_to :help_campaign, optional: true, class_name: 'Campaign'
  belongs_to :help_group,    optional: true, class_name: 'Group'
  belongs_to :help_stage,    optional: true, class_name: 'Stage'
  belongs_to :help_tag,      optional: true, class_name: 'Tag'

  belongs_to :session_length_campaign, optional: true, class_name: 'Campaign'
  belongs_to :session_length_group,    optional: true, class_name: 'Group'
  belongs_to :session_length_stage,    optional: true, class_name: 'Stage'
  belongs_to :session_length_tag,      optional: true, class_name: 'Tag'

  has_many :aiagent_sessions, dependent: :nullify, class_name: 'Aiagent::Session'
  has_many :aiagent_test_sessions, -> { merge(Aiagent::Session.test_session) }, dependent: :nullify, class_name: 'Aiagent::TestSession', inverse_of: :aiagent
  has_many :aiagent_sms_sessions, -> { merge(Aiagent::Session.sms_session) }, dependent: :nullify, class_name: 'Aiagent::SmsSession', inverse_of: :aiagent
  has_many :aiagent_messages, through: :aiagent_sessions
  has_many :contacts, through: :sessions

  validates :share_code, uniqueness: true
  validates :aiagent_type, inclusion: { in: AIAGENT_TYPES, message: "%{value} must be one of #{AIAGENT_TYPES.join(', ')}" }
  validate :action_is_allowed

  before_save    :ensure_share_code
  after_destroy  :unlink_triggeraction

  store_accessor :data, :custom_fields, :business_unit_id, :job_type_id, :st_campaign_id, :tag_type_names, :technician_ids, :description, :client_custom_fields, :lookback_days

  scope :normal, -> { where.not(action: 'quick_response') }
  scope :quick_responses, -> { where(action: 'quick_response') }

  def copy(new_client_id:)
    new_aiagent = self.dup
    new_aiagent.client_id  = new_client_id
    new_aiagent.share_code = nil
    new_aiagent.name       = new_name

    new_aiagent.save ? new_aiagent : nil
  end

  def credits_per_segment
    self.client.aiagent_message_credits
  end

  def default_prompt_pre
    PRE_PROMPTS[self.action]
  end

  def default_prompt_post
    POST_PROMPTS[self.action]
  end

  def action_types
    out = {}

    out[:conversation]   = 'Carry on a Conversation'
    out[:extract_data]   = 'Collect Information'
    out[:booking_st]     = 'ServiceTitan Booking' if self.client&.integrations_allowed&.include?('servicetitan') && self.service_titan_integration && Integration::Servicetitan::V2::Base.new(self.service_titan_integration)&.valid_credentials?
    out[:quick_response] = 'Quick Response'

    out.with_indifferent_access
  end

  def respond(conversation)
    self.aa_client(conversation).chat
  end

  def service_titan_integration
    cai = self.client&.client_api_integrations&.find_by(target: 'servicetitan', name: '')
    cai&.credentials.present? ? cai : nil
  end

  def system_prompt_segments
    (self.system_prompt.length / SEGMENT_LENGTH).ceil
  end

  def to_openai
    {
      role:    :system,
      content: [self.default_prompt_pre, self.system_prompt.strip, self.default_prompt_post].join("\n")
    }
  end

  private

  def aa_client(conversation)
    AiAgent.new conversation, model: self.aiagent_type, functions:
  end

  def action_is_allowed
    errors.add(:action, "action must be one of #{self.action_types.keys.join(', ')}") unless self.action_types.key?(self.action)
  end

  def after_update_commit_actions
    super

    self.aiagent_test_sessions.map(&:stop!)
  end

  def ensure_share_code
    self.share_code = new_share_code if self.share_code.blank?
  end

  def functions
    return [] if self.action == 'quick_response'

    output = [function_get_help]
    output << function_extract_data if self.action == 'extract_data'
    output << function_end_conversation if self.action == 'conversation'
    if self.action == 'booking_st'
      output << function_available_appointments
      output << function_existing_addresses
      output << function_book_appointment
    end
    output
  end

  def function_available_appointments
    {
      name:        'available_appointments',
      description: 'Get a list of dates and times when an appointment could be scheduled.',
      parameters:  {
        type:       'object',
        properties: {
          days_of_month: {
            description: 'Days of the month to schedule an appointment',
            type:        'array',
            items:       {
              type: 'number'
            }
          },
          days_of_week:  {
            description: 'Days of the week to schedule an appointment',
            type:        'array',
            items:       {
              type: 'number'
            }
          },
          hours_of_day:  {
            description: 'Hours of the day to schedule an appointment',
            type:        'array',
            items:       {
              type: 'number'
            }
          }
        },
        required:   []
      }
    }
  end

  def function_existing_addresses
    {
      name:        'existing_addresses',
      description: 'Get a list of existing customer addresses.',
      parameters:  {
        type:       'object',
        properties: {},
        required:   []
      }
    }
  end

  def function_book_appointment
    {
      name:        'book_appointment',
      description: 'Book an appointment.',
      parameters:  {
        type:       'object',
        properties: {
          start_time:    {
            description: 'Start date and time of the appointment',
            type:        'string'
          },
          end_time:      {
            description: 'End date and time of the appointment',
            type:        'string'
          },
          technician_id: {
            description: 'Technician ID from the time slot the customer chooses',
            type:        'string'
          },
          address1:      {
            description: 'Customer address line 1',
            type:        'string'
          },
          address2:      {
            description: 'Customer address line 2',
            type:        'string'
          },
          city:          {
            description: 'Customer city',
            type:        'string'
          },
          state:         {
            description: 'Customer state',
            type:        'string'
          },
          zipcode:       {
            description: 'Customer zipcode',
            type:        'string'
          },
          location_id:   {
            description: 'Location ID from the existing address, if the customer chooses an existing address',
            type:        'string'
          }
        },
        required:   %w[start_time end_time technician_id address1]
      }
    }
  end

  def function_end_conversation
    {
      name:        'end_conversation',
      description: 'End the conversation.',
      parameters:  {
        type:       'object',
        properties: {},
        required:   []
      }
    }
  end

  def function_extract_data
    output = {
      name:        'extract_data',
      description: 'Extract data about a customer',
      parameters:  {
        type:       'object',
        properties: {},
        required:   []
      }
    }

    custom_fields.sort_by { |_, metadata| metadata['order'].to_i }.each do |name, metadata|
      next unless metadata['show'].to_bool

      output[:parameters][:properties][name] = {
        type: 'string'
        # description: ''
      }

      output[:parameters][:required] << name if metadata['required'].to_bool
    end

    output
  end

  def function_get_help
    {
      name:        'get_help',
      description: 'Ask a customer service representative to help.',
      parameters:  {
        type:       'object',
        properties: {},
        required:   []
      }
    }
  end

  def new_name
    "Copy of #{name}"
  end

  def new_share_code
    share_code = RandomCode.new.create(20)
    share_code = RandomCode.new.create(20) while Aiagent.find_by(share_code:)

    share_code
  end

  def unlink_triggeraction
    Triggeraction.where(action_type: [250, 450]).where("#{Triggeraction.table_name}.data @> ?", { agent_id: id }.to_json).find_each do |triggeraction|
      triggeraction.update! agent_id: nil
    end
  end
end
