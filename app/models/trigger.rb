# frozen_string_literal: true

# app/models/trigger.rb
class Trigger < ApplicationRecord
  INCOMING_TEXT_MESSAGE_TYPES         = [100, 155].freeze
  INCOMING_TEXT_MESSAGE_KEYWORD_TYPES = [110].freeze
  FORWARD_TYPES                       = [115, 130, 132, 133, 134, 135, 136, 137, 138, 139, 140, 150, 152].freeze
  REVERSE_TYPES                       = [120, 125, 142, 143, 144, 145, 146, 147, 148, 149].freeze
  REPEATABLE_TYPES                    = [115, 130, 135, 140].freeze

  ALL_TYPES                           = (INCOMING_TEXT_MESSAGE_TYPES + INCOMING_TEXT_MESSAGE_KEYWORD_TYPES + FORWARD_TYPES + REVERSE_TYPES).freeze
  START_CAMPAIGN_TYPES                = (FORWARD_TYPES + REVERSE_TYPES - [150, 152]).freeze

  belongs_to :campaign

  has_many   :triggeractions, dependent: :destroy

  validates  :trigger_type,   presence: true

  serialize :data, coder: YAML, type: Hash

  after_initialize :apply_defaults, if: :new_record?

  # analyze a Trigger for errors
  # returns a hash of errors
  #   [
  #     {trigger_id: Integer, triggeraction_id: Integer},
  #     {trigger_id: Integer, triggeraction_id: Integer}
  #   ]
  # result = trigger.analyze!
  def analyze!
    response = []

    case trigger_type
    when 110
      response << { trigger_id: id, triggeraction_id: 0, description: "Keyword was NOT saved for #{data[:name]}." } if data.dig(:keyword).to_s.empty?
    when 130
      response << { trigger_id: id, triggeraction_id: 0, description: "Specific Date was NOT saved for #{data[:name]}." } if data.dig(:start_campaign_specific_date).to_s.empty?
    when 140, 145
      response << { trigger_id: id, triggeraction_id: 0, description: "Custom Field was NOT selected for #{data[:name]}." } if data.dig(:client_custom_field_id).to_s.empty?
    when 143
      response << { trigger_id: id, triggeraction_id: 0, description: "Job date was NOT selected for #{data[:name]}." } if data.dig(:client_custom_field_id).to_s.empty?
    when 144, 146
      response << { trigger_id: id, triggeraction_id: 0, description: "Estimate or Job date was NOT selected for #{data[:name]}." } if data.dig(:client_custom_field_id).to_s.empty?
    when 147
      response << { trigger_id: id, triggeraction_id: 0, description: "Estimate or Order date was NOT selected for #{data[:name]}." } if data.dig(:client_custom_field_id).to_s.empty?
    when 148
      response << { trigger_id: id, triggeraction_id: 0, description: "Estimate date was NOT selected for #{data[:name]}." } if data.dig(:client_custom_field_id).to_s.empty?
    when 149
      response << { trigger_id: id, triggeraction_id: 0, description: "Estimate or Work Order date was NOT selected for #{data[:name]}." } if data.dig(:client_custom_field_id).to_s.empty?
    when 120
      response << { trigger_id: id, triggeraction_id: 0, description: "Event Date was NOT saved for #{data[:name]}." } if data.dig(:target_time).to_s.empty?
    when 150, 152, 155
      response << { trigger_id: id, triggeraction_id: 0, description: "Active Times were NOT saved for #{data[:name]}." } if data.dig(:process_times_a).to_s.empty? || data.dig(:process_times_b).to_s.empty?
      response << { trigger_id: id, triggeraction_id: 0, description: "Active Days were NOT saved for #{data[:name]}." } unless data.dig(:process_sat) && data.dig(:process_sun) && data.dig(:process_mon) && data.dig(:process_tue) && data.dig(:process_wed) && data.dig(:process_thu) && data.dig(:process_fri)
    end

    response << { trigger_id: id, triggeraction_id: 0, description: "Actions have NOT been created for #{data[:name]}." } if triggeractions.empty?

    triggeractions.each do |triggeraction|
      response += triggeraction.analyze!
    end

    response
  end

  # copy a Trigger
  # trigger.copy( new_campaign_id: Integer )
  def copy(new_campaign_id:, **args)
    campaign_id_prefix = args.dig(:campaign_id_prefix).to_s

    return nil unless new_campaign_id.to_i.positive? && (new_campaign = Campaign.find_by(id: new_campaign_id.to_i))

    new_trigger = self.dup
    new_trigger.campaign_id = new_campaign.id
    new_trigger.step_numb   = self.step_numb

    return nil unless new_trigger.save

    self.triggeractions.each do |triggeraction|
      new_triggeraction = triggeraction.copy(new_trigger_id: new_trigger.id, campaign_id_prefix:)

      unless new_triggeraction
        new_trigger.destroy
        new_trigger = nil
        break
      end
    end

    new_trigger
  end

  # fire Trigger for Campaign
  # @trigger.fire(contact: Contact, contact_campaign: Contacts::Campaign, message: Messages::Message)
  def fire(contact:, contact_campaign:, message:, **args)
    JsonLog.info 'Trigger.fire', { contact:, contact_campaign:, message:, args: }
    target_time = args.dig(:target_time).respond_to?(:strftime) ? args[:target_time] : Time.current

    return unless contact.is_a?(Contact)

    start_time = self.start_time(contact_campaign:, target_time:)

    self.triggeractions.order(:sequence, :action_type).each do |ta|
      result = true

      case self.trigger_type
      when *INCOMING_TEXT_MESSAGE_TYPES
        # (100) start actions on incoming text message
        # (155) start actions on a new Contact from incoming text message
        result = ta.fire(contact:, contact_campaign:, start_time:, message:)
      when *INCOMING_TEXT_MESSAGE_KEYWORD_TYPES
        # text message with a keyword

        if self.data&.include?(:keyword) && (
            ((self.data&.dig(:keyword_location).to_i == 1 || self.data&.exclude?(:keyword_location)) && message.message.to_s.strip.casecmp?(self.data[:keyword].to_s.strip)) ||
            (self.data&.dig(:keyword_location).to_i == 2 && message.message.to_s.strip.downcase[0, self.data[:keyword].to_s.strip.length] == self.data[:keyword].to_s.strip.downcase) ||
            (self.data&.dig(:keyword_location).to_i == 3 && message.message.to_s.strip.downcase.include?(self.data[:keyword].to_s.strip.downcase))
          )
          # response matches keyword

          contact_campaign ||= contact.contact_campaigns.create(campaign_id: self.campaign_id)

          result = ta.fire(contact:, contact_campaign:, start_time:)
        end
      when *FORWARD_TYPES
        # (115) start actions immediately (no trigger)
        # (130) start actions on a specific date
        # (132) start actions on a Contacts::Invoice due_date (Jobber)
        # (133) start actions on a Contacts::Estimate or Contacts::Job date (Jobber)
        # (134) start actions on a Contacts::Estimate or Contacts::Job date (ServiceTitan)
        # (135) start actions on a birthdate
        # (136) start actions on a Contacts::Estimate or Contacts::Job date (JobNimbus)
        # (137) start actions on a Contacts::Estimate or Contacts::Job date (Housecall Pro)
        # (138) start actions on a Contacts::Estimate or Contacts::Job date (ResponsiBid)
        # (139) start actions on a Contacts::Estimate or Contacts::Job date (ServiceMonster)
        # (140) start actions on a ContactCustomField date
        # (150) start actions on an incoming voice call
        # (152) start actions after a missed incoming voice call
        result = ta.fire(contact:, contact_campaign:, start_time:)
      when *REVERSE_TYPES
        # reverse Triggers
        # (120) start actions immediately based on entered date
        # (125) start actions immediately based on dynamic date
        # (142) start actions leading up to a Contacts::Invoice due_date (Jobber)
        # (143) start actions leading up to a Contacts::Estimate or Contacts::Job date (Jobber)
        # (144) start actions leading up to a Contacts::Estimate or Contacts::Job date (ServiceTitan)
        # (145) start actions leading up to a ContactCustomField date
        # (146) start actions leading up to a Contacts::Estimate or Contacts::Job date (Housecall Pro)
        # (147) start actions leading up to a Contacts::Estimate or Contacts::Job date (ServiceMonster)
        # (148) start actions leading up to a Contacts::Estimate date (ResponsiBid)
        # (149) start actions leading up to a Contacts::Estimate date (JobNimbus)
        result = ta.fire(contact:, contact_campaign:, start_time:, reverse: true)
      end

      break unless result
    end
  end

  # return true/false if Trigger is repeatable
  # trigger.repeatable?
  def repeatable?
    REPEATABLE_TYPES.include?(self.trigger_type)
  end

  # calculate the start time for this Trigger
  # trigger.start_time
  def start_time(contact_campaign:, target_time:)
    contact_campaign = nil unless contact_campaign.is_a?(Contacts::Campaign)
    target_time      = Time.current unless target_time.respond_to?(:strftime)

    case self.trigger_type
    when 120
      # event Trigger with target time / set target time
      start_time = self.data.dig(:target_time) || Time.current
    when 100, 125, 150, 152, 155
      # (100) start actions on incoming text message
      # (125) appointment Trigger with dynamic target time / set target time using target_time
      # (150) start actions on an incoming voice call
      # (152) start actions after a missed incoming voice call
      # (155) start actions on a new Contact from incoming text message
      start_time = target_time
    when 130
      # start actions on a specific date
      start_time = if self.data.dig(:start_campaign_specific_date).to_s.present?
                     Chronic.parse(self.data[:start_campaign_specific_date])
                   else
                     1.week.ago
                   end
    when 135
      # start actions on a birthdate

      if contact_campaign&.contact&.birthdate
        # change birthdate year to the current year
        start_time = contact_campaign.contact.birthdate.change(year: Time.current.year)

        # bump up a year if not in the future
        start_time += 1.year unless start_time.future?

        # set time to 8am in Client time zone
        Time.zone = contact_campaign.contact.client.time_zone
        Chronic.time_class = Time.zone
        start_time = Chronic.parse(start_time.strftime('%m/%d/%Y')).change(hour: 8, min: 0, sec: 0).utc
      else
        start_time = 1.week.ago
      end
    when 132, 133, 134, 136, 137, 138, 139
      # start actions on a Contacts::Invoice due_date (Jobber, JobNimbus, ServiceMonster or ServiceTitan)
      # start actions on a Contacts::Estimate or Contacts::Job date (Housecall Pro, Jobber, JobNimbus, ServiceMonster or ServiceTitan)
      # start actions on a Contacts::Estimate date (ResponsiBid)

      start_time = if self.data.dig(:client_custom_field_id).to_s[0, 9] == 'estimate_' && contact_campaign.data.dig(:contact_estimate_id).present? &&
                      (contact_estimate = contact_campaign.contact.estimates.find_by(id: contact_campaign.data[:contact_estimate_id]))
                     contact_estimate.send(self.data.dig(:client_custom_field_id).to_s.delete_prefix('estimate_'))
                   elsif self.data.dig(:client_custom_field_id).to_s[0, 8] == 'invoice_' && contact_campaign.data.dig(:contact_invoice_id).present? &&
                         (contact_invoice = contact_campaign.contact.invoices.find_by(id: contact_campaign.data[:contact_invoice_id])) &&
                         contact_invoice.due_date.present?

                     contact_invoice.due_date
                   elsif self.data.dig(:client_custom_field_id).to_s[0, 4] == 'job_' && contact_campaign.data.dig(:contact_job_id).present? &&
                         (contact_job = contact_campaign.contact.jobs.find_by(id: contact_campaign.data[:contact_job_id]))
                     contact_job.send(self.data.dig(:client_custom_field_id).to_s.delete_prefix('job_'))
                   elsif self.data.dig(:client_custom_field_id).to_s[0, 6] == 'visit_' && contact_campaign.data.dig(:contact_visit_id).present? &&
                         (contact_visit = contact_campaign.contact.visits.find_by(id: contact_campaign.data[:contact_visit_id]))
                     contact_visit.send(self.data.dig(:client_custom_field_id).to_s.delete_prefix('visit_'))
                   else
                     Time.current
                   end
    when 140
      # start actions on a ContactCustomField date

      if contact_campaign && self.data.dig(:client_custom_field_id).to_i.positive?
        contact_custom_field = contact_campaign.contact.contact_custom_fields.find_by(client_custom_field_id: self.data[:client_custom_field_id].to_i)

        start_time = if contact_custom_field && contact_custom_field.client_custom_field.var_type == 'date' && contact_custom_field.var_value.present?
                       Chronic.parse(contact_custom_field.var_value)
                     else
                       1.week.ago
                     end
      else
        start_time = 1.week.ago
      end
    when 145
      # (reverse trigger) start actions leading up to a ContactCustomField date
      start_time = 1.week.ago

      if contact_campaign && self.data.dig(:client_custom_field_id).to_i.positive? &&
         (contact_custom_field = contact_campaign.contact.contact_custom_fields.find_by(client_custom_field_id: self.data[:client_custom_field_id].to_i)) &&
         contact_custom_field.client_custom_field.var_type == 'date' && contact_custom_field.var_value.present?

        start_time = Chronic.parse(contact_custom_field.var_value)
      end
    when 142, 143, 144, 146, 147, 148, 149
      # (reverse trigger) start actions leading up to a Contacts::Invoice die_date (Jobber)
      # (reverse trigger) start actions leading up to a Contacts::Estimate or Contacts::Job date (Housecall Pro, Jobber, JobNimbus, ServiceMonster or ServiceTitan)
      # (reverse trigger) start actions leading up to a Contacts::Estimate date (ResponsiBid)
      start_time = 1.week.ago

      if contact_campaign

        if self.data.dig(:client_custom_field_id).to_s[0, 9] == 'estimate_' && contact_campaign.data.dig(:contact_estimate_id).to_i.positive? &&
           (contact_estimate = contact_campaign.contact.estimates.find_by(id: contact_campaign.data.dig(:contact_estimate_id).to_i)) &&
           contact_estimate.send(self.data.dig(:client_custom_field_id).to_s.delete_prefix('estimate_')).present?

          start_time = contact_estimate.send(self.data.dig(:client_custom_field_id).to_s.delete_prefix('estimate_'))
        elsif self.data.dig(:client_custom_field_id).to_s[0, 8] == 'invoice_' && contact_campaign.data.dig(:contact_invoice_id).to_i.positive? &&
              (contact_invoice = contact_campaign.contact.invoices.find_by(id: contact_campaign.data.dig(:contact_invoice_id).to_i)) &&
              contact_invoice.due_date.present?

          start_time = contact_invoice.due_date
        elsif self.data.dig(:client_custom_field_id).to_s[0, 4] == 'job_' && contact_campaign.data.dig(:contact_job_id).to_i.positive? &&
              (contact_job = contact_campaign.contact.jobs.find_by(id: contact_campaign.data.dig(:contact_job_id).to_i)) &&
              contact_job.send(self.data.dig(:client_custom_field_id).to_s.delete_prefix('job_')).present?

          start_time = contact_job.send(self.data.dig(:client_custom_field_id).to_s.delete_prefix('job_'))
        elsif self.data.dig(:client_custom_field_id).to_s[0, 6] == 'visit_' && contact_campaign.data.dig(:contact_visit_id).to_i.positive? &&
              (contact_visit = contact_campaign.contact.visits.find_by(id: contact_campaign.data.dig(:contact_visit_id).to_i)) &&
              contact_visit.send(self.data.dig(:client_custom_field_id).to_s.delete_prefix('visit_')).present?

          start_time = contact_visit.send(self.data.dig(:client_custom_field_id).to_s.delete_prefix('visit_'))
        end
      end
    else
      # set time when Campaign started (add 10 seconds so as not to jump to future date if repeatable)
      start_time = (contact_campaign ? contact_campaign.created_at : Time.current) + 10.seconds
    end

    return start_time if start_time.nil?

    if start_time < Time.current && self.repeatable? && self.data.dig(:repeat).to_i == 1 && self.data.dig(:repeat_interval).to_i.positive? && self.data.dig(:repeat_period).to_s.present?

      while start_time < Time.current
        # convert utc to local before adding repeat to allow for time changes where necessary
        start_time = (start_time.in_time_zone(self.campaign.client.time_zone) + self.data[:repeat_interval].to_i.send(self.data[:repeat_period].to_s)).utc
      end
    end

    start_time.in_time_zone(self.campaign.client.time_zone)
  end

  # return a Trigger name
  # trigger.type_name
  def type_name
    if (response = self.types_expanded(step_numb: self.step_numb).dig(self.trigger_type))
      self.trigger_type == 100 ? response : "Start a #{response}"
    else
      'Unknown Trigger Type'
    end
  end

  def types_abbreviated
    self.types_expanded.transform_values { |v| v[v.index('(').to_i + 1, v.index(')').to_i - v.index('(').to_i - 1].to_s }.compact_blank
  end

  # return a hash of triggers available
  # trigger.types_expanded(step_numb: Integer)
  def types_expanded(args = {})
    step_numb     = args.dig(:step_numb).to_i
    trigger_types = {}

    trigger_types[100] = 'Text Message Received' if step_numb != 0

    if step_numb <= 1
      trigger_types.merge!({
                             110 => 'Keyword Conversation',
                             115 => 'Drip Campaign (Immediately)',
                             130 => 'Drip Campaign (on a Specific Date)',
                             135 => 'Drip Campaign (on a Birthdate)',
                             140 => 'Drip Campaign (on a Custom Field Date)',
                             150 => 'Drip Campaign (on an Incoming Phone Call)',
                             152 => 'Drip Campaign (on a Missed Incoming Phone Call)',
                             155 => 'Drip Campaign (on an Incoming Text Message)'
                           })

      trigger_types[137] = 'Drip Campaign (on a Housecall Pro Estimate or Job Date)' if self.campaign&.client&.integrations_allowed&.intersect?(%w[housecall housecallpro])
      trigger_types[132] = 'Drip Campaign (on a Jobber Invoice Due Date)' if self.campaign&.client&.integrations_allowed&.include?('jobber')
      trigger_types[133] = 'Drip Campaign (on a Jobber Job or Visit Date)' if self.campaign&.client&.integrations_allowed&.include?('jobber')
      trigger_types[136] = 'Drip Campaign (on a JobNimbus Estimate or Work Order Date)' if self.campaign&.client&.integrations_allowed&.include?('jobnimbus')
      trigger_types[138] = 'Drip Campaign (on a ResponsiBid Estimate Date)' if self.campaign&.client&.integrations_allowed&.include?('responsibid')
      trigger_types[139] = 'Drip Campaign (on a ServiceMonster Estimate or Order Date)' if self.campaign&.client&.integrations_allowed&.include?('servicemonster')
      trigger_types[134] = 'Drip Campaign (on a ServiceTitan Estimate or Job Date)' if self.campaign&.client&.integrations_allowed&.include?('servicetitan')
      trigger_types[145] = 'Drip Campaign (Leading up to a Custom Field Date)'
      trigger_types[146] = 'Drip Campaign (Leading up to a Housecall Pro Estimate or Job Date)' if self.campaign&.client&.integrations_allowed&.intersect?(%w[housecall housecallpro])
      trigger_types[142] = 'Drip Campaign (Leading up to a Jobber Invoice Due Date)' if self.campaign&.client&.integrations_allowed&.include?('jobber')
      trigger_types[143] = 'Drip Campaign (Leading up to a Jobber Job or Visit Date)' if self.campaign&.client&.integrations_allowed&.include?('jobber')
      trigger_types[149] = 'Drip Campaign (Leading up to a JobNimbus Estimate or Work Order Date)' if self.campaign&.client&.integrations_allowed&.include?('jobber')
      trigger_types[148] = 'Drip Campaign (Leading up to a ResponsiBid Estimate Date)' if self.campaign&.client&.integrations_allowed&.include?('responsibid')
      trigger_types[147] = 'Drip Campaign (Leading up to a ServiceMonster Estimate or Order Date)' if self.campaign&.client&.integrations_allowed&.include?('servicemonster')
      trigger_types[144] = 'Drip Campaign (Leading up to a ServiceTitan Estimate or Job Date)' if self.campaign&.client&.integrations_allowed&.include?('servicetitan')

      trigger_types[120] = 'Drip Campaign (Leading up to an Event)'
      trigger_types[125] = 'Drip Campaign (Leading up to an Appointment)'
      # trigger_types[155] = "Smart Conversation"
    end

    trigger_types
  end

  private

  def after_create_commit_actions
    super

    after_commit_process
  end

  def after_destroy_commit_actions
    super

    after_commit_process
  end

  def after_update_commit_actions
    super

    after_commit_process
  end

  def after_commit_process
    return unless !self.destroyed? && (campaign = Campaign.find_by(id: self.campaign_id))

    campaign.update(analyzed: campaign.analyze!.empty?)
  end

  def apply_defaults
    self.step_numb    = (self.campaign&.triggers&.maximum('step_numb') || 0) + 1
    self.trigger_type = (self.step_numb == 1 ? 115 : 100)
    self.name         = self.type_name
    self.data         = {}
    self.data[:name]  = self.type_name
  end
end
