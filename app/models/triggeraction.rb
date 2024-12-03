# frozen_string_literal: true

# app/models/triggeraction.rb
class Triggeraction < ApplicationRecord
  class TriggeractionError < StandardError; end

  AIAGENT_TYPES      = [250, 450].freeze
  CALL_TYPES         = [750].freeze
  CAMPAIGN_TYPES     = [200, 400].freeze
  CLIENT_TYPES       = [800, 801].freeze
  CUSTOM_FIELD_TYPES = [605, 610].freeze
  EMAIL_TYPES        = [170, 171].freeze
  GROUP_TYPES        = [350, 355].freeze
  INTEGRATION_TYPES  = [901].freeze
  LEAD_TYPES         = [360].freeze
  NOTE_TYPES         = [615].freeze
  OK2EMAIL_TYPES     = [501, 506].freeze
  OK2TEXT_TYPES      = [500, 505].freeze
  PARSE_TYPES        = [600].freeze
  RVM_TYPES          = [150].freeze
  SLACK_TYPES        = [180, 181, 182].freeze
  STAGE_TYPES        = [340, 345].freeze
  TAG_TYPES          = [300, 305].freeze
  TASK_TYPES         = [700].freeze
  TEXT_TYPES         = [100].freeze
  USER_TYPES         = [510].freeze

  ALL_TYPES          = (AIAGENT_TYPES + CALL_TYPES + CAMPAIGN_TYPES + CLIENT_TYPES + CUSTOM_FIELD_TYPES + EMAIL_TYPES + GROUP_TYPES + INTEGRATION_TYPES + LEAD_TYPES + NOTE_TYPES + OK2EMAIL_TYPES + OK2TEXT_TYPES + PARSE_TYPES + RVM_TYPES + SLACK_TYPES + STAGE_TYPES + TAG_TYPES + TASK_TYPES + TEXT_TYPES + USER_TYPES).freeze
  SCHEDULED_TYPES    = (AIAGENT_TYPES + CALL_TYPES + CAMPAIGN_TYPES + CUSTOM_FIELD_TYPES + EMAIL_TYPES + GROUP_TYPES + INTEGRATION_TYPES + LEAD_TYPES + NOTE_TYPES + OK2EMAIL_TYPES + OK2TEXT_TYPES + RVM_TYPES + SLACK_TYPES + STAGE_TYPES + TAG_TYPES + TASK_TYPES + TEXT_TYPES + USER_TYPES - [450, 500, 501, 510]).freeze

  belongs_to :trigger

  has_many   :delayed_jobs,                    dependent: :delete_all
  has_many   :contact_campaign_triggeractions, dependent: :delete_all, class_name: '::Contacts::Campaigns::Triggeraction'
  has_many   :messages,                        dependent: :nullify,    class_name: '::Messages::Message'

  has_one    :campaign, through: :trigger

  validates :action_type, presence: true

  store_accessor :data, :delay_months, :delay_days, :delay_hours, :delay_minutes, :safe_start, :safe_end,
                 :safe_sun, :safe_mon, :safe_tue, :safe_wed, :safe_thu, :safe_fri, :safe_sat,
                 :ok2skip,
                 # (100) a send text message
                 :text_message, :from_phone, :send_to, :last_used_from_phone, :attachments,
                 # (150) send an RVM
                 :voice_recording_id, :from_phone,
                 # (170) send an email
                 :bcc_email, :bcc_name, :cc_email, :cc_name, :email_template_id, :email_template_subject, :email_template_yield, :from_email, :from_name, :reply_email, :reply_name, :to_email,
                 # (171) send an email to a user via Chiirp
                 :send_to, :subject, :body,
                 # (180) send a Slack message
                 :slack_channel, :text_message, :attachments,
                 # (181) create a Slack channel
                 :slack_channel,
                 # (182) add Users to a Slack channel
                 :slack_channel, :users,
                 # (200) start a Campaign
                 :campaign_id,
                 # (250 & 450) start/stop an AI Agent Conversation
                 :aiagent_id,
                 # (300 & 305) apply/remove a Tag
                 :tag_id,
                 # (340 & 345) assign to/remove from a Stage
                 :stage_id,
                 # (350 & 355) assign to/remove from a Group
                 :group_id,
                 # (360) assign a Lead Source
                 :lead_source_id,
                 # (400) stop a Campaign(s)
                 :campaign_id, :description, :job_estimate_id, :not_this_campaign,
                 # (500) set ok2text on
                 # (501) set ok2email on
                 # (505) set ok2text off
                 # (506) set ok2email off
                 # (510) assign Contact to User
                 :assign_to, :distribution,
                 # (600) parse text message response
                 :client_custom_field_id, :parse_text_respond, :parse_text_notify, :parse_text_text, :clear_field_on_invalid_response, :text_message, :attachments,
                 # (605) process/act on a Contact custom field
                 :client_custom_field_id, :response_range,
                 # (610) save data to a Contact or ContactCustomField
                 :client_custom_field_id, :description,
                 # (615) save Contacts::Note to a Contact
                 :note, :user_id,
                 # (700) create a Task
                 :name, :assign_to, :from_phone, :description, :campaign_id, :due_delay_days, :due_delay_hours, :due_delay_minutes, :dead_delay_days, :dead_delay_hours, :dead_delay_minutes, :cancel_after,
                 # (750) call a Contact
                 :user_id, :send_to, :from_phone, :retry_count, :retry_interval, :stop_on_connection,
                 # (800) create a Client
                 :client_name_custom_field_id, :client_package_id,
                 # (801) Push Contact to Client
                 # clients: [{ client_id: integer, client_campaign_id: integer, agency_campaign_id: integer, max_monthly_leads: integer, leads_this_month: integer, period_start_date: DateTime.iso8601 }]
                 :clients,
                 # Integration specific actions
                 # (901) Push data to PC Richard
                 :completed, :install_method, :scheduled, :serial_number

  after_initialize :apply_defaults
  after_validation :set_sequence
  after_commit     :after_commit_process

  scope :for_campaign, ->(campaign_id) {
    joins(:trigger)
      .where(triggers: { campaign_id: })
  }
  scope :for_client_and_action_type, ->(client_id, action_type) {
    joins(:trigger)
      .joins(trigger: :campaign)
      .where(campaigns: { client_id: })
      .where(triggeractions: { action_type: })
  }

  def all_types?
    ALL_TYPES.include?(action_type)
  end

  # analyze a Triggeraction for errors
  # returns a hash of errors
  #   [
  #     {trigger_id: Integer, triggeraction_id: Integer},
  #     {trigger_id: Integer, triggeraction_id: Integer}
  #   ]
  # result = triggeraction.analyze!
  def analyze!
    response = []

    case action_type
    when 100
      # send a text message
      response << { trigger_id: trigger_id, triggeraction_id: id, description: "Text Message was NOT saved for #{type_name}." } if text_message.empty? && attachments.empty?
      response << { trigger_id: trigger_id, triggeraction_id: id, description: "Recipient was NOT selected for #{type_name}." } if send_to.empty?
    when 105
      # send text message to User
      response << { trigger_id: trigger_id, triggeraction_id: id, description: "Text Message was NOT saved for #{type_name}." } if text_message.empty?
    when 150
      # send a ringless voicemail
      if voice_recording_id.to_i.positive?
        response << { trigger_id: trigger_id, triggeraction_id: id, description: "Ringless Voicemail selected for #{type_name} was NOT found." } unless trigger.campaign.client.voice_recordings.find_by(id: voice_recording_id)
      else
        response << { trigger_id: trigger_id, triggeraction_id: id, description: "Ringless Voicemail was NOT selected for #{type_name}." }
      end
    when 170
      # send an email
      if (email_template_id.to_i.positive? && trigger.campaign.client.email_templates.find_by(id: email_template_id)) || (email_template_yield.present? && email_template_subject.present?)
        response << { trigger_id: trigger_id, triggeraction_id: id, description: "Email API key was NOT saved for #{type_name}." } unless trigger.campaign.client.send_emails?
      else
        response << { trigger_id: trigger_id, triggeraction_id: id, description: "Email Message was NOT saved for #{type_name}." }
      end
    when 171
      # send email to a user via Chiirp
      response << { trigger_id: trigger_id, triggeraction_id: id, description: "Email \"Send To\" was NOT saved for #{type_name}." } if send_to.blank?
      response << { trigger_id: trigger_id, triggeraction_id: id, description: "Email Subject was NOT saved for #{type_name}." } if subject.blank?
    when 180
      # send Slack message
      response << { trigger_id: trigger_id, triggeraction_id: id, description: "Slack Message was NOT saved for #{type_name}." } if text_message.empty?
      response << { trigger_id: trigger_id, triggeraction_id: id, description: "Slack channel was NOT selected for #{type_name}." } if slack_channel.empty?
    when 181
      # create new Slack channel
      response << { trigger_id: trigger_id, triggeraction_id: id, description: "Slack channel was NOT selected for #{type_name}." } if slack_channel.empty?
    when 182
      # add Users to Slack channel
      response << { trigger_id: trigger_id, triggeraction_id: id, description: "Slack channel was NOT selected for #{type_name}." } if slack_channel.empty?
      response << { trigger_id: trigger_id, triggeraction_id: id, description: "Users were NOT selected for #{type_name}." } if users.empty?
    when 200
      # start Campaign
      if campaign_id.to_i.positive?
        response << { trigger_id: trigger_id, triggeraction_id: id, description: "Campaign selected for #{type_name} was NOT found." } unless trigger.campaign.client.campaigns.find_by(id: campaign_id)
      else
        response << { trigger_id: trigger_id, triggeraction_id: id, description: "Campaign was NOT selected for #{type_name}." }
      end
    when 250
      # start AI Agent session
      if aiagent_id.to_i.positive?
        response << { trigger_id: trigger_id, triggeraction_id: id, description: "AI Agent selected for #{type_name} was NOT found." } unless trigger.campaign.client.aiagents.find_by(id: aiagent_id)
      else
        response << { trigger_id: trigger_id, triggeraction_id: id, description: "AI Agent was NOT selected for #{type_name}." }
      end
    when 300, 305
      # apply/remove a Tag
      if tag_id.to_i.positive?
        response << { trigger_id: trigger_id, triggeraction_id: id, description: "Tag selected for #{type_name} was NOT found." } unless trigger.campaign.client.tags.find_by(id: tag_id)
      else
        response << { trigger_id: trigger_id, triggeraction_id: id, description: "Tag was NOT selected for #{type_name}." }
      end
    when 340
      # add to a Stage
      if stage_id.to_i.positive?
        response << { trigger_id: trigger_id, triggeraction_id: id, description: "Stage selected for #{type_name} was NOT found." } unless Stage.joins(:stage_parent).where(stage_parent: { client_id: trigger.campaign.client_id }).find_by(id: stage_id)
      else
        response << { trigger_id: trigger_id, triggeraction_id: id, description: "Stage was NOT selected for #{type_name}." }
      end
    when 345
      # remove from a Stage
      response << { trigger_id: trigger_id, triggeraction_id: id, description: "Stage was NOT selected for #{type_name}." } if stage_id.to_i.positive? && !Stage.joins(:stage_parent).where(stage_parent: { client_id: trigger.campaign.client_id }).find_by(id: stage_id)
    when 350, 355
      # add/remove to a Group
      if group_id.to_i.positive?
        response << { trigger_id: trigger_id, triggeraction_id: id, description: "Group selected for #{type_name} was NOT found." } unless trigger.campaign.client.groups.find_by(id: group_id)
      else
        response << { trigger_id: trigger_id, triggeraction_id: id, description: "Group was NOT selected for #{type_name}." }
      end
    when 360
      # assign a Lead Source
      if lead_source_id.nil?
        response << { trigger_id: trigger_id, triggeraction_id: id, description: "Lead Source was NOT selected for #{type_name}." }
      else
        response << { trigger_id: trigger_id, triggeraction_id: id, description: "Lead Source selected for #{type_name} was NOT found." } unless lead_source_id.to_i.zero? || trigger.campaign.client.lead_sources.find_by(id: lead_source_id)
      end
    when 400
      # stop Campaign(s)
      if (campaign_id.is_a?(String) && campaign_id.empty?) || (campaign_id.is_a?(Integer) && campaign_id.zero?)
        response << { trigger_id: trigger_id, triggeraction_id: id, description: "Campaign was NOT selected for #{type_name}." }
      elsif campaign_id.is_a?(Integer)
        response << { trigger_id: trigger_id, triggeraction_id: id, description: "Campaign selected for #{type_name} was NOT found." } unless trigger.campaign.client.campaigns.find_by(id: campaign_id.to_i)
      end
    when 450
      # stop AI Agent session

    when 500
      # turn ok2text ON

    when 501
      # turn ok2email ON

    when 505
      # turn ok2text OFF

    when 506
      # turn ok2email OFF

    when 510
      # reassign Contact
      if assign_to.empty?
        response << { trigger_id: trigger_id, triggeraction_id: id, description: "No one was selected for #{type_name}." }
      else
        found_users   = true
        users         = []
        org_positions = []

        assign_to.each_key do |key|
          key_split = key.split('_')
          users         << key_split[1].to_i if key_split[0] == 'user'
          org_positions << key_split[1].to_i if key_split[0] == 'orgposition'
        end

        found_users = false if users.present? && users.length != trigger.campaign.client.users.where(id: users).length
        found_users = false if !found_users || (org_positions.present? && org_positions.length != trigger.campaign.client.org_positions.where(id: org_positions).length)

        response << { trigger_id: trigger_id, triggeraction_id: id, description: "No one was found for #{type_name}." } unless found_users
      end
    when 600
      # parse text message response
      response << { trigger_id: trigger_id, triggeraction_id: id, description: "Custom Field was NOT selected for #{type_name}." } if client_custom_field_id.empty?
    when 605
      # save response to ClientCustomField
      if client_custom_field_id.positive?
        response << { trigger_id: trigger_id, triggeraction_id: id, description: "Custom Field was NOT selected for #{type_name}." } unless trigger.campaign.client.client_custom_fields.find_by(id: client_custom_field_id)
      else
        response << { trigger_id: trigger_id, triggeraction_id: id, description: "Custom Field was NOT selected for #{type_name}." }
      end
    when 610
      # update a ClientCustomField
      response << { trigger_id: trigger_id, triggeraction_id: id, description: "Contact Info was NOT selected for #{type_name}." } if client_custom_field_id.empty?
      response << { trigger_id: trigger_id, triggeraction_id: id, description: "Contact Info was NOT selected for #{type_name}." } if client_custom_field_id != client_custom_field_id.to_i.to_s && client_custom_field_id.to_i.positive? && !trigger.campaign.client.client_custom_fields.find_by(id: client_custom_field_id.to_i)
      response << { trigger_id: trigger_id, triggeraction_id: id, description: "Contact Info was NOT entered for #{type_name}." } if description.empty?
    when 615
      # (615) save Contacts::Note to a Contact
      response << { trigger_id: trigger_id, triggeraction_id: id, description: "Task name was not entered for #{type_name}." } if note.blank?
    when 700
      # create a Task
      response << { trigger_id: trigger_id, triggeraction_id: id, description: "Task name was not entered for #{type_name}." } if name.empty?
      response << { trigger_id: trigger_id, triggeraction_id: id, description: "User was not select for #{type_name}." } if assign_to.empty?
      response << { trigger_id: trigger_id, triggeraction_id: id, description: "Selected Campaign does NOT exist for #{type_name}." } if campaign_id.positive? && !trigger.campaign.client.campaigns.find_by(id: campaign_id)
    when 750
      # make a voice call
      response << { trigger_id: trigger_id, triggeraction_id: id, description: "Who to Call was NOT selected for #{type_name}." } if send_to.empty?
      response << { trigger_id: trigger_id, triggeraction_id: id, description: "User to Connect Call To was NOT selected for #{type_name}." } if user_id.empty?
    when 800
      # create a Client
      if client_name_custom_field_id.zero?
        # ClientCustomField for company name was not selected
        response << { trigger_id: trigger_id, triggeraction_id: id, description: "Client name Custom Field was not selected for #{type_name}." }
      end

      if client_package_id.zero?
        # Package was not selected
        response << { trigger_id: trigger_id, triggeraction_id: id, description: "Package was not selected for #{type_name}." }
      elsif (client_package = Package.find_by(id: client_package_id)) && ((client_package.promo_months.positive? && client_package.promo_mo_charge.to_d.positive?) || client_package.mo_charge.to_d.positive? || client_package.setup_fee.to_d.positive?)
        # Package was selected / it isn't free
        response << { trigger_id: trigger_id, triggeraction_id: id, description: "Package selected for #{type_name} is NOT free. A credit card is not collected within this action." }
      end
    when 801
      # Push Contact to Client
      response << { trigger_id: trigger_id, triggeraction_id: id, description: "Clients were not selected for #{type_name}." } if clients.empty?
    when 901
      # Push to PC Richard
      response << { trigger_id: trigger_id, triggeraction_id: id, description: "Custom Field for completed date was not selected for #{type_name}." } if install_method == 'completed' && completed.dig('date').blank?
      response << { trigger_id: trigger_id, triggeraction_id: id, description: "Custom Field for scheduled date was not selected for #{type_name}." } if install_method == 'scheduled' && completed.dig('date').blank?
    else
      response << { trigger_id: trigger_id, triggeraction_id: id, description: 'Action Type was not selected for new Action.' }
    end

    response
  end

  # copy a Triggeraction
  # triggeraction.copy()
  #   (req) new_trigger_id: (Integer)
  #
  #   (opt) campaign_id_prefix: (String)
  def copy(new_trigger_id:, **args)
    campaign_id_prefix = args.dig(:campaign_id_prefix).to_s

    return nil unless new_trigger_id.to_i.positive? && (new_trigger = Trigger.find_by(id: new_trigger_id.to_i))

    new_triggeraction = self.dup
    new_triggeraction.trigger_id = new_trigger.id

    return nil unless new_triggeraction.save

    case action_type
    when 100
      # send text to Contact
      # :text_message / :send_to / :attachments
      new_triggeraction.send_to = copy_send_to(send_to:, new_client: new_triggeraction.campaign.client) unless send_to.empty?

      new_triggeraction.from_phone = []

      self.from_phone.each do |fp|
        new_triggeraction.from_phone << fp if fp != fp.to_i.to_s || self.campaign.client_id == new_triggeraction.campaign.client_id
      end
    when 150
      # send VoiceRecording
      # :voice_recording_id
      if self.campaign.client_id != new_triggeraction.campaign.client_id

        if self.voice_recording_id.to_i.positive?
          # VoiceRecording can NOT be copied to a new Client
          new_triggeraction.voice_recording_id = nil
        end

        new_triggeraction.from_phone = '' if self.from_phone == self.from_phone.to_i.to_s
      end
    when 170
      # send email
      if self.campaign.client_id != new_triggeraction.campaign.client_id
        # we need a new email template for the client
        old_email_template = EmailTemplate.find_by(id: email_template_id)

        if old_email_template
          new_triggeraction.email_template_id = if (new_email_template = old_email_template.copy(new_client_id: new_triggeraction.campaign.client_id, campaign_id_prefix:))
                                                  new_email_template.id
                                                end
        end
      end
    when 171
      # send email to a user via Chiirp
      new_triggeraction.send_to = copy_send_to(send_to:, new_client: new_triggeraction.campaign.client) unless send_to.empty?
    when 180
      # send slack
    when 181
      # create a Slack channel
    when 182
      # add Users to Slack channel
    when 200
      # start another Campaign
      # :campaign_id

      if self.campaign_id.positive? && self.campaign.client_id != new_triggeraction.campaign.client_id
        # Campaign can NOT be copied to a new Client
        new_triggeraction.campaign_id = 0
      end
    when 250, 450
      # Aiagents
      if self.campaign.client_id == new_triggeraction.campaign.client_id
        new_triggeraction.aiagent_id = self.aiagent_id
      elsif self.campaign.client.aiagent_included_count.zero?
        # Aiagent can NOT be copied to a new Client
        new_triggeraction.aiagent_id = 0
      else
        # copy the aiagent to the client, and use that for the id
        aiagent = Aiagent.find_by(id: self.aiagent_id)
        new_aiagent = aiagent.copy(new_client_id: new_triggeraction.campaign.client_id)
        new_triggeraction.aiagent_id = new_aiagent.id
      end
    when 300, 305
      # apply/remove Tag
      # :tag_id

      if tag_id.positive? && self.campaign.client_id != new_triggeraction.campaign.client_id && (tag = Tag.find_by(id: tag_id))
        new_triggeraction.tag_id = if (new_tag = tag.copy(new_client_id: new_triggeraction.campaign.client_id))
                                     new_tag.id
                                   else
                                     0
                                   end
      end
    when 340, 345
      # add/remove Stage
      # :stage_id

      if stage_id.positive? && self.campaign.client_id != new_triggeraction.campaign.client_id && (stage = Stage.find_by(id: stage_id))
        new_triggeraction.stage_id = if (new_stage = stage.copy(new_client: new_triggeraction.campaign.client))
                                       new_stage.id
                                     else
                                       0
                                     end
      end
    when 350, 355
      # add/remove Group
      # :group_id

      if group_id.positive? && self.campaign.client_id != new_triggeraction.campaign.client_id && (group = Group.find_by(id: group_id))
        new_triggeraction.group_id = if (new_group = group.copy(new_client_id: new_triggeraction.campaign.client_id))
                                       new_group.id
                                     else
                                       0
                                     end
      end
    when 360
      # assign a Lead Source
      # :lead_source_id

      if self.lead_source_id.positive? && self.campaign.client_id != new_triggeraction.campaign.client_id && (lead_source = self.campaign.client.lead_sources.find_by(id: self.lead_source_id))
        new_triggeraction.lead_source_id = if (new_lead_source = lead_source.copy(new_client_id: new_triggeraction.campaign.client_id))
                                             new_lead_source.id
                                           end
      end
    when 400
      # stop a Campaign
      # :campaign_id

      if self.campaign_id.present? && self.campaign.client_id != new_triggeraction.campaign.client_id

        case self.campaign_id[0, 6]
        when 'this'
          # no adjustments here
        when 'all_ot'
          # no adjustments here
        when 'group_'
          new_triggeraction.campaign_id = 0
          # stop_ids = contact.contact_campaigns.where(campaign_id: self.campaign.client.campaigns.where(campaign_group_id: self.campaign_id.gsub('group_', '').to_i).pluck(:id)).pluck(:id)
        else
          new_triggeraction.campaign_id = (campaign_id_prefix.present? ? campaign_id_prefix + self.campaign_id.strip : '0')
        end
      end
    when 500
      # set ok2text on
    when 501
      # set ok2email on
    when 505
      # set ok2text off
    when 506
      # set ok2email off
    when 510
      # assign to User
      # :assign_to / :distribution

      if assign_to.length.positive? && self.campaign.client_id != new_triggeraction.campaign.client_id
        # Users can NOT be copied to new Client
        new_triggeraction.assign_to = {}

        assign_to.each do |user_org, percentage|
          user_org_split = user_org.split('_')

          if user_org_split[0] == 'orgposition'

            if new_triggeraction.campaign.client.org_positions.length.positive?
              # match up the OrgPosition level and reassign

              if (org_position = self.campaign.client.org_positions.find_by(id: user_org_split[1].to_i)) && ((new_org_position = new_triggeraction.campaign.client.org_positions.find_by(level: org_position.level)) || (new_org_position = new_triggeraction.campaign.client.org_positions.order(:level).last))
                new_triggeraction.assign_to["orgposition_#{new_org_position.id}"] = percentage
              end
            else
              # new Client does NOT have OrgPositions defined / create them

              self.campaign.client.org_positions.order(:level).each do |op|
                new_org_position = new_triggeraction.campaign.client.org_positions.create(title: op.title, level: op.level)

                new_triggeraction.assign_to["orgposition_#{new_org_position.id}"] = percentage if op.id == user_org_split[1].to_i
              end
            end
          end
        end

        new_triggeraction.distribution = {}
      end
    when 600
      # save text response
      # :client_custom_field_id / :parse_text_respond / :parse_text_notify / :parse_text_text

      if client_custom_field_id != client_custom_field_id.to_i.to_s
        # client_custom_field_id is a native field
      elsif client_custom_field_id.to_i.positive? && self.campaign.client_id != new_triggeraction.campaign.client_id
        # client_custom_field_id is a ClientCustomField & NOT the same Client
        new_triggeraction.client_custom_field_id = ''

        if (client_custom_field = self.campaign.client.client_custom_fields.find_by(id: client_custom_field_id.to_i))
          new_client_custom_field = client_custom_field.copy(new_client_id: new_triggeraction.campaign.client_id)
          new_triggeraction.client_custom_field_id = new_client_custom_field.id.to_s if new_client_custom_field
        end
      end
    when 605
      # ClientCustomField action
      # :client_custom_field_id

      if client_custom_field_id.positive? && self.campaign.client_id != new_triggeraction.campaign.client_id
        new_triggeraction.client_custom_field_id = 0
        new_triggeraction.response_range&.deep_symbolize_keys!

        if (client_custom_field = self.campaign.client.client_custom_fields.find_by(id: client_custom_field_id))
          new_client_custom_field = client_custom_field.copy(new_client_id: new_triggeraction.campaign.client_id)
          new_triggeraction.client_custom_field_id = new_client_custom_field.id if new_client_custom_field

          if new_triggeraction.client_custom_field_id.positive?

            if client_custom_field.var_type == 'string' && client_custom_field.var_options.include?(:string_options)
              # ClientCustomField has :string_options

              client_custom_field.string_options_as_array.each do |so|
                # scan through each :string_option

                if response_range.dig(so, 'campaign_id').to_i.positive?
                  # Campaign id for :string_option is defined
                  new_triggeraction.response_range[so.to_sym][:campaign_id] = (campaign_id_prefix.length.positive? ? campaign_id_prefix + response_range.dig(so, 'campaign_id').to_s.strip : 0)
                end

                if response_range.dig(so, 'group_id').to_i.positive?
                  # Group id for :string_option is defined
                  new_triggeraction.response_range[so.to_sym][:group_id] = 0

                  # find the existing Group
                  if (group = self.campaign.client.groups.find_by(id: response_range.dig(so, 'group_id').to_i))
                    # existing Group was found

                    # find or create Group for new Client
                    new_group = group.copy(new_client_id: new_triggeraction.campaign.client_id)
                    new_triggeraction.response_range[so.to_sym][:group_id] = new_group.id if new_group
                  end
                end

                if response_range.dig(so, 'stage_id').to_i.positive?
                  # Stage id for :string_option is defined
                  new_triggeraction.response_range[so.to_sym][:stage_id] = 0

                  # find the existing Stage
                  if (tag = self.campaign.client.stages.find_by(id: response_range.dig(so, 'stage_id').to_i))
                    # existing Stage was found

                    # find or create Stage for new Client
                    new_stage = stage.copy(new_client_id: new_triggeraction.campaign.client_id)
                    new_triggeraction.response_range[so.to_sym][:stage_id] = new_stage.id if new_stage
                  end
                end

                if response_range.dig(so, 'tag_id').to_i.positive?
                  # Tag id for :string_option is defined
                  new_triggeraction.response_range[so.to_sym][:tag_id] = 0

                  # find the existing Tag
                  if (tag = self.campaign.client.tags.find_by(id: response_range.dig(so, 'tag_id').to_i))
                    # existing Tag was found

                    # find or create Tag for new Client
                    new_tag = tag.copy(new_client_id: new_triggeraction.campaign.client_id)
                    new_triggeraction.response_range[so.to_sym][:tag_id] = new_tag.id if new_tag
                  end
                end
              end
            elsif %w[numeric currency stars].include?(client_custom_field.var_type)
              # ClientCustomField has :response_range

              new_triggeraction.response_range.each_value do |values|
                # scan through :response_ranges

                if values.dig(:campaign_id).to_i.positive?
                  # Campaign id for :response_range is defined
                  values[:campaign_id] = (campaign_id_prefix.length.positive? ? campaign_id_prefix + values[:campaign_id].to_s.strip : 0)
                end

                if values.dig(:group_id).to_i.positive?
                  # Group id for :string_option is defined
                  group_id = values[:group_id].to_i
                  values[:group_id] = 0

                  # find the existing Group
                  if (group = self.campaign.client.groups.find_by(id: group_id))
                    # existing Group was found

                    # find or create Group for new Client
                    new_group = group.copy(new_client_id: new_triggeraction.campaign.client_id)
                    values[:group_id] = new_group.id if new_group
                  end
                end

                if values.dig(:stage_id).to_i.positive?
                  # Stage id for :string_option is defined
                  stage_id = values[:stage_id].to_i
                  values[:stage_id] = 0

                  # find the existing Stage
                  if (stage = self.campaign.client.stages.find_by(id: stage_id))
                    # existing Stage was found

                    # find or create Stage for new Client
                    new_stage = stage.copy(new_client_id: new_triggeraction.campaign.client_id)
                    values[:stage_id] = new_stage.id if new_stage
                  end
                end

                if values.dig(:tag_id).to_i.positive?
                  # Tag id for :string_option is defined
                  tag_id = values[:tag_id].to_i
                  values[:tag_id] = 0

                  # find the existing Tag
                  if (tag = self.campaign.client.tags.find_by(id: tag_id))
                    # existing Tag was found

                    # find or create Tag for new Client
                    new_tag = tag.copy(new_client_id: new_triggeraction.campaign.client_id)
                    values[:tag_id] = new_tag.id if new_tag
                  end
                end
              end
            end
          end
        end
      end
    when 610
      # save data to a Contact or ContactCustomField

      if client_custom_field_id.to_i.positive? && self.campaign.client_id != new_triggeraction.campaign.client_id
        new_triggeraction.client_custom_field_id = ''

        if (client_custom_field = self.campaign.client.client_custom_fields.find_by(id: client_custom_field_id.to_i))
          new_client_custom_field = client_custom_field.copy(new_client_id: new_triggeraction.campaign.client_id)
          new_triggeraction.client_custom_field_id = new_client_custom_field.id if new_client_custom_field
        end
      end
    when 615
      # (615) save Contacts::Note to a Contact
      new_triggeraction.assign_to = new_triggeraction.campaign.client.def_user_id if self.campaign.client_id != new_triggeraction.campaign.client_id
    when 700
      # create a Task

      if self.campaign.client_id != new_triggeraction.campaign.client_id
        new_triggeraction.assign_to   = new_triggeraction.campaign.client.def_user_id
        new_triggeraction.from_phone  = new_triggeraction.campaign.client.def_user.default_from_twnumber&.phonenumber.to_s
        new_triggeraction.campaign_id = 0
      end
    when 750
      # call Contact
      new_triggeraction.send_to = copy_send_to(send_to:, new_client: new_triggeraction.campaign.client) unless data.dig(:send_to).to_s.empty?
      new_triggeraction.user_id = copy_send_to(send_to: user_id, new_client: new_triggeraction.campaign.client) unless user_id.to_s.empty?
      new_triggeraction.from_phone = '' if self.from_phone.to_s == self.from_phone.to_s.to_i.to_s && self.campaign.client_id != new_triggeraction.campaign.client_id
    when 800
      # create a Client

      if user_id.positive? && self.campaign.client_id != new_triggeraction.campaign.client_id
        # User id can NOT be copied to a new Client
        new_triggeraction.user_id = new_triggeraction.campaign.client.def_user_id
      end
    when 801
      # Push Contact to Client
      new_triggeraction.clients = []
    when 901
      # Push data to PC Richard
    end

    if new_triggeraction.save
      # new Triggeraction was saved

      # copy any TrackableLinks if copying to a different Client
      if [100, 700].include?(action_type) && self.campaign.client_id != new_triggeraction.campaign.client_id

        message = if action_type == 100 && text_message.length.positive?
                    text_message
                  elsif action_type == 700 && description.length.positive?
                    description
                  else
                    ''
                  end

        if message.length.positive?
          self.campaign.client.trackable_links.each do |trackable_link|
            hashtag = format('\#{trackable_link_%s}', trackable_link.id.to_s) # '#{trackable_link_1234}'

            if message.include?(hashtag) && (new_trackable_link = trackable_link.copy(new_client: new_triggeraction.campaign.client, campaign_id_prefix:))
              message = message.gsub(hashtag, format('\#{trackable_link_%s}', new_trackable_link.id.to_s))
            end
          end

          if action_type == 100 && text_message.length.positive?
            new_triggeraction.text_message = message
          elsif action_type == 700 && description.length.positive?
            new_triggeraction.description = message
          end

          new_triggeraction.save
        end
      end
    else
      new_triggeraction = nil
    end

    new_triggeraction
  end

  # determine the appropriate User to reassign the Triggeraction to
  # copy_send_to()
  #   (req) new_client: (Client)
  #   (req) send_to:    (String)
  def copy_send_to(new_client:, **args)
    send_to       = (args.dig(:send_to) || 'user').to_s.strip
    response      = send_to
    send_to_split = send_to.split('_')

    return response unless new_client.is_a?(Client)

    if send_to_split.length == 2 && send_to_split[0] == 'user'

      if trigger.campaign.client_id != new_client.id
        # User id can NOT be copied to a new Client
        # set the User id to the default User for the new Client
        response = "user_#{new_client.def_user_id}"
      end
    elsif send_to_split.length == 2 && send_to_split[0] == 'orgposition'

      if trigger.campaign.client_id != new_client.id
        # assigning to an OrgPosition does not easily translate to a new Client
        response = 'user'

        if new_client.org_positions.length.positive?
          # match up the OrgPosition level and reassign

          if (org_position = trigger.campaign.client.org_positions.find_by(id: send_to_split[1].to_i)) && ((new_org_position = new_client.org_positions.find_by(level: org_position.level)) || (new_org_position = new_client.org_positions.order(:level).last))
            response = "orgposition_#{new_org_position.id}"
          end
        else
          # new Client does NOT have OrgPositions defined / create them

          trigger.campaign.client.org_positions.order(:level).each do |op|
            new_org_position = new_client.org_positions.create(title: op.title, level: op.level)

            response = "orgposition_#{new_org_position.id}" if op.id == send_to_split[1].to_i
          end
        end
      end
    end

    response
  end

  # process a Triggeraction
  # @triggeraction.fire()
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  def fire(contact:, contact_campaign:, **args)
    JsonLog.info 'Triggeraction.fire', { triggeraction: self, contact:, contact_campaign:, args: }
    return false unless contact.is_a?(Contact) && contact_campaign.is_a?(Contacts::Campaign)

    common_args = {
      start_time:    args.dig(:start_time).is_a?(Time) ? args[:start_time] : Time.current,
      interval:      contact.client.text_delay,
      time_zone:     self.campaign.client.time_zone,
      reverse:       args.dig(:reverse).to_bool,
      delay_months:  self.delay_months,
      delay_days:    self.delay_days,
      delay_hours:   self.delay_hours,
      delay_minutes: self.delay_minutes,
      safe_start:    self.safe_start,
      safe_end:      self.safe_end,
      safe_sun:      self.safe_sun,
      safe_mon:      self.safe_mon,
      safe_tue:      self.safe_tue,
      safe_wed:      self.safe_wed,
      safe_thu:      self.safe_thu,
      safe_fri:      self.safe_fri,
      safe_sat:      self.safe_sat,
      holidays:      contact.client.holidays.to_h { |h| [h.occurs_at, h.action] },
      ok2skip:       self.ok2skip
    }

    send(:"fire_triggeraction_#{self.action_type}", contact:, contact_campaign:, common_args:, message: args.dig(:message))
  end

  # determine a from_phone to fire Triggeraction on
  # triggeraction.fire_from_phone()
  #   (req) contact: (Contact)
  def fire_from_phone(contact)
    contact = case contact
              when Contact
                contact
              when Integer
                Contact.find_by(id: contact)
              end

    return '' unless contact.is_a?(Contact)

    from_phone = self.campaign.get_lock_phone(contact:)
    from_phone = self.from_phone if from_phone.empty?

    return from_phone unless from_phone.is_a?(Array)

    if from_phone.compact_blank.blank? || from_phone.include?('last_number')
      from_phone = 'last_number'
    elsif from_phone.include?('user_number')
      from_phone = 'user_number'
    elsif from_phone.length == 1 && from_phone[0] == from_phone[0].to_i.to_s
      from_phone = from_phone[0]
    end

    if from_phone.is_a?(Array)
      from_phone -= %w[last_number user_number]

      if self.last_used_from_phone.empty?
        from_phone = from_phone.first
      else
        index_of_from_phone = (from_phone.index(self.last_used_from_phone) || -1).to_i
        from_phone = (index_of_from_phone + 1) == from_phone.length ? from_phone.first : from_phone[index_of_from_phone + 1]
      end

      contact.latest_client_phonenumber(default_ok: true, phone_numbers_only: true)&.phonenumber.to_s if from_phone.blank?

      self.update(last_used_from_phone: from_phone.to_s)
    end

    from_phone
  end

  # 100 send a text message
  # triggeraction.fire_triggeraction_100()
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  #   (req) common_args:      (Hash)
  def fire_triggeraction_100(contact:, contact_campaign:, common_args:, **_args)
    from_phone  = self.fire_from_phone(contact)
    run_at_time = AcceptableTime.new(common_args).new_time(common_args[:start_time].in_time_zone(common_args[:time_zone]))

    if self.text_message.present? || self.attachments.present?

      if run_at_time.present?
        image_id_array = self.fire_triggeraction_100_image_ids(contact:, contact_campaign:)

        send_to = self.send_to.present? ? self.send_to.split('_') : ['']

        twnumber_phonenumber = case from_phone
                               when 'user_number'
                                 contact.user.default_from_twnumber&.phonenumber.to_s
                               when 'last_number'
                                 contact.latest_client_phonenumber(default_ok: true, phone_numbers_only: true)&.phonenumber.to_s
                               else
                                 from_phone
                               end

        if send_to[0] == 'contact'
          run_at = PhoneNumberReservations.new(twnumber_phonenumber).reserve(common_args.merge(action_time: run_at_time.utc))

          unless run_at.nil?
            data = {
              from_phone:,
              to_label:                send_to[1] || '',
              to_label_fallback:       self.trigger.trigger_type == 152 ? 'voice' : '',
              content:                 self.text_message,
              image_id_array:,
              triggeraction_id:        self.id,
              automated:               true,
              msg_type:                'textout',
              contact_estimate_id:     contact_campaign.data.dig(:contact_estimate_id),
              contact_invoice_id:      contact_campaign.data.dig(:contact_invoice_id),
              contact_job_id:          contact_campaign.data.dig(:contact_job_id),
              contact_subscription_id: contact_campaign.data.dig(:contact_subscription_id),
              contact_visit_id:        contact_campaign.data.dig(:contact_visit_id),
              contact_campaign_id:     contact_campaign.id
            }
            contact.delay(
              run_at:,
              priority:            DelayedJob.job_priority('send_text'),
              queue:               DelayedJob.job_queue('send_text'),
              contact_id:          contact.id,
              user_id:             contact.user_id,
              triggeraction_id:    self.id,
              contact_campaign_id: contact_campaign.id,
              data:,
              process:             'send_text'
            ).send_text(data)
          end
        elsif %w[user orgposition].include?(send_to[0])
          data = {
            automated:               true,
            contact_campaign_id:     contact_campaign.id,
            contact_estimate_id:     contact_campaign.data.dig(:contact_estimate_id),
            contact_id:              contact.id,
            contact_invoice_id:      contact_campaign.data.dig(:contact_invoice_id),
            contact_job_id:          contact_campaign.data.dig(:contact_job_id),
            contact_subscription_id: contact_campaign.data.dig(:contact_subscription_id),
            contact_visit_id:        contact_campaign.data.dig(:contact_visit_id),
            content:                 self.text_message,
            from_phone:,
            image_id_array:,
            msg_type:                'textoutuser',
            send_to:                 send_to.join('_'),
            triggeraction_id:        self.id
          }
          contact.user.delay(
            run_at:              run_at_time.utc,
            priority:            DelayedJob.job_priority('send_text'),
            queue:               DelayedJob.job_queue('send_text'),
            contact_id:          contact.id,
            user_id:             contact.user_id,
            triggeraction_id:    self.id,
            contact_campaign_id: contact_campaign.id,
            data:,
            process:             'send_text'
          ).send_text(data)
        elsif send_to[0] == 'primary'
          run_at = PhoneNumberReservations.new(twnumber_phonenumber).reserve(common_args.merge(action_time: run_at_time.utc))

          unless run_at.nil?
            data = {
              from_phone:,
              to_label:                'primary',
              to_phone:                contact.primary_phone&.phone.to_s,
              content:                 self.text_message,
              image_id_array:,
              triggeraction_id:        self.id,
              automated:               true,
              msg_type:                'textout',
              contact_estimate_id:     contact_campaign.data.dig(:contact_estimate_id),
              contact_invoice_id:      contact_campaign.data.dig(:contact_invoice_id),
              contact_job_id:          contact_campaign.data.dig(:contact_job_id),
              contact_subscription_id: contact_campaign.data.dig(:contact_subscription_id),
              contact_visit_id:        contact_campaign.data.dig(:contact_visit_id),
              contact_campaign_id:     contact_campaign.id
            }
            contact.delay(
              run_at:,
              priority:            DelayedJob.job_priority('send_text'),
              queue:               DelayedJob.job_queue('send_text'),
              contact_id:          contact.id,
              user_id:             contact.user_id,
              triggeraction_id:    self.id,
              contact_campaign_id: contact_campaign.id,
              data:,
              process:             'send_text'
            ).send_text(data)
          end
        elsif send_to[0] == 'last'
          run_at = PhoneNumberReservations.new(twnumber_phonenumber).reserve(common_args.merge(action_time: run_at_time.utc))

          unless run_at.nil?
            data = {
              from_phone:,
              to_phone:                contact.latest_contact_phone_by_label,
              content:                 self.text_message,
              image_id_array:,
              triggeraction_id:        self.id,
              automated:               true,
              msg_type:                'textout',
              contact_estimate_id:     contact_campaign.data.dig(:contact_estimate_id),
              contact_invoice_id:      contact_campaign.data.dig(:contact_invoice_id),
              contact_job_id:          contact_campaign.data.dig(:contact_job_id),
              contact_subscription_id: contact_campaign.data.dig(:contact_subscription_id),
              contact_visit_id:        contact_campaign.data.dig(:contact_visit_id),
              contact_campaign_id:     contact_campaign.id
            }
            contact.delay(
              run_at:,
              priority:            DelayedJob.job_priority('send_text'),
              queue:               DelayedJob.job_queue('send_text'),
              contact_id:          contact.id,
              user_id:             contact.user_id,
              triggeraction_id:    self.id,
              contact_campaign_id: contact_campaign.id,
              data:,
              process:             'send_text'
            ).send_text(data)
          end
        elsif send_to[0] == 'technician'

          if run_at_time.present? && (technician = contact.jobs.find_by(id: contact_campaign.data.dig(:contact_job_id))&.technician.presence || contact.estimates.find_by(id: contact_campaign.data.dig(:contact_job_id))&.technician.presence) && technician&.dig(:phone).present?
            data = {
              from_phone:,
              to_label:                'technician',
              to_phone:                technician[:phone].to_s,
              content:                 self.text_message,
              image_id_array:,
              triggeraction_id:        self.id,
              automated:               true,
              msg_type:                'textoutother',
              contact_estimate_id:     contact_campaign.data.dig(:contact_estimate_id),
              contact_invoice_id:      contact_campaign.data.dig(:contact_invoice_id),
              contact_job_id:          contact_campaign.data.dig(:contact_job_id),
              contact_subscription_id: contact_campaign.data.dig(:contact_subscription_id),
              contact_visit_id:        contact_campaign.data.dig(:contact_visit_id),
              contact_campaign_id:     contact_campaign.id
            }
            contact.delay(
              run_at:              run_at_time.utc,
              priority:            DelayedJob.job_priority('send_text'),
              queue:               DelayedJob.job_queue('send_text'),
              contact_id:          contact.id,
              user_id:             contact.user_id,
              triggeraction_id:    self.id,
              contact_campaign_id: contact_campaign.id,
              data:,
              process:             'send_text'
            ).send_text(data)
          end
        end
      end
    else
      # message was NOT sent / send text message to User
      Users::SendPushOrTextJob.perform_later(
        contact_id:       contact.id,
        content:          "Trigger: #{self.trigger.data[:name]} could NOT be processed for #{self.campaign.name}. Message or Images were NOT defined. Customer: #{contact.fullname}.",
        from_phone:,
        ok2push:          contact.user.notifications.dig('campaigns', 'by_push'),
        ok2text:          contact.user.notifications.dig('campaigns', 'by_text'),
        to_phone:         contact.user.phone,
        triggeraction_id: self.id,
        user_id:          contact.user_id
      )
    end

    contact.triggeraction_complete(triggeraction: self, contact_campaign:)
  end

  # 150 send a ringless voicemail (RVM)
  # triggeraction.fire_triggeraction_150()
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  #   (req) common_args:      (Hash)
  def fire_triggeraction_150(contact:, contact_campaign:, common_args:, **_args)
    from_phone  = self.fire_from_phone(contact)
    run_at_time = AcceptableTime.new(common_args).new_time(common_args[:start_time].in_time_zone(common_args[:time_zone]))

    if run_at_time.present?

      if contact.client.rvm_allowed

        if self.voice_recording_id.to_i.positive?

          if (voice_recording = contact.client.voice_recordings.find_by(id: self.voice_recording_id))
            voice_recording_url = if voice_recording.audio_file.attached?
                                    "#{Cloudinary::Utils.cloudinary_url(voice_recording.audio_file.key, resource_type: 'video', secure: true)}.mp3"
                                  else
                                    voice_recording.url
                                  end

            data = {
              from_phone:,
              voice_recording_id:  voice_recording.id,
              voice_recording_url:,
              message:             voice_recording.recording_name,
              triggeraction_id:    self.id,
              contact_campaign_id: contact_campaign.id
            }
            contact.delay(
              run_at:              run_at_time.utc,
              priority:            DelayedJob.job_priority('send_rvm'),
              queue:               DelayedJob.job_queue('send_rvm'),
              contact_id:          contact.id,
              triggeraction_id:    self.id,
              contact_campaign_id: contact_campaign.id,
              data:,
              process:             'send_rvm'
            ).send_rvm(data)
          else
            Users::SendPushOrTextJob.perform_later(
              contact_id:       contact.id,
              content:          "Trigger: #{self.trigger.data[:name]} could NOT be processed for #{self.campaign.name}. Ringless Voicemail was NOT found. Customer: #{contact.fullname}.",
              from_phone:,
              ok2push:          contact.user.notifications.dig('campaigns', 'by_push'),
              ok2text:          contact.user.notifications.dig('campaigns', 'by_text'),
              to_phone:         contact.user.phone,
              triggeraction_id: self.id,
              user_id:          contact.user_id
            )
          end
        else
          Users::SendPushOrTextJob.perform_later(
            contact_id:       contact.id,
            content:          "Trigger: #{self.trigger.data[:name]} could NOT be processed for #{self.campaign.name}. Ringless Voicemail was NOT selected. Customer: #{contact.fullname}.",
            from_phone:,
            ok2push:          contact.user.notifications.dig('campaigns', 'by_push'),
            ok2text:          contact.user.notifications.dig('campaigns', 'by_text'),
            to_phone:         contact.user.phone,
            triggeraction_id: self.id,
            user_id:          contact.user_id
          )
        end
      else
        Users::SendPushOrTextJob.perform_later(
          contact_id:       contact.id,
          content:          "Trigger: #{self.trigger.data[:name]} could NOT be processed for #{self.campaign.name}. Ringless Voicemail is NOT permitted. Customer: #{contact.fullname}.",
          from_phone:,
          ok2push:          contact.user.notifications.dig('campaigns', 'by_push'),
          ok2text:          contact.user.notifications.dig('campaigns', 'by_text'),
          to_phone:         contact.user.phone,
          triggeraction_id: self.id,
          user_id:          contact.user_id
        )
      end
    end

    contact.triggeraction_complete(triggeraction: self, contact_campaign:)
  end

  # 170 send an email
  # triggeraction.fire_triggeraction_170()
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  #   (req) common_args:      (Hash)
  def fire_triggeraction_170(contact:, contact_campaign:, common_args:, **_args)
    common_args.delete(:holidays)
    run_at_time = AcceptableTime.new(common_args).new_time(common_args[:start_time].in_time_zone(common_args[:time_zone]))

    if run_at_time.present?

      if (self.email_template_subject && self.email_template_yield) || trigger.campaign.client.email_templates.where(id: self.email_template_id).any?
        if contact.client.send_emails?
          from_email = if self.from_email.present? && self.from_name.present?
                         { email: self.from_email, name: self.from_name }
                       elsif self.from_name.present?
                         { email: contact.user.email, name: self.from_name }
                       else
                         self.from_email
                       end
          data = {
            automated:               true,
            bcc_email:               self.bcc_email,
            cc_email:                self.cc_email,
            contact_campaign_id:     contact_campaign.id,
            contact_estimate_id:     contact_campaign.data.dig(:contact_estimate_id),
            contact_invoice_id:      contact_campaign.data.dig(:contact_invoice_id),
            contact_job_id:          contact_campaign.data.dig(:contact_job_id),
            contact_subscription_id: contact_campaign.data.dig(:contact_subscription_id),
            contact_visit_id:        contact_campaign.data.dig(:contact_visit_id),
            email_template_yield:    self.email_template_yield,
            email_template_id:       self.email_template_id,
            from_email:,
            reply_email:             self.reply_email,
            subject:                 self.email_template_subject,
            to_email:                self.to_email,
            triggeraction_id:        self.id
          }
          contact.delay(
            run_at:              run_at_time.utc,
            priority:            DelayedJob.job_priority('send_email'),
            queue:               DelayedJob.job_queue('send_email'),
            process:             'send_email',
            contact_id:          contact.id,
            user_id:             contact.user_id,
            triggeraction_id:    self.id,
            contact_campaign_id: contact_campaign.id,
            data:
          ).send_email(data)
        else
          Users::SendPushOrTextJob.perform_later(
            contact_id:       contact.id,
            content:          "Trigger: #{self.trigger.data[:name]} could NOT be processed for #{self.campaign.name}. SendGrid API key was not found. Customer: #{contact.fullname}.",
            from_phone:       contact.user.default_from_twnumber&.phonenumber.to_s,
            ok2push:          contact.user.notifications.dig('campaigns', 'by_push'),
            ok2text:          contact.user.notifications.dig('campaigns', 'by_text'),
            to_phone:         contact.user.phone,
            triggeraction_id: self.id,
            user_id:          contact.user_id
          )
        end
      else
        Users::SendPushOrTextJob.perform_later(
          contact_id:       contact.id,
          content:          "Trigger: #{self.trigger.data[:name]} could NOT be processed for #{self.campaign.name}. Email Template does NOT exist. Customer: #{contact.fullname}.",
          from_phone:       contact.user.default_from_twnumber&.phonenumber.to_s,
          ok2push:          contact.user.notifications.dig('campaigns', 'by_push'),
          ok2text:          contact.user.notifications.dig('campaigns', 'by_text'),
          to_phone:         contact.user.phone,
          triggeraction_id: self.id,
          user_id:          contact.user_id
        )
      end
    end

    contact.triggeraction_complete(triggeraction: self, contact_campaign:)
  end

  # 171 send an email to a user via Chiirp
  # triggeraction.fire_triggeraction_171()
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  #   (req) common_args:      (Hash)
  def fire_triggeraction_171(contact:, contact_campaign:, common_args:, **_args)
    common_args.delete(:holidays)
    run_at_time = AcceptableTime.new(common_args).new_time(common_args[:start_time].in_time_zone(common_args[:time_zone]))

    if run_at_time.present? && self.send_to.present?
      # app/jobs/campaigns/triggeractions/send_email_internal_job.rb
      Campaigns::Triggeractions::SendEmailInternalJob.set(wait_until: run_at_time.utc).perform_later(
        contact_id:          contact.id,
        contact_campaign_id: contact_campaign.id,
        triggeraction_id:    self.id
      )
    end

    contact.triggeraction_complete(triggeraction: self, contact_campaign:)
  end

  # 180 send Slack notification
  # triggeraction.fire_triggeraction_180()
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  #   (req) common_args:      (Hash)
  def fire_triggeraction_180(contact:, contact_campaign:, common_args:, **_args)
    common_args.delete(:holidays)
    run_at_time = AcceptableTime.new(common_args).new_time(common_args[:start_time].in_time_zone(common_args[:time_zone]))

    if self.text_message.present?
      if run_at_time.present?
        data = {
          contact_campaign_id:     contact_campaign.id,
          contact_estimate_id:     contact_campaign.data.dig(:contact_estimate_id),
          contact_invoice_id:      contact_campaign.data.dig(:contact_invoice_id),
          contact_job_id:          contact_campaign.data.dig(:contact_job_id),
          contact_subscription_id: contact_campaign.data.dig(:contact_subscription_id),
          contact_visit_id:        contact_campaign.data.dig(:contact_visit_id),
          message:                 self.text_message,
          slack_channel:           self.slack_channel,
          triggeraction_id:        self.id
        }
        contact.delay(
          run_at:              run_at_time.utc,
          priority:            DelayedJob.job_priority('send_slack'),
          queue:               DelayedJob.job_queue('send_slack'),
          process:             'send_slack',
          contact_id:          contact.id,
          triggeraction_id:    self.id,
          contact_campaign_id: contact_campaign.id,
          data:
        ).send_to_slack(data)
      end
    else
      # message was NOT sent / send text message to User
      Users::SendPushOrTextJob.perform_later(
        contact_id:       contact.id,
        content:          "Trigger: #{self.trigger.data[:name]} could NOT be processed for #{self.campaign.name}. Message was NOT defined. Customer: #{contact.fullname}.",
        from_phone:,
        ok2push:          contact.user.notifications.dig('campaigns', 'by_push'),
        ok2text:          contact.user.notifications.dig('campaigns', 'by_text'),
        to_phone:         contact.user.phone,
        triggeraction_id: self.id,
        user_id:          contact.user_id
      )
    end

    contact.triggeraction_complete(triggeraction: self, contact_campaign:)
  end

  # 181 create a Slack channel
  # triggeraction.fire_triggeraction_181()
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  def fire_triggeraction_181(contact:, contact_campaign:, **_args)
    data = {
      contact_campaign_id:     contact_campaign.id,
      contact_estimate_id:     contact_campaign.data.dig(:contact_estimate_id),
      contact_invoice_id:      contact_campaign.data.dig(:contact_invoice_id),
      contact_job_id:          contact_campaign.data.dig(:contact_job_id),
      contact_subscription_id: contact_campaign.data.dig(:contact_subscription_id),
      contact_visit_id:        contact_campaign.data.dig(:contact_visit_id),
      slack_channel:           self.slack_channel,
      triggeraction_id:        self.id
    }
    contact.delay(
      run_at:              20.seconds.from_now,
      priority:            DelayedJob.job_priority('slack_channel_create'),
      queue:               DelayedJob.job_queue('slack_channel_create'),
      process:             'slack_channel_create',
      contact_id:          contact.id,
      triggeraction_id:    self.id,
      contact_campaign_id: contact_campaign.id,
      data:
    ).slack_channel_create(data)

    contact.triggeraction_complete(triggeraction: self, contact_campaign:)
  end

  # 182 add Users to a Slack channel
  # triggeraction.fire_triggeraction_182()
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  def fire_triggeraction_182(contact:, contact_campaign:, **_args)
    data = {
      contact_campaign_id:     contact_campaign.id,
      contact_estimate_id:     contact_campaign.data.dig(:contact_estimate_id),
      contact_invoice_id:      contact_campaign.data.dig(:contact_invoice_id),
      contact_job_id:          contact_campaign.data.dig(:contact_job_id),
      contact_subscription_id: contact_campaign.data.dig(:contact_subscription_id),
      contact_visit_id:        contact_campaign.data.dig(:contact_visit_id),
      slack_channel:           self.slack_channel,
      triggeraction_id:        self.id,
      users:                   self.users
    }
    contact.delay(
      run_at:              20.seconds.from_now,
      priority:            DelayedJob.job_priority('slack_channel_invite'),
      queue:               DelayedJob.job_queue('slack_channel_invite'),
      process:             'slack_channel_invite',
      contact_id:          contact.id,
      triggeraction_id:    self.id,
      contact_campaign_id: contact_campaign.id,
      data:
    ).slack_channel_invite(data)

    contact.triggeraction_complete(triggeraction: self, contact_campaign:)
  end

  # 200 start a Campaign
  # triggeraction.fire_triggeraction_200()
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  #   (req) common_args:      (Hash)
  def fire_triggeraction_200(contact:, contact_campaign:, common_args:, **_args)
    from_phone  = self.fire_from_phone(contact)
    run_at_time = AcceptableTime.new(common_args).new_time(common_args[:start_time].in_time_zone(common_args[:time_zone]))

    if run_at_time.present?

      if self.campaign_id.positive?
        Contacts::Campaigns::StartJob.set(wait_until: run_at_time.utc).perform_later(
          campaign_id:             self.campaign_id,
          client_id:               contact.client_id,
          contact_campaign_id:     contact_campaign.id,
          contact_estimate_id:     contact_campaign.data.dig(:contact_estimate_id).to_i,
          contact_id:              contact.id,
          contact_invoice_id:      contact_campaign.data.dig(:contact_invoice_id).to_i,
          contact_job_id:          contact_campaign.data.dig(:contact_job_id).to_i,
          contact_subscription_id: contact_campaign.data.dig(:contact_subscription_id).to_i,
          triggeraction_id:        self.id,
          contact_visit_id:        contact_campaign.data.dig(:contact_visit_id).to_i,
          user_id:                 contact.user_id
        )
      else
        Users::SendPushOrTextJob.perform_later(
          contact_id:       contact.id,
          content:          "Trigger Action: #{self.type_name} could NOT be processed for #{self.campaign.name}. A Campaign was NOT selected. Customer: #{contact.fullname}.",
          from_phone:,
          ok2push:          contact.user.notifications.dig('campaigns', 'by_push'),
          ok2text:          contact.user.notifications.dig('campaigns', 'by_text'),
          to_phone:         contact.user.phone,
          triggeraction_id: self.id,
          user_id:          contact.user_id
        )
      end
    end

    contact.triggeraction_complete(triggeraction: self, contact_campaign:)
  end

  # 250 start an AI Agent Session
  # triggeraction.fire_triggeraction_250()
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  #   (req) common_args:      (Hash)
  def fire_triggeraction_250(contact:, contact_campaign:, common_args:, **_args)
    run_at_time = AcceptableTime.new(common_args).new_time(common_args[:start_time].in_time_zone(common_args[:time_zone]))

    if run_at_time.present? && (agent = trigger.campaign.client.aiagents.find_by(id: self.aiagent_id))
      send_to = self.send_to.present? ? self.send_to.split('_') : ['']
      data = {
        aiagent_id:          agent.id,
        contact_campaign_id: contact_campaign.id,
        from_phone:          self.fire_from_phone(contact),
        to_label:            send_to[1] || '',
        triggeraction_id:    self.id
      }
      contact.delay(
        run_at:              run_at_time.utc,
        priority:            DelayedJob.job_priority('aiagent_start_session'),
        queue:               DelayedJob.job_queue('aiagent_start_session'),
        process:             'aiagent_start_session',
        contact_id:          contact.id,
        user_id:             contact.user_id,
        triggeraction_id:    self.id,
        contact_campaign_id: contact_campaign.id,
        data:
      ).aiagent_start_session_from_triggeraction(data)
    end

    contact.triggeraction_complete(triggeraction: self, contact_campaign:)
  end

  # 300 apply a Tag
  # triggeraction.fire_triggeraction_300()
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  #   (req) common_args:      (Hash)
  def fire_triggeraction_300(contact:, contact_campaign:, common_args:, **_args)
    from_phone = self.fire_from_phone(contact)
    common_args.delete(:holidays)
    run_at_time = AcceptableTime.new(common_args).new_time(common_args[:start_time].in_time_zone(common_args[:time_zone]))

    if run_at_time.present?

      if self.tag_id.positive?
        Contacts::Tags::ApplyJob.set(wait_until: run_at_time.utc).perform_later(
          contact_id:          contact.id,
          user_id:             contact.user_id,
          triggeraction_id:    self.id,
          contact_campaign_id: contact_campaign.id,
          tag_id:              self.tag_id
        )
      else
        Users::SendPushOrTextJob.perform_later(
          contact_id:       contact.id,
          content:          "Trigger: #{self.trigger.data[:name]} could NOT be processed for #{self.campaign.name}. A Tag was NOT selected. Customer: #{contact.fullname}.",
          from_phone:,
          ok2push:          contact.user.notifications.dig('campaigns', 'by_push'),
          ok2text:          contact.user.notifications.dig('campaigns', 'by_text'),
          to_phone:         contact.user.phone,
          triggeraction_id: self.id,
          user_id:          contact.user_id
        )
      end
    end

    contact.triggeraction_complete(triggeraction: self, contact_campaign:)
  end

  # 305 remove a Tag
  # triggeraction.fire_triggeraction_305()
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  #   (req) common_args:      (Hash)
  def fire_triggeraction_305(contact:, contact_campaign:, common_args:, **_args)
    from_phone = self.fire_from_phone(contact)
    common_args.delete(:holidays)
    run_at_time = AcceptableTime.new(common_args).new_time(common_args[:start_time].in_time_zone(common_args[:time_zone]))

    if run_at_time.present?

      if self.tag_id.positive?
        Contacts::Tags::RemoveJob.set(wait_until: run_at_time.utc).perform_later(
          contact_campaign_id: contact_campaign.id,
          contact_id:          contact.id,
          tag_id:              self.tag_id,
          triggeraction_id:    self.id,
          user_id:             contact.user_id
        )
      else
        Users::SendPushOrTextJob.perform_later(
          contact_id:       contact.id,
          content:          "Trigger: #{self.trigger.data[:name]} could NOT be processed for #{self.campaign.name}. A Tag was NOT selected. Customer: #{contact.fullname}.",
          from_phone:,
          ok2push:          contact.user.notifications.dig('campaigns', 'by_push'),
          ok2text:          contact.user.notifications.dig('campaigns', 'by_text'),
          to_phone:         contact.user.phone,
          triggeraction_id: self.id,
          user_id:          contact.user_id
        )
      end
    end

    contact.triggeraction_complete(triggeraction: self, contact_campaign:)
  end

  # 340 add a Contact to a Stage
  # triggeraction.fire_triggeraction_340()
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  #   (req) common_args:      (Hash)
  def fire_triggeraction_340(contact:, contact_campaign:, common_args:, **_args)
    from_phone = self.fire_from_phone(contact)
    common_args.delete(:holidays)
    run_at_time = AcceptableTime.new(common_args).new_time(common_args[:start_time].in_time_zone(common_args[:time_zone]))

    if run_at_time.present?

      if self.stage_id.to_i.positive?
        Contacts::Stages::AddJob.set(wait_until: run_at_time.utc).perform_later(
          client_id:           contact.client_id,
          contact_campaign_id: contact_campaign.id,
          contact_id:          contact.id,
          stage_id:            self.stage_id,
          triggeraction_id:    id,
          user_id:             contact.user_id
        )
      else
        Users::SendPushOrTextJob.perform_later(
          contact_id:       contact.id,
          content:          "Trigger: #{self.trigger.data[:name]} could NOT be processed for #{self.campaign.name}. A Stage was NOT selected. Customer: #{contact.fullname}.",
          from_phone:,
          ok2push:          contact.user.notifications.dig('campaigns', 'by_push'),
          ok2text:          contact.user.notifications.dig('campaigns', 'by_text'),
          to_phone:         contact.user.phone,
          triggeraction_id: self.id,
          user_id:          contact.user_id
        )
      end
    end

    contact.triggeraction_complete(triggeraction: self, contact_campaign:)
  end

  # 345 remove a Contact from a Stage
  # triggeraction.fire_triggeraction_340()
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  #   (req) common_args:      (Hash)
  def fire_triggeraction_345(contact:, contact_campaign:, common_args:, **_args)
    common_args.delete(:holidays)
    run_at_time = AcceptableTime.new(common_args).new_time(common_args[:start_time].in_time_zone(common_args[:time_zone]))

    if run_at_time.present?
      Contacts::Stages::RemoveJob.set(wait_until: run_at_time.utc).perform_later(
        contact_campaign_id: contact_campaign.id,
        contact_id:          contact.id,
        stage_id:            self.stage_id,
        triggeraction_id:    self.id,
        user_id:             contact.user_id
      )
    end

    contact.triggeraction_complete(triggeraction: self, contact_campaign:)
  end

  # 350 add to Group
  # triggeraction.fire_triggeraction_350()
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  #   (req) common_args:      (Hash)
  def fire_triggeraction_350(contact:, contact_campaign:, common_args:, **_args)
    from_phone = self.fire_from_phone(contact)
    common_args.delete(:holidays)
    run_at_time = AcceptableTime.new(common_args).new_time(common_args[:start_time].in_time_zone(common_args[:time_zone]))

    if run_at_time.present?

      if self.group_id.positive?
        Contacts::Groups::AddJob.set(wait_until: run_at_time.utc).perform_later(
          contact_campaign_id: contact_campaign.id,
          contact_id:          contact.id,
          group_id:            self.group_id,
          triggeraction_id:    self.id,
          user_id:             contact.user_id
        )
      else
        Users::SendPushOrTextJob.perform_later(
          contact_id:       contact.id,
          content:          "Trigger: #{self.trigger.data[:name]} could NOT be processed for #{self.campaign.name}. A Group was NOT selected. Customer: #{contact.fullname}.",
          from_phone:,
          ok2push:          contact.user.notifications.dig('campaigns', 'by_push'),
          ok2text:          contact.user.notifications.dig('campaigns', 'by_text'),
          to_phone:         contact.user.phone,
          triggeraction_id: self.id,
          user_id:          contact.user_id
        )
      end
    end

    contact.triggeraction_complete(triggeraction: self, contact_campaign:)
  end

  # 355 remove from a Group
  # triggeraction.fire_triggeraction_355()
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  #   (req) common_args:      (Hash)
  def fire_triggeraction_355(contact:, contact_campaign:, common_args:, **_args)
    common_args.delete(:holidays)
    run_at_time = AcceptableTime.new(common_args).new_time(common_args[:start_time].in_time_zone(common_args[:time_zone]))

    if run_at_time.present?
      Contacts::Groups::RemoveJob.set(wait_until: run_at_time.utc).perform_later(
        contact_campaign_id: contact_campaign.id,
        contact_id:          contact.id,
        group_id:            self.group_id,
        triggeraction_id:    self.id,
        user_id:             contact.user_id
      )
    end

    contact.triggeraction_complete(triggeraction: self, contact_campaign:)
  end

  # 360 assign a Lead Source
  # triggeraction.fire_triggeraction_360()
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  #   (req) common_args:      (Hash)
  def fire_triggeraction_360(contact:, contact_campaign:, common_args:, **_args)
    from_phone = self.fire_from_phone(contact)
    common_args.delete(:holidays)
    run_at_time = AcceptableTime.new(common_args).new_time(common_args[:start_time].in_time_zone(common_args[:time_zone]))

    if run_at_time.present?

      if self.lead_source_id.nil?
        Users::SendPushOrTextJob.perform_later(
          contact_id:       contact.id,
          content:          "Trigger: #{self.trigger.data[:name]} could NOT be processed for #{self.campaign.name}. A Lead Source was NOT selected. Customer: #{contact.fullname}.",
          from_phone:,
          ok2push:          contact.user.notifications.dig('campaigns', 'by_push'),
          ok2text:          contact.user.notifications.dig('campaigns', 'by_text'),
          to_phone:         contact.user.phone,
          triggeraction_id: self.id,
          user_id:          contact.user_id
        )
      else
        Contacts::LeadSources::AssignJob.set(wait_until: run_at_time.utc).perform_later(
          contact_campaign_id: contact_campaign.id,
          contact_id:          contact.id,
          lead_source_id:      self.lead_source_id,
          triggeraction_id:    self.id,
          user_id:             contact.user_id
        )
      end
    end

    contact.triggeraction_complete(triggeraction: self, contact_campaign:)
  end

  # 400 stop a Campaign
  # triggeraction.fire_triggeraction_400()
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  #   (req) common_args:      (Hash)
  def fire_triggeraction_400(contact:, contact_campaign:, common_args:, **_args)
    from_phone = self.fire_from_phone(contact)
    common_args.delete(:holidays)
    run_at_time = AcceptableTime.new(common_args).new_time(common_args[:start_time].in_time_zone(common_args[:time_zone]))

    if run_at_time.present?

      if self.campaign_id.present?
        Contacts::Campaigns::StopJob.set(wait_until: run_at_time.utc + 20.seconds).perform_later(
          campaign_id:                    self.campaign_id,
          contact_campaign_id:            contact_campaign.id,
          contact_id:                     contact.id,
          keep_triggeraction_ids:         self.id,
          limit_to_estimate_job_visit_id: self.job_estimate_id,
          multi_stop:                     self.description,
          triggeraction_id:               self.id,
          user_id:                        contact.user_id
        )
      else
        Users::SendPushOrTextJob.perform_later(
          contact_id:       contact.id,
          content:          "Trigger: #{self.trigger.data[:name]} could NOT be processed for #{self.campaign.name}. A Campaign was NOT selected. Customer: #{contact.fullname}.",
          from_phone:,
          ok2push:          contact.user.notifications.dig('campaigns', 'by_push'),
          ok2text:          contact.user.notifications.dig('campaigns', 'by_text'),
          to_phone:         contact.user.phone,
          triggeraction_id: id,
          user_id:          contact.user_id
        )
      end
    end

    contact.triggeraction_complete(triggeraction: self, contact_campaign:)
  end

  # 450 stop an AI Agent Conversation
  # triggeraction.fire_triggeraction_450()
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  def fire_triggeraction_450(contact:, contact_campaign:, **_args)
    contact.stop_aiagents
    contact.triggeraction_complete(triggeraction: self, contact_campaign:)
  end

  # (500) turn ok2text ON
  # triggeraction.fire_triggeraction_500()
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  def fire_triggeraction_500(contact:, contact_campaign:, **_args)
    contact.ok2text_on
    contact.triggeraction_complete(triggeraction: self, contact_campaign:)
  end

  # (501) turn ok2email ON
  # triggeraction.fire_triggeraction_501()
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  def fire_triggeraction_501(contact:, contact_campaign:, **_args)
    contact.ok2email_on
    contact.triggeraction_complete(triggeraction: self, contact_campaign:)
  end

  # 505 turn ok2text off
  # triggeraction.fire_triggeraction_505()
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  #   (req) common_args:      (Hash)
  def fire_triggeraction_505(contact:, contact_campaign:, common_args:, **_args)
    common_args.delete(:holidays)
    run_at_time = AcceptableTime.new(common_args).new_time(common_args[:start_time].in_time_zone(common_args[:time_zone]))

    if run_at_time.present?
      contact.delay(
        run_at:              run_at_time.utc,
        priority:            DelayedJob.job_priority('ok_to_text_off'),
        queue:               DelayedJob.job_queue('ok_to_text_off'),
        process:             'ok_to_text_off',
        contact_id:          contact.id,
        user_id:             contact.user_id,
        contact_campaign_id: contact_campaign.id,
        triggeraction_id:    self.id
      ).ok2text_off
    end

    contact.triggeraction_complete(triggeraction: self, contact_campaign:)
  end

  # 506 turn ok2email off
  # triggeraction.fire_triggeraction_506()
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  #   (req) common_args:      (Hash)
  def fire_triggeraction_506(contact:, contact_campaign:, common_args:, **_args)
    common_args.delete(:holidays)
    run_at_time = AcceptableTime.new(common_args).new_time(common_args[:start_time].in_time_zone(common_args[:time_zone]))

    if run_at_time.present?
      contact.delay(
        run_at:              run_at_time.utc,
        priority:            DelayedJob.job_priority('ok2email_off'),
        queue:               DelayedJob.job_queue('ok2email_off'),
        process:             'ok2email_off',
        contact_id:          contact.id,
        user_id:             contact.user_id,
        triggeraction_id:    self.id,
        contact_campaign_id: contact_campaign.id
      ).ok2email_off
    end

    contact.triggeraction_complete(triggeraction: self, contact_campaign:)
  end

  # 510 assign Contact to a User
  # triggeraction.fire_triggeraction_510()
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  def fire_triggeraction_510(contact:, contact_campaign:, **_args)
    from_phone = self.fire_from_phone(contact)

    if self.assign_to.present?
      # assign a User in round robin fashion
      distribution       = self.distribution.presence || self.assign_to&.keys&.index_with { |_k| 0 }
      total_distribution = self.distribution.values.sum.to_f
      distributed        = false
      new_user_id        = contact.user_id

      self.assign_to.each do |org_user, percentage|
        # scan through all Users
        distribution[org_user] = 0 unless distribution.include?(org_user)

        if !distributed && distribution[org_user] <= (total_distribution * (percentage.to_f / 100))
          # User has received less than percentage defined
          org_user_split = org_user.split('_')

          if org_user_split[0] == 'user' && org_user_split.length == 2 && contact.client.users.find_by(id: org_user_split[1].to_i)
            new_user_id             = org_user_split[1].to_i
            distribution[org_user] += 1
            distributed             = true
          elsif org_user_split[0] == 'orgposition' && org_user_split.length == 2 && (current_orguser = contact.client.org_users.find_by(user_id: contact.user_id))

            if (new_orguser = contact.client.org_users.find_by(org_group: current_orguser.org_group, org_position_id: org_user_split[1].to_i))

              if new_orguser.user_id.positive?
                new_user_id             = new_orguser.user_id
                distribution[org_user] += 1
                distributed             = true
              else
                Users::SendPushOrTextJob.perform_later(
                  content:          "Organizational position: #{new_orguser.org_position.title} could NOT be assigned for #{self.campaign.name}. Organizational position is NOT held by a User. Customer: #{contact.fullname}.",
                  contact_id:       contact.id,
                  triggeraction_id: self.id,
                  user_id:          contact.user_id
                )
              end
            end
          end
        end
      end

      contact.assign_user(new_user_id)
      self.update(distribution:)
    else
      Users::SendPushOrTextJob.perform_later(
        contact_id:       contact.id,
        content:          "Trigger: #{self.trigger.data[:name]} could NOT be processed for #{self.campaign.name}. User(s) were NOT selected. Customer: #{contact.fullname}.",
        from_phone:,
        ok2push:          contact.user.notifications.dig('campaigns', 'by_push'),
        ok2text:          contact.user.notifications.dig('campaigns', 'by_text'),
        to_phone:         contact.user.phone,
        triggeraction_id: self.id,
        user_id:          contact.user_id
      )
    end

    contact.triggeraction_complete(triggeraction: self, contact_campaign:)
  end

  # 600 parse text message response
  # triggeraction.fire_triggeraction_600()
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  #   (req) message:          (Messages::Message)
  def fire_triggeraction_600(contact:, contact_campaign:, **args)
    message = args.dig(:message)

    if message.is_a?(Messages::Message) && self.parse_string_and_update_field(
      contact:,
      message:,
      contact_campaign:
    )
      contact.triggeraction_complete(triggeraction: self, contact_campaign:)
      true
    else
      # text received could not be parsed / set Trigger to restart

      if (triggeractions = Triggeraction.where(trigger_id: self.trigger_id).pluck(:id)).present?

        contact_campaign.contact_campaign_triggeractions.where(triggeraction_id: triggeractions).find_each do |contact_campaign_triggeraction|
          if (delayed_job = contact.delayed_jobs.find_by(contact_campaign_id: contact_campaign_triggeraction.contact_campaign_id, triggeraction_id: contact_campaign_triggeraction.triggeraction_id))
            delayed_job.destroy
          end
        end
      end

      false
    end
  end

  # 605 process/act on a Contact custom field
  # triggeraction.fire_triggeraction_605()
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  #   (req) common_args:      (Hash)
  def fire_triggeraction_605(contact:, contact_campaign:, common_args:, **_args)
    from_phone = self.fire_from_phone(contact)
    common_args.delete(:holidays)
    run_at_time = AcceptableTime.new(common_args).new_time(common_args[:start_time].in_time_zone(common_args[:time_zone]))

    if run_at_time.present?

      if self.client_custom_field_id.positive?

        data = {
          client_custom_field_id:  self.client_custom_field_id,
          contact_estimate_id:     contact_campaign.data.dig(:contact_estimate_id).to_i,
          contact_invoice_id:      contact_campaign.data.dig(:contact_invoice_id).to_i,
          contact_job_id:          contact_campaign.data.dig(:contact_job_id).to_i,
          contact_subscription_id: contact_campaign.data.dig(:contact_subscription_id).to_i,
          contact_visit_id:        contact_campaign.data.dig(:contact_visit_id).to_i,
          triggeraction_id:        self.id
        }
        contact.delay(
          run_at:              run_at_time.utc + 10.seconds,
          priority:            DelayedJob.job_priority('custom_field_action'),
          queue:               DelayedJob.job_queue('custom_field_action'),
          process:             'custom_field_action',
          contact_id:          contact.id,
          user_id:             contact.user_id,
          triggeraction_id:    self.id,
          contact_campaign_id: contact_campaign.id,
          data:
        ).custom_field_action(data)
      else
        Users::SendPushOrTextJob.perform_later(
          contact_id:       contact.id,
          content:          "Trigger: #{self.trigger.data[:name]} could NOT be processed for #{self.campaign.name}. Custom field was NOT selected. Customer: #{contact.fullname}.",
          from_phone:,
          ok2push:          contact.user.notifications.dig('campaigns', 'by_push'),
          ok2text:          contact.user.notifications.dig('campaigns', 'by_text'),
          to_phone:         contact.user.phone,
          triggeraction_id: self.id,
          user_id:          contact.user_id
        )
      end
    end

    contact.triggeraction_complete(triggeraction: self, contact_campaign:)
  end

  # 610 save data to a Contact or ContactCustomField
  # triggeraction.fire_triggeraction_610()
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  #   (req) common_args:      (Hash)
  def fire_triggeraction_610(contact:, contact_campaign:, common_args:, **_args)
    from_phone = self.fire_from_phone(contact)
    common_args.delete(:holidays)
    run_at_time = AcceptableTime.new(common_args).new_time(common_args[:start_time].in_time_zone(common_args[:time_zone]))

    if run_at_time.present?

      if self.client_custom_field_id.empty?
        Users::SendPushOrTextJob.perform_later(
          contact_id:       contact.id,
          content:          "Trigger: #{self.trigger.data[:name]} could NOT be processed for #{self.campaign.name}. Contact info was NOT selected. Customer: #{contact.fullname}.",
          from_phone:,
          ok2push:          contact.user.notifications.dig('campaigns', 'by_push'),
          ok2text:          contact.user.notifications.dig('campaigns', 'by_text'),
          to_phone:         contact.user.phone,
          triggeraction_id: self.id,
          user_id:          contact.user_id
        )
      elsif self.description.empty?
        Users::SendPushOrTextJob.perform_later(
          contact_id:       contact.id,
          content:          "Trigger: #{self.trigger.data[:name]} could NOT be processed for #{self.campaign.name}. Contact info was NOT entered. Customer: #{contact.fullname}.",
          from_phone:,
          ok2push:          contact.user.notifications.dig('campaigns', 'by_push'),
          ok2text:          contact.user.notifications.dig('campaigns', 'by_text'),
          to_phone:         contact.user.phone,
          triggeraction_id: self.id,
          user_id:          contact.user_id
        )
      else
        internal_fields       = ::Webhook.internal_key_hash(contact.client, 'contact', %w[personal ext_references]).keys
        custom_field_keys     = contact.client.client_custom_fields.pluck(:id)
        contact_data          = {}
        phone_number          = []
        contact_custom_fields = {}

        if internal_fields.include?(self.client_custom_field_id)

          if self.client_custom_field_id == 'fullname'
            fullname = self.description.to_s.parse_name
            contact_data[:firstname] = fullname[:firstname]
            contact_data[:lastname] = fullname[:lastname]
          else
            contact_data[self.client_custom_field_id.to_sym] = self.description
          end
        elsif custom_field_keys.include?(self.client_custom_field_id.to_i)
          contact_custom_fields[self.client_custom_field_id] = self.description
        elsif self.client_custom_field_id.include?('phone_')
          phone_number = [self.description.clean_phone(contact.client.primary_area_code), self.client_custom_field_id.gsub('phone_', '')]
        elsif %w[ok2text ok2email].include?(self.client_custom_field_id)
          contact_data[self.client_custom_field_id.to_sym] = self.description.is_yes? ? 1 : 0
        end

        if phone_number.present?
          data = {
            contact_id: contact.id,
            label:      phone_number[1],
            phone:      phone_number[0]
          }
          ContactPhone.delay(
            run_at:              run_at_time.utc + 10.seconds,
            priority:            DelayedJob.job_priority('update_contact_info'),
            queue:               DelayedJob.job_queue('update_contact_info'),
            process:             'update_contact_info',
            contact_id:          contact.id,
            user_id:             contact.user_id,
            triggeraction_id:    self.id,
            contact_campaign_id: contact_campaign.id,
            data:
          ).find_or_create_by(data)
        elsif contact_custom_fields.present?
          data = {
            contact_campaign_id: contact_campaign.id,
            custom_fields:       contact_custom_fields,
            triggeraction_id:    self.id
          }
          contact.delay(
            run_at:              run_at_time.utc + 10.seconds,
            priority:            DelayedJob.job_priority('update_contact_info'),
            queue:               DelayedJob.job_queue('update_contact_info'),
            process:             'update_contact_info',
            contact_id:          contact.id,
            user_id:             contact.user_id,
            triggeraction_id:    self.id,
            contact_campaign_id: contact_campaign.id,
            data:
          ).update_custom_fields(data)
        elsif contact_data.present?
          contact.delay(
            run_at:              run_at_time.utc + 10.seconds,
            priority:            DelayedJob.job_priority('update_contact_info'),
            queue:               DelayedJob.job_queue('update_contact_info'),
            process:             'update_contact_info',
            contact_id:          contact.id,
            user_id:             contact.user_id,
            triggeraction_id:    self.id,
            contact_campaign_id: contact_campaign.id,
            data:                contact_data
          ).update(contact_data)
        end
      end
    end

    contact.triggeraction_complete(triggeraction: self, contact_campaign:)
  end

  # (615) save Contacts::Note to a Contact
  # triggeraction.fire_triggeraction_615()
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  #   (req) common_args:      (Hash)
  def fire_triggeraction_615(contact:, contact_campaign:, common_args:, **_args)
    run_at_time = AcceptableTime.new(common_args).new_time(common_args[:start_time].in_time_zone(common_args[:time_zone]))

    if run_at_time.present?
      Contacts::Notes::NewJob.set(wait_until: run_at_time).perform_later(
        contact_id:          contact.id,
        contact_campaign_id: contact_campaign.id,
        note:,
        user_id:
      )
    end

    contact.triggeraction_complete(triggeraction: self, contact_campaign:)
  end

  # 700 create a Task
  # triggeraction.fire_triggeraction_700()
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  #   (req) common_args:      (Hash)
  def fire_triggeraction_700(contact:, contact_campaign:, common_args:, **_args)
    from_phone = self.fire_from_phone(contact)
    common_args.delete(:holidays)
    run_at_time = AcceptableTime.new(common_args).new_time(common_args[:start_time].in_time_zone(common_args[:time_zone]))

    if run_at_time.present?
      data = {
        assign_to:           self.assign_to,
        campaign_id:         self.campaign_id,
        cancel_after:        self.cancel_after,
        contact_campaign_id: contact_campaign.id,
        contact_id:          contact.id,
        description:         self.description,
        dead_delay_days:     self.dead_delay_days,
        dead_delay_hours:    self.dead_delay_hours,
        dead_delay_minutes:  self.dead_delay_minutes,
        due_delay_days:      self.due_delay_days,
        due_delay_hours:     self.due_delay_hours,
        due_delay_minutes:   self.due_delay_minutes,
        from_phone:,
        name:,
        triggeraction_id:    self.id
      }
      Task.delay(
        run_at:              run_at_time.utc,
        priority:            DelayedJob.job_priority('create_new_task'),
        queue:               DelayedJob.job_queue('create_new_task'),
        process:             'create_new_task',
        contact_id:          contact.id,
        user_id:             contact.user_id,
        triggeraction_id:    self.id,
        contact_campaign_id: contact_campaign.id,
        data:
      ).create_new(data)
    end

    contact.triggeraction_complete(triggeraction: self, contact_campaign:)
  end

  # 750 call Contact
  # triggeraction.fire_triggeraction_750()
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  #   (req) common_args:      (Hash)
  def fire_triggeraction_750(contact:, contact_campaign:, common_args:, **_args)
    from_phone = self.fire_from_phone(contact)
    common_args.delete(:holidays)
    run_at_time = AcceptableTime.new(common_args).new_time(common_args[:start_time].in_time_zone(common_args[:time_zone]))

    if run_at_time.present?

      if self.user_id.present? && self.send_to.present? &&
         contact.org_users(users_orgs: self.user_id, purpose: 'voice', default_to_all_users_in_org_position: false).present? &&
         contact.org_users(users_orgs: self.send_to, purpose: 'voice', default_to_all_users_in_org_position: false).present?

        contact_campaign.data[:triggeractions] = {} unless contact_campaign.data.include?(:triggeractions)
        contact_campaign.data[:triggeractions][self.id] = {
          from_users_orgs:     self.user_id,
          to_users_orgs:       self.send_to,
          from_phone:,
          retry_count:         self.retry_count,
          retry_interval:      self.retry_interval,
          stop_on_connection:  self.stop_on_connection,
          machine_detection:   true,
          current_retry_count: 0,
          priority:            5,
          process:             'call_contact'
        }

        contact_campaign.save

        data = {
          users_orgs:          self.user_id,
          from_phone:,
          machine_detection:   true,
          contact_campaign_id: contact_campaign.id,
          triggeraction_id:    self.id
        }
        contact.delay(
          run_at:              run_at_time.utc,
          priority:            DelayedJob.job_priority('call_contact'),
          queue:               DelayedJob.job_queue('call_contact'),
          process:             'call_contact',
          contact_id:          contact.id,
          user_id:             contact.user_id,
          triggeraction_id:    self.id,
          contact_campaign_id: contact_campaign.id,
          data:
        ).call(data)
      else
        Users::SendPushOrTextJob.perform_later(
          contact_id:       contact.id,
          content:          "Trigger: #{self.trigger.data[:name]} could NOT be processed for #{self.campaign.name}. Incomplete action configuration. Customer: #{contact.fullname}.",
          from_phone:,
          ok2push:          contact.user.notifications.dig('campaigns', 'by_push'),
          ok2text:          contact.user.notifications.dig('campaigns', 'by_text'),
          to_phone:         contact.user.phone,
          triggeraction_id: self.id,
          user_id:          contact.user_id
        )
      end
    end

    contact.triggeraction_complete(triggeraction: self, contact_campaign:)
  end

  # 800 create a Client
  # triggeraction.fire_triggeraction_800()
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  def fire_triggeraction_800(contact:, contact_campaign:, **_args)
    if self.client_name_custom_field_id.positive? && self.client_package_id.positive?

      ### find the Upflow ClientCustomField and convert the ContactCustomField id to the Upflow ClientCustomField id
      if (upflow_client_custom_field = User.find_by(email: 'kevin@fieldcontrolpro.com').client.client_custom_fields.find_by(id: self.client_name_custom_field_id)) && (chiirp_client_custom_field = contact.client.client_custom_fields.find_by(var_var: upflow_client_custom_field.var_var)) && (contact_custom_field = contact.contact_custom_fields.find_by(client_custom_field_id: chiirp_client_custom_field.id))
        contact.update(client_id: User.find_by(email: 'kevin@fieldcontrolpro.com').client.id, user_id: User.find_by(email: 'kevin@fieldcontrolpro.com').client.def_user_id)
        contact.reload # loads the correct Client
        contact_custom_field.update(client_custom_field_id: upflow_client_custom_field.id)
        contact_custom_field.reload # loads the correct ClientCustomField
      end

      # ClientCustomField & Package are defined
      contact_custom_field = contact.contact_custom_fields.find_by(client_custom_field_id: self.client_name_custom_field_id)

      # find Package
      package = Package.find_by(tenant: 'upflow', id: self.client_package_id)

      # find PackagePage
      package_page = package ? PackagePage.where(package_01_id: package.id).or(PackagePage.where(package_02_id: package.id)).or(PackagePage.where(package_03_id: package.id)).or(PackagePage.where(package_04_id: package.id)).first : nil

      # find KEY_USER
      key_user = User.find_by(email: 'kevin@fieldcontrolpro.com') || nil

      if contact_custom_field && contact_custom_field.var_value.length.positive? && package && key_user
        # ContactCustomField & Package & KEY_USER are valid

        new_client = Client.create(
          name:        contact_custom_field.var_value,
          address1:    contact.address1,
          address2:    contact.address2,
          city:        contact.city,
          state:       contact.state,
          zip:         contact.zipcode,
          phone:       contact.primary_phone&.phone.to_s,
          time_zone:   contact.client.time_zone,
          def_user_id: key_user.id,
          tenant:      contact.client.tenant
        )

        if new_client
          # Client was created
          new_client.update(contact_id: contact.id)
          new_client.update_package_settings(package_page:, package:)

          # initialize new User
          new_user = new_client.users.create(
            firstname:                contact.firstname,
            lastname:                 contact.lastname,
            phone:                    contact.primary_phone&.phone.to_s,
            email:                    contact.email,
            skip_password_validation: true
          )

          if new_user
            # User was created
            new_client.update(def_user_id: new_user.id)

            # add credits to Client account
            if (new_client.first_payment_delay_days + new_client.first_payment_delay_months).zero?
              # monthly credits
              new_client.add_credits({ credits_amt: new_client.current_mo_credits.to_d })
            else
              # trial credits
              new_client.add_credits({ credits_amt: new_client.trial_credits.to_d })
            end

            # send User login invitation
            I18n.with_locale('upflow') do
              ActionMailer::Base.default_url_options[:domain] = 'fieldcontrolpro.com'
              new_user.invite!(key_user)

              delay_data = {
                content:   "#{I18n.t('devise.text.invitation_instructions.hello').gsub('%{firstname}', new_user.firstname)} - #{I18n.t('devise.text.invitation_instructions.someone_invited_you')} #{I18n.t('devise.text.invitation_instructions.accept')} #{accept_user_invitation_url(invitation_token: new_user.raw_invitation_token)}",
                automated: true,
                msg_type:  'textoutuser'
              }
              new_user.delay(
                run_at:   Time.current,
                priority: DelayedJob.job_priority('send_text'),
                queue:    DelayedJob.job_queue('send_text'),
                process:  'send_text',
                user_id:  new_user.id,
                data:     delay_data
              ).send_text(delay_data)
            end

            # import Campaigns/CampaignGroups
            package.package_campaigns.find_each do |package_campaign|
              begin
                if package_campaign.campaign_id
                  package_campaign.campaign.copy(new_client_id: new_client.id)
                elsif package_campaign.campaign_group_id
                  package_campaign.campaign_group.copy(new_client_id: new_client.id)
                end
              rescue StandardError => e
                if package_campaign.campaign_id
                  campaign_id         = package_campaign.campaign_id
                  campaign_name       = package_campaign.campaign.name
                  campaign_group_id   = 0
                  campaign_group_name = ''
                elsif package_campaign.campaign_group_id
                  campaign_id         = 0
                  campaign_name       = ''
                  campaign_group_id   = package_campaign.campaign_group_id
                  campaign_group_name = package_campaign.campaign_group.name
                end

                e.set_backtrace(BC.new.clean(caller))

                Appsignal.report_error(e) do |transaction|
                  # Only needed if it needs to be different or there's no active transaction from which to inherit it
                  Appsignal.set_action('Triggeraction.fire_triggeraction_800')

                  # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
                  Appsignal.add_params({ contact:, contact_campaign: })

                  Appsignal.set_tags(
                    error_level: 'error',
                    error_code:  0
                  )
                  Appsignal.add_custom_data(
                    new_client:          "#{new_client.name} (#{new_client.id})",
                    package:             "#{package.name} (#{package.id})",
                    package_campaign_id: package_campaign.id,
                    campaign:            "#{campaign_name} (#{campaign_id})",
                    campaign_group:      "#{campaign_group_name} (#{campaign_group_id})",
                    file:                __FILE__,
                    line:                __LINE__
                  )
                end

                next
              end
            end

            contact.process_actions(
              campaign_id:       package&.campaign_id,
              group_id:          package&.group_id,
              stage_id:          package&.stage_id,
              tag_id:            package&.tag_id,
              stop_campaign_ids: package&.stop_campaign_ids
            )
          end
        end
      end
    end

    contact.triggeraction_complete(triggeraction: self, contact_campaign:)
  end

  # 801 Push Contact to Client
  # triggeraction.fire_triggeraction_801()
  # clients: [{ client_id: integer, client_campaign_id: integer, agency_campaign_id: integer, max_monthly_leads: integer, leads_this_month: integer, period_start_date: DateTime.iso8601 }]
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  def fire_triggeraction_801(contact:, contact_campaign:, **_args)
    clients_ta_hash       = self.clients
    expected_distribution = {}
    current_progression   = {}

    # update period_end_dates
    clients_ta_hash.each do |client_ta_hash|
      if (client = Client.by_agency(self.campaign.client_id).find_by(id: client_ta_hash['client_id']))

        if client.next_pmt_date.to_time.in_time_zone(client.time_zone) > client_ta_hash['period_end_date'].in_time_zone(client.time_zone)
          client_ta_hash['period_end_date'] = client.next_pmt_date.to_time.in_time_zone(client.time_zone).utc.iso8601
          client_ta_hash['leads_this_month'] = 0
        end

        # (elapsed days since period_start_date / 30) * max_monthly_leads
        expected_distribution[client.id] = [(((((30 * 24 * 60 * 60) - (Chronic.parse(client_ta_hash['period_end_date']) - Time.current.end_of_day)) / (24 * 60 * 60)).round.to_f / 30) * client_ta_hash['max_monthly_leads']).to_f.round, client_ta_hash['max_monthly_leads']].min
        # (leads_this_month / expected_distribution)
        current_progression[client.id]   = expected_distribution[client.id].zero? ? 0 : client_ta_hash['leads_this_month'] / expected_distribution[client.id].to_f

        self.update(clients: clients_ta_hash)
      end
    end

    # lowest current_progression
    selected_progression  = current_progression.find { |_key, value| value == current_progression.values.min }
    selected_client       = selected_progression.blank? ? nil : self.clients.find { |client| client['client_id'] == selected_progression[0] }

    if selected_client && (client = Client.by_agency(self.campaign.client_id).find_by(id: selected_client['client_id']))
      new_contact = contact.dup
      new_contact.client_id           = client.id
      new_contact.user_id             = client.def_user_id
      new_contact.group_id            = 0
      new_contact.group_id_updated_at = nil

      if new_contact.save
        contact.contact_phones.each do |contact_phone|
          new_contact_phone = contact_phone.dup
          new_contact_phone.contact_id = new_contact.id
          new_contact_phone.save
        end

        if selected_client['client_campaign_id'].positive?
          Contacts::Campaigns::StartJob.perform_later(
            campaign_id:         selected_client['client_campaign_id'],
            client_id:           new_contact.client_id,
            contact_campaign_id: contact_campaign.id,
            contact_id:          new_contact.id,
            triggeraction_id:    self.id,
            user_id:             new_contact.user_id
          )
        end

        if selected_client['agency_campaign_id'].positive?
          Contacts::Campaigns::StartJob.perform_later(
            campaign_id:         selected_client['agency_campaign_id'],
            client_id:           contact.client_id,
            contact_campaign_id: contact_campaign.id,
            contact_id:          contact.id,
            triggeraction_id:    self.id,
            user_id:             contact.user_id
          )
        end

        self.reload

        if (selected_client = self.clients.find { |c| c['client_id'] == selected_client['client_id'] })
          self.clients.delete(selected_client)
          selected_client['leads_this_month'] += 1
          self.clients << selected_client
          self.save
        end
      end
    end

    contact.triggeraction_complete(triggeraction: self, contact_campaign:)
  end

  # 901 Push data to PC Richard
  # triggeraction.fire_triggeraction_901()
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  def fire_triggeraction_901(contact:, contact_campaign:, **_args)
    return unless contact.client.integrations_allowed.include?('pcrichard') && (client_api_integration = contact.client.client_api_integrations.find_by(target: 'pcrichard', name: ''))

    case self.install_method
    when 'completed'
      data = {
        client_api_integration_id: client_api_integration.id,
        contact:,
        contact_campaign_id:       contact_campaign.id,
        triggeraction:             self
      }
      Integration::Pcrichard::V1::Base.new(client_api_integration).delay(
        run_at:              Time.current,
        priority:            DelayedJob.job_priority('pcrichard_processes'),
        queue:               DelayedJob.job_queue('pcrichard_processes'),
        user_id:             contact.user_id,
        contact_id:          contact.id,
        triggeraction_id:    self.id,
        contact_campaign_id: contact_campaign.id,
        group_process:       0,
        process:             'pcrichard_processes',
        data:
      ).submit_completed_to_pc_richard(data)
    when 'scheduled'
      data = {
        client_api_integration_id: client_api_integration.id,
        contact:,
        contact_campaign_id:       contact_campaign.id,
        triggeraction:             self
      }
      Integration::Pcrichard::V1::Base.new(client_api_integration).delay(
        run_at:              Time.current,
        priority:            DelayedJob.job_priority('pcrichard_processes'),
        queue:               DelayedJob.job_queue('pcrichard_processes'),
        user_id:             contact.user_id,
        contact_id:          contact.id,
        triggeraction_id:    self.id,
        contact_campaign_id: contact_campaign.id,
        group_process:       0,
        process:             'pcrichard_processes',
        data:
      ).submit_scheduled_to_pc_richard(data)
    when 'invalid_zone'
      data = {
        client_api_integration_id: client_api_integration.id,
        contact:,
        contact_campaign_id:       contact_campaign.id,
        triggeraction_id:          self.id
      }
      Integration::Pcrichard::V1::Base.new(client_api_integration).delay(
        run_at:              Time.current,
        priority:            DelayedJob.job_priority('pcrichard_processes'),
        queue:               DelayedJob.job_queue('pcrichard_processes'),
        user_id:             contact.user_id,
        contact_id:          contact.id,
        triggeraction_id:    self.id,
        contact_campaign_id: contact_campaign.id,
        group_process:       0,
        process:             'pcrichard_processes',
        data:
      ).submit_invalid_zone_to_pc_richard(data)
    end

    contact.triggeraction_complete(triggeraction: self, contact_campaign:)
  end

  # return all image urls included with a Triggeraction in a hash
  # Triggeraction.images
  def images
    attachments.empty? ? [] : trigger.campaign.client.client_attachments.where(id: attachments)
  end

  # parse text content and update appropriate Contact fields
  # triggeraction.parse_string_and_update_field()
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  #   (req) message:          (Messages::Message)
  def parse_string_and_update_field(contact:, contact_campaign:, message:, **args)
    response = true

    if contact.is_a?(Contact) && message.is_a?(Messages::Message) && contact_campaign.is_a?(Contacts::Campaign)
      content                = message.message.to_s
      client_custom_field_id = self.client_custom_field_id

      case client_custom_field_id
      when 'firstname'
        contact_name = content.parse_name
        contact.update(firstname: contact_name[:firstname])
      when 'lastname'
        contact_name = content.split.length > 1 ? content.parse_name[:lastname] : content
        contact.update(lastname: contact_name)
      when 'fullname'
        contact_name = content.parse_name
        contact.update(firstname: contact_name[:firstname], lastname: contact_name[:lastname])
      when 'address1'
        contact.update(address1: content)
      when 'address2'
        contact.update(address2: content)
      when 'city'
        contact.update(city: content)
      when 'state'
        contact.update(state: content[0, 2])
      when 'zipcode'
        contact.update(zipcode: content[0, 6])
      when 'email'
        contact.update(email: content)
      when 'brand-notes'
        Contacts::Notes::NewJob.perform_now(
          contact_id:          contact.id,
          contact_campaign_id: contact_campaign.id,
          note:                content,
          user_id:             contact.user_id
        )
      else
        client_custom_field_found = false
        string_chars              = ['', '.']

        if client_custom_field_id == 'birthdate'
          Time.zone = contact.client.time_zone
          Chronic.time_class = Time.zone
          date_field = Chronic.parse(content)

          if date_field
            contact.update(birthdate: date_field)
            client_custom_field_found = true
          end
        elsif client_custom_field_id[0, 6] == 'phone_'
          label = client_custom_field_id.gsub('phone_', '')
          phone = content.clean_phone(contact.client.primary_area_code)

          if phone.length >= 10
            contact.contact_phones.find_or_create_by(label:, phone:)
            client_custom_field_found = true
          end
        elsif (client_custom_field = contact.client.client_custom_fields.find_by(id: client_custom_field_id.to_i))

          case client_custom_field.var_type
          when 'string'

            if client_custom_field.var_options.dig(:string_options).present?
              string_options = client_custom_field.var_options.dig(:string_options).split(',')
              string_match   = if content.is_match?(string_options)
                                 content.match_in_array(string_options)
                               elsif string_options.include?('yes') && content.is_yes?
                                 'yes'
                               elsif string_options.include?('no') && content.is_no?
                                 'no'
                               else
                                 ''
                               end

              contact.update_custom_fields(custom_fields: { client_custom_field.id => string_match })
            else
              contact.update_custom_fields(custom_fields: { client_custom_field.id => content })
            end

            client_custom_field_found = true
          when 'numeric'
            numbers_received = content.split.map { |x| string_chars.include?(x.to_s.gsub(%r{[^\d.]}, '')) ? '' : x.to_s.gsub(%r{[^\d.]}, '') }.select { |x| x > '' }.map(&:to_i).sort.reverse

            if client_custom_field.var_options.include?(:numeric_min) && client_custom_field.var_options.include?(:numeric_max)

              if numbers_received.length.positive? && numbers_received[0] >= client_custom_field.var_options[:numeric_min].to_d && numbers_received[0] <= client_custom_field.var_options[:numeric_max].to_d
                contact.update_custom_fields(custom_fields: { client_custom_field.id => numbers_received[0].to_s })
                client_custom_field_found = true
              end
            elsif numbers_received.length.positive?
              contact.update_custom_fields(custom_fields: { client_custom_field.id => numbers_received[0].to_s })
              client_custom_field_found = true
            end
          when 'stars'
            numbers_received = content.split.map { |x| string_chars.include?(x.to_s.gsub(%r{[^\d.]}, '')) ? '' : x.to_s.gsub(%r{[^\d.]}, '') }.select { |x| x > '' }.map(&:to_i).sort.reverse

            if client_custom_field.var_options.include?(:stars_max)

              if numbers_received.length.positive? && numbers_received[0] >= 0 && numbers_received[0] <= client_custom_field.var_options[:stars_max].to_i
                contact.update_custom_fields(custom_fields: { client_custom_field.id => numbers_received[0].to_s })
                client_custom_field_found = true
              end
            elsif numbers_received.length.positive?
              contact.update_custom_fields(custom_fields: { client_custom_field.id => numbers_received[0].to_s })
              client_custom_field_found = true
            end
          when 'currency'
            numbers_received = content.split.map { |x| string_chars.include?(x.to_s.gsub(%r{[^\d.]}, '')) ? '' : x.to_s.gsub(%r{[^\d.]}, '') }.select { |x| x > '' }.map(&:to_d).sort.reverse

            if client_custom_field.var_options.include?(:currency_min) && client_custom_field.var_options.include?(:currency_max)

              if numbers_received.length.positive? && numbers_received[0] >= client_custom_field.var_options[:currency_min].to_d && numbers_received[0] <= client_custom_field.var_options[:currency_max].to_d
                contact.update_custom_fields(custom_fields: { client_custom_field.id => numbers_received[0].to_s })
                client_custom_field_found = true
              end
            elsif numbers_received.length.positive?
              contact.update_custom_fields(custom_fields: { client_custom_field.id => numbers_received[0].to_s })
              client_custom_field_found = true
            end
          when 'date'
            Time.zone = contact.client.time_zone
            Chronic.time_class = Time.zone
            date_field = Chronic.parse(content)

            if date_field
              contact.update_custom_fields(custom_fields: { client_custom_field.id => date_field.utc })
              client_custom_field_found = true
            end
          end

          if !client_custom_field_found && client_custom_field.image_is_valid && message.attachments.any?
            contact.update_custom_fields(custom_fields: { client_custom_field.id => '<image>' })
            client_custom_field_found = true
          end
        end

        unless client_custom_field_found
          retry_count                     = 0
          parse_text_respond              = self.parse_text_respond
          parse_text_text                 = self.parse_text_text
          parse_text_notify               = self.parse_text_notify
          clear_field_on_invalid_response = self.clear_field_on_invalid_response
          response_text                   = text_message

          if parse_text_respond && !response_text.empty?
            # text Contact with request for clarification (3 times)
            contact_campaign.update(retry_count: contact_campaign.retry_count.to_i + 1)
            retry_count = contact_campaign.retry_count

            if retry_count <= 3
              # add images to message
              image_id_array = []

              attachments.each do |client_attachment_id|
                client_attachment = trigger.campaign.client.client_attachments.find_by(id: client_attachment_id)

                if client_attachment.image.present?
                  contact_attachment = contact.contact_attachments.create!(image: Cloudinary::CarrierWave::StoredFile.new(client_attachment.image.identifier))
                  image_id_array << contact_attachment.id
                end
              end

              data = {
                automated:           true,
                contact_campaign_id: contact_campaign.id,
                content:             response_text,
                from_phone:          contact.latest_client_phonenumber(default_ok: true, phone_numbers_only: true)&.phonenumber.to_s,
                image_id_array:,
                msg_type:            if message.msg_type.to_s.include?('user')
                                       'textoutuser'
                                     else
                                       message.msg_type.to_s.include?('other') ? 'textoutother' : 'textout'
                                     end,
                to_phone:            message.from_phone,
                triggeraction_id:    self.id
              }
              contact.delay(
                run_at:              10.seconds.from_now,
                priority:            DelayedJob.job_priority('send_text'),
                queue:               DelayedJob.job_queue('send_text'),
                process:             'send_text',
                contact_id:          contact.id,
                user_id:             contact.user_id,
                triggeraction_id:    self.id,
                contact_campaign_id: contact_campaign.id,
                data:
              ).send_text(data)
            end
          end

          if parse_text_text
            # assigned User requested to be texted on an invalid response
            content_array = []
            content_array << 'Invalid Campaign response.' if !parse_text_respond || retry_count.zero?
            content_array << 'First invalid Campaign response.' if parse_text_respond && retry_count == 1
            content_array << 'Second invalid Campaign response.' if parse_text_respond && retry_count == 2
            content_array << 'Third invalid Campaign response.' if parse_text_respond && retry_count == 3
            content_array << 'Fourth invalid Campaign response. No additional attempts.' if parse_text_respond && retry_count > 3
            content_array << "Trigger: #{trigger.data[:name]} could NOT be processed for #{trigger.campaign.name}."
            content_array << "Customer: #{contact.fullname}."
            content = content_array.join(' ')

            data = {
              automated:           true,
              contact_campaign_id: contact_campaign.id,
              contact_id:          contact.id,
              content:,
              from_phone:          contact.latest_client_phonenumber(default_ok: true, phone_numbers_only: true)&.phonenumber.to_s,
              msg_type:            'textoutuser',
              triggeraction_id:    self.id
            }
            contact.user.delay(
              priority:            DelayedJob.job_priority('send_text_to_user'),
              queue:               DelayedJob.job_queue('send_text_to_user'),
              process:             'send_text_to_user',
              contact_id:          contact.id,
              user_id:             contact.user_id,
              triggeraction_id:    self.id,
              contact_campaign_id: contact_campaign.id,
              data:
            ).send_text(data)
          end

          if parse_text_notify
            # assigned User requested to be notified on an invalid response
            title_text = 'Invalid Campaign Response' if !parse_text_respond || retry_count.zero?
            title_text = 'First invalid Campaign Response' if parse_text_respond && retry_count == 1
            title_text = 'Second invalid Campaign Response' if parse_text_respond && retry_count == 2
            title_text = 'Third invalid Campaign Response' if parse_text_respond && retry_count == 3
            title_text = 'Fourth (LAST) invalid Campaign Response' if parse_text_respond && retry_count > 3
            app_host   = I18n.with_locale(contact.client.tenant) { I18n.t("tenant.#{Rails.env}.app_host") }

            Users::SendPushJob.perform_later(
              content: "Trigger: #{trigger.data[:name]} could NOT be processed for #{trigger.campaign.name}",
              tenant:  contact.client.tenant,
              title:   title_text,
              url:     Rails.application.routes.url_helpers.central_url(contact_id: contact.id, host: app_host),
              user_id: contact.user_id
            )
          end

          if !parse_text_respond || retry_count > 3
            contact.update_custom_fields(custom_fields: { client_custom_field.id => '' }) if client_custom_field && clear_field_on_invalid_response
            retry_count = 4
          end

          response = (retry_count > 3)
        end
      end
    else
      # data field was NOT received
      error = TriggeractionError.new('Invalid Arguments')
      error.set_backtrace(BC.new.clean(caller))

      Appsignal.report_error(error) do |transaction|
        # Only needed if it needs to be different or there's no active transaction from which to inherit it
        Appsignal.set_action('Triggeraction.parse_string_and_update_field')

        # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
        Appsignal.add_params({ contact:, contact_campaign:, message:, args: })

        Appsignal.set_tags(
          error_level: 'error',
          error_code:  0
        )
        Appsignal.add_custom_data(
          file: __FILE__,
          line: __LINE__
        )
      end
    end

    response
  end

  # remove reference to a Campaign that was destroyed
  # Triggeraction.references_destroyed()
  #   (req) client_id:      (Integer)
  #   (opt) campaign_id:    (Integer)
  #   (opt) group_id:       (Integer)
  #   (opt) lead_source_id: (Integer)
  #   (opt) tag_id:         (Integer)
  #   (opt) stage_id:       (Integer)
  def self.references_destroyed(**args)
    return false unless (Integer(args.dig(:client_id), exception: false) || 0).positive? &&
                        ((Integer(args.dig(:campaign_id), exception: false) || 0).positive? || (Integer(args.dig(:group_id), exception: false) || 0).positive? ||
                        (Integer(args.dig(:stage_id), exception: false) || 0).positive? || (Integer(args.dig(:tag_id), exception: false) || 0).positive? ||
                        (Integer(args.dig(:lead_source_id), exception: false) || 0).positive?)

    campaign_id    = args.dig(:campaign_id).to_i
    group_id       = args.dig(:group_id).to_i
    lead_source_id = args.dig(:lead_source_id)
    stage_id       = args.dig(:stage_id).to_i
    tag_id         = args.dig(:tag_id).to_i

    if campaign_id.positive?
      action_types = CAMPAIGN_TYPES + CUSTOM_FIELD_TYPES + TASK_TYPES - [610]
    elsif group_id.positive?
      action_types = GROUP_TYPES + CUSTOM_FIELD_TYPES - [610]
    elsif !args.dig(:lead_source_id).nil?
      action_types = LEAD_TYPES + CUSTOM_FIELD_TYPES - [610]
    elsif args.dig(:tag_id).to_i.positive?
      action_types = TAG_TYPES + CUSTOM_FIELD_TYPES - [610]
    elsif args.dig(:stage_id).to_i.positive?
      action_types = STAGE_TYPES + CUSTOM_FIELD_TYPES - [610]
    end

    self.for_client_and_action_type(args[:client_id], action_types).find_each do |triggeraction|
      case triggeraction.action_type
      when 200, 700
        # start a Campaign, create a Task
        triggeraction.campaign_id = 0 if triggeraction.campaign_id == campaign_id
      when 300, 305
        triggeraction.tag_id = 0 if triggeraction.tag_id == tag_id
      when 340, 345
        triggeraction.stage_id = 0 if triggeraction.stage_id == stage_id
      when 350, 355
        triggeraction.group_id = 0 if triggeraction.group_id == group_id
      when 360
        triggeraction.lead_source_id = nil if triggeraction.lead_source_id == lead_source_id
      when 400
        # stop a Campaign
        triggeraction.campaign_id = '' if triggeraction.campaign_id.to_i == campaign_id && %w[this all_ot group_].exclude?(triggeraction.campaign_id.to_s[0, 6])
      when 605
        # ClientCustomField action

        triggeraction.response_range&.each_value do |values|
          values['campaign_id'] = 0 if campaign_id.positive? && values.dig('campaign_id').to_i == campaign_id
          values['group_id']    = 0 if group_id.positive? && values.dig('group_id').to_i == group_id
          values['stage_id']    = 0 if stage_id.positive? && values.dig('stage_id').to_i == stage_id
          values['tag_id']      = 0 if tag_id.positive? && values.dig('tag_id').to_i == tag_id
        end
      end

      if triggeraction.changed?
        triggeraction.save
        triggeraction.trigger&.campaign&.update(analyzed: triggeraction.trigger&.campaign&.analyze!&.blank?)
      end
    end

    true
  end

  def schedule_string
    response = []

    if self.scheduled_type?
      # advance date by the delay_months
      response << "#{delay_months}M" if delay_months.positive?
      # advance date by the delay_days
      response << "#{delay_days}d" if delay_days.positive?
      # advance date by the delay_hours
      response << "#{delay_hours}h" if delay_hours.positive?
      # advance date by the delay_minutes
      response << "#{delay_minutes}m" if delay_minutes.positive?
      response << 'immediately' if response.empty?
    else
      response << 'immediately'
    end

    "(#{response.join(' ')})"
  end

  # scheduled Triggeraction?
  # self.scheduled_type?
  def scheduled_type?
    SCHEDULED_TYPES.include?(self.action_type)
  end

  def set_sequence
    # minutes in a month = (365.25 days / 12 months) = 30.4375 days/mo * 1440 minutes/day
    self.sequence = self.scheduled_type? ? (self.delay_months.to_i * 43_830) + (self.delay_days.to_i * 1_440) + (self.delay_hours.to_i * 60) + self.delay_minutes.to_i : 0
  end

  def self.type_hash(client)
    {
      0   => 'Select an Action Type',
      100 => 'Send a Text Message'
    }
      .merge(client.rvm_allowed ? { 150 => 'Send a Ringless Voicemail' } : {})
      .merge(client.send_emails? ? { 170 => 'Send an Email' } : {})
      .merge({ 171 => 'Send an Email to a User' })
      .merge(client.integrations_allowed.include?('slack') ? { 180 => 'Send a Slack Message' } : {})
      .merge(client.integrations_allowed.include?('slack') ? { 181 => 'Create a Slack Channel' } : {})
      .merge(client.integrations_allowed.include?('slack') ? { 182 => 'Add Users to a Slack Channel' } : {})
      .merge(client.campaigns_count.positive? ? { 200 => 'Start a Campaign' } : {})
      .merge(client.ai_agents? ? { 250 => 'Start an AI Agent Conversation' } : {})
      .merge({
               300 => 'Apply a Tag',
               305 => 'Remove a Tag'
             })
      .merge(client.stages_count.positive? ? { 340 => 'Add to a Stage' } : {})
      .merge(client.stages_count.positive? ? { 345 => 'Remove from a Stage' } : {})
      .merge(client.groups_count.positive? ? { 350 => 'Add To a Group' } : {})
      .merge(client.groups_count.positive? ? { 355 => 'Remove From a Group' } : {})
      .merge({ 360 => 'Assign a Lead Source' })
      .merge(client.campaigns_count.positive? ? { 400 => 'Stop a Campaign' } : {})
      .merge(client.ai_agents? ? { 450 => 'Stop AI Agent Conversations' } : {})
      .merge({
               500 => 'Set OK to Text ON',
               505 => 'Set OK to Text OFF',
               501 => 'Set OK to Email ON',
               506 => 'Set OK to Email OFF',
               510 => 'Reassign Contact'
             })
      .merge({
               600 => 'Save a Text Response'
             })
      .merge(client.custom_fields_count.positive? ? { 605 => 'Custom Field Action' } : {})
      .merge({
               610 => 'Update Contact Info',
               615 => 'Add a Note to Contact'
             })
      .merge(client.tasks_allowed ? { 700 => 'Create a Task' } : {})
      .merge(client.phone_calls_allowed ? { 750 => 'Make a Voice Call' } : {})
      .merge(client.id == I18n.t("tenant.#{Rails.env}.client_id").to_i ? { 800 => 'Create a Client' } : {})
      .merge(client.agency_access ? { 801 => 'Push Contact to Client' } : {})
      .merge(client.integrations_allowed.include?('pcrichard') ? { 901 => 'Push data to PC Richard' } : {})
  end

  # create a unique title for the Trigger
  # triggeraction.type_name
  def type_name
    response = Triggeraction.type_hash(trigger.campaign.client)[action_type] || 'Unknown Action Type'

    case action_type
    when 100
      response += " (#{ActionController::Base.helpers.truncate(text_message, length: 18)})" unless text_message.empty?
      response += ' (Image Only)' if text_message.empty? && !attachments.empty?
    when 150
      response += if voice_recording_id.to_i.positive? && (voice_recording = trigger.campaign.client.voice_recordings.find_by(id: voice_recording_id))
                    " (#{ActionController::Base.helpers.truncate(voice_recording.recording_name, length: 18)})"
                  else
                    ' (undefined)'
                  end
    when 170
      if (email_template = trigger.campaign.client.email_templates.find_by(id: self.email_template_id))
        response += " (#{ActionController::Base.helpers.truncate(email_template.name, length: 18)})"
      end
    when 171
      response += self.subject.present? ? " (#{ActionController::Base.helpers.truncate(self.subject, length: 18)})" : ''
    when 180
      response += " (#{self.slack_channel} / #{ActionController::Base.helpers.truncate(self.text_message, length: 18)})"
    when 181, 182
      response += " (#{self.slack_channel})"
    when 200
      response += if campaign_id.to_i.positive? && (campaign = trigger.campaign.client.campaigns.find_by(id: campaign_id))
                    " (#{ActionController::Base.helpers.truncate(campaign.name, length: 18)})"
                  else
                    ' (undefined)'
                  end
    when 250
      response += if self.aiagent_id && (aiagent = Aiagent.find_by(id: self.aiagent_id))
                    " (#{aiagent.name})"
                  else
                    ' (undefined)'
                  end
    when 300, 305
      response += if tag_id.to_i.positive? && (tag = trigger.campaign.client.tags.find_by(id: tag_id))
                    " (#{ActionController::Base.helpers.truncate(tag.name, length: 18)})"
                  else
                    ' (undefined)'
                  end
    when 340
      response += if stage_id.to_i.positive? && (stage = Stage.for_client(trigger.campaign.client.id).find_by(id: stage_id))
                    " (#{ActionController::Base.helpers.truncate(stage.name, length: 18)})"
                  else
                    ' (undefined)'
                  end
    when 345
      response += if stage_id.to_i.positive? && (stage = Stage.for_client(trigger.campaign.client.id).find_by(id: stage_id))
                    " (#{ActionController::Base.helpers.truncate(stage.name, length: 18)})"
                  elsif stage_id.to_i.zero?
                    ' (All Stages)'
                  else
                    ' (undefined)'
                  end
    when 350, 355
      response += if group_id.to_i.positive? && (group = trigger.campaign.client.groups.find_by(id: group_id))
                    " (#{ActionController::Base.helpers.truncate(group.name, length: 18)})"
                  else
                    ' (undefined)'
                  end
    when 360
      response += if !self.lead_source_id.nil? && (lead_source = trigger.campaign.client.lead_sources.find_by(id: self.lead_source_id))
                    " (#{ActionController::Base.helpers.truncate(lead_source.name, length: 18)})"
                  elsif !self.lead_source_id.nil? && self.lead_source_id.to_i.zero?
                    ' (No Lead Source)'
                  else
                    ' (undefined)'
                  end
    when 400
      campaign_id = self.campaign_id[0, 6]

      response += case campaign_id
                  when 'this'
                    ' (This Campaign)'
                  when 'all_ot'
                    ' (All Other Campaigns)'
                  when 'group_'

                    if (campaign_group = trigger.campaign.client.campaign_groups.find_by(id: self.campaign_id.gsub('group_', '').to_i))
                      " (Group: #{campaign_group.name})"
                    else
                      ' (Group: Unknown)'
                    end
                  else

                    if self.campaign_id.to_i.positive? && (campaign = trigger.campaign.client.campaigns.find_by(id: self.campaign_id))
                      " (#{ActionController::Base.helpers.truncate(campaign.name, length: 18)})"
                    else
                      ' (undefined)'
                    end
                  end
    when 600, 605, 610
      internal_fields = ::Webhook.internal_key_hash(trigger.campaign.client, 'contact', %w[personal ext_references]).merge(::Webhook.internal_key_hash(trigger.campaign.client, 'contact', %w[phones])).merge({ 'brand-notes' => 'Notes' })
      custom_fields   = trigger.campaign.client.client_custom_fields.pluck(:id, :var_name).to_h

      response += if internal_fields.key?(client_custom_field_id.to_s)
                    " (#{ActionController::Base.helpers.truncate(internal_fields[client_custom_field_id.to_s], length: 18)})"
                  elsif custom_fields.key?(client_custom_field_id.to_i)
                    " (#{ActionController::Base.helpers.truncate(custom_fields[client_custom_field_id.to_i], length: 18)})"
                  else
                    ' (undefined)'
                  end
    when 615
      response += " (#{ActionController::Base.helpers.truncate(self.note, length: 18)})"
    when 700
      response += " (#{ActionController::Base.helpers.truncate(name.to_s, length: 18)})"
    end

    response
  end

  private

  def after_commit_process
    return if self.destroyed?

    self.campaign.update(analyzed: campaign.analyze!.empty?)
  end

  def after_destroy_commit_actions
    super

    return unless (campaign = Campaign.find_by(id: self.trigger&.campaign_id))

    campaign.update(analyzed: campaign.analyze!.empty?)
  end

  def apply_defaults
    if self.scheduled_type?
      self.delay_months                      ||= 0
      self.delay_days                        ||= 0
      self.delay_hours                       ||= 0
      self.delay_minutes                     ||= 0
      self.safe_start                        ||= 480  #  8:00
      self.safe_end                          ||= 1200 # 20:00
      self.safe_sun                            = safe_sun.nil? ? false : safe_sun.to_bool
      self.safe_mon                            = safe_mon.nil? ? true : safe_mon.to_bool
      self.safe_tue                            = safe_tue.nil? ? true : safe_tue.to_bool
      self.safe_wed                            = safe_wed.nil? ? true : safe_wed.to_bool
      self.safe_thu                            = safe_thu.nil? ? true : safe_thu.to_bool
      self.safe_fri                            = safe_fri.nil? ? true : safe_fri.to_bool
      self.safe_sat                            = safe_sat.nil? ? false : safe_sat
      self.ok2skip                             = ok2skip.nil? ? false : ok2skip
    end

    case action_type
    when 100
      self.text_message                    ||= ''
      self.from_phone                      ||= []
      self.send_to                         ||= ''
      self.last_used_from_phone            ||= ''
      self.attachments                     ||= []
    when 150
      self.voice_recording_id              ||= nil
      self.from_phone                      ||= ''
    when 170
      self.email_template_id               ||= nil
      self.cc_email                        ||= ''
      self.cc_name                         ||= ''
      self.bcc_email                       ||= ''
      self.bcc_name                        ||= ''
      self.reply_email                     ||= ''
      self.reply_name                      ||= ''
      self.from_email                      ||= ''
    when 180
      self.text_message                    ||= ''
      self.slack_channel                   ||= ''
      self.attachments                     ||= []
    when 181
      self.slack_channel                   ||= ''
    when 182
      self.slack_channel                   ||= ''
      self.users                           ||= []
    when 200
      self.campaign_id                     ||= 0
    when 250, 450
      self.aiagent_id ||= ''
    when 300, 305
      self.tag_id                          ||= 0
    when 340, 345
      self.stage_id                        ||= 0
    when 350, 355
      self.group_id                        ||= 0
    when 360
      self.lead_source_id                  ||= nil
    when 400
      self.campaign_id                     ||= ''
      self.description                     ||= ''
      self.job_estimate_id                 ||= false
      self.not_this_campaign               ||= false
    when 510
      self.assign_to                       ||= {}
      self.distribution                    ||= {}
    when 600
      self.client_custom_field_id            = (client_custom_field_id.is_a?(Integer) && client_custom_field_id.zero? ? '' : client_custom_field_id.to_s)
      self.parse_text_respond                = parse_text_respond.nil? ? false : parse_text_respond
      self.parse_text_notify                 = parse_text_notify.nil? ? false : parse_text_notify
      self.parse_text_text                   = parse_text_text.nil? ? false : parse_text_text
      self.clear_field_on_invalid_response   = clear_field_on_invalid_response.nil? ? false : clear_field_on_invalid_response
      self.text_message                    ||= ''
      self.attachments                     ||= []
    when 605
      self.client_custom_field_id            = client_custom_field_id.to_i
      self.response_range                    = (response_range || {})
    when 610
      self.client_custom_field_id            = (client_custom_field_id.is_a?(Integer) && client_custom_field_id.zero? ? '' : client_custom_field_id.to_s)
      self.description                     ||= ''
    when 615
      self.user_id                         ||= 0
      self.note                            ||= ''
    when 700
      self.name                            ||= ''
      self.assign_to                       ||= ''
      self.from_phone                      ||= ''
      self.description                     ||= ''
      self.campaign_id                     ||= 0
      self.due_delay_days                  ||= 0
      self.due_delay_hours                 ||= 0
      self.due_delay_minutes               ||= 0
      self.dead_delay_days                 ||= 0
      self.dead_delay_hours                ||= 0
      self.dead_delay_minutes              ||= 0
      self.cancel_after                    ||= 0
    when 750
      self.user_id                         ||= ''
      self.send_to                         ||= ''
      self.from_phone                      ||= ''
      self.retry_count                     ||= 0
      self.retry_interval                  ||= 0
      self.stop_on_connection              ||= self.stop_on_connection.nil? ? false : self.stop_on_connection
    when 800
      self.client_name_custom_field_id     ||= 0
      self.client_package_id               ||= 0
    when 801
      self.clients                         ||= []
    when 901
      self.completed                       ||= {}
      self.install_method                  ||= ''
      self.scheduled                       ||= {}
      self.serial_number                   ||= ''
    end
  end

  # duplicate defined images for the Triggeraction to the Contact & return an image id array
  # fire_triggeraction_100_image_ids()
  #   (req) contact:          (Contact)
  #   (req) contact_campaign: (Contacts::Campaign)
  def fire_triggeraction_100_image_ids(contact:, contact_campaign:)
    image_id_array = []

    self.attachments.each do |image_id|
      client_attachment = ClientAttachment.find_by(id: image_id)

      begin
        contact_attachment = contact.contact_attachments.new
        contact_attachment.remote_image_url = client_attachment.image.url(secure: true)
        contact_attachment.save
        image_id_array << contact_attachment.id
      rescue Cloudinary::CarrierWave::UploadError => e
        if e.message.downcase.include?('resource not found')
          Users::SendPushOrTextJob.perform_later(
            contact_id:       contact.id,
            content:          "Image was NOT found for Trigger: #{self.trigger.data[:name]} in Campaign: #{self.campaign.name}. Text was #{self.text_message.present? ? 'sent without image' : 'NOT sent'}. Customer: #{contact.fullname}.",
            from_phone:,
            ok2push:          contact.user.notifications.dig('campaigns', 'by_push'),
            ok2text:          contact.user.notifications.dig('campaigns', 'by_text'),
            triggeraction_id: self.id,
            user_id:          contact.user_id
          )
        else
          e.set_backtrace(BC.new.clean(caller))

          Appsignal.report_error(e) do |transaction|
            # Only needed if it needs to be different or there's no active transaction from which to inherit it
            Appsignal.set_action('Triggeraction.fire_triggeraction_100_image_ids')

            # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
            Appsignal.add_params({ contact:, contact_campaign: })

            Appsignal.set_tags(
              error_level: 'error',
              error_code:  0
            )
            Appsignal.add_custom_data(
              attachments:        self.attachments.inspect,
              client_attachment:  client_attachment.inspect,
              contact_attachment: defined?(contact_attachment) ? contact_attachment.inspect : 'Undefined',
              image_id_array:     image_id_array.inspect,
              file:               __FILE__,
              line:               __LINE__
            )
          end
        end
      rescue ActiveRecord::RecordInvalid => e
        e.set_backtrace(BC.new.clean(caller))

        Appsignal.report_error(e) do |transaction|
          # Only needed if it needs to be different or there's no active transaction from which to inherit it
          Appsignal.set_action('Triggeraction.fire_triggeraction_100_image_ids')

          # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
          Appsignal.add_params({ contact:, contact_campaign: })

          Appsignal.set_tags(
            error_level: 'error',
            error_code:  0
          )
          Appsignal.add_custom_data(
            attachments:        self.attachments.inspect,
            client_attachment:  client_attachment.inspect,
            contact_attachment: defined?(contact_attachment) ? contact_attachment.inspect : 'Undefined',
            image_id_array:     image_id_array.inspect,
            file:               __FILE__,
            line:               __LINE__
          )
        end
      rescue StandardError => e
        e.set_backtrace(BC.new.clean(caller))

        Appsignal.report_error(e) do |transaction|
          # Only needed if it needs to be different or there's no active transaction from which to inherit it
          Appsignal.set_action('Triggeraction.fire_triggeraction_100_image_ids')

          # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
          Appsignal.add_params({ contact:, contact_campaign: })

          Appsignal.set_tags(
            error_level: 'error',
            error_code:  0
          )
          Appsignal.add_custom_data(
            attachments:        self.attachments.inspect,
            client_attachment:  client_attachment.inspect,
            contact_attachment: defined?(contact_attachment) ? contact_attachment.inspect : 'Undefined',
            image_id_array:     image_id_array.inspect,
            file:               __FILE__,
            line:               __LINE__
          )
        end
      end
    end

    image_id_array
  end
end
