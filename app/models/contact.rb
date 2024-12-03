# frozen_string_literal: true

# app/models/contact.rb
class Contact < ApplicationRecord
  include Textable

  class ContactEmailNoBodyError < StandardError; end

  belongs_to :campaign_group, optional: true
  belongs_to :client
  belongs_to :group, optional: true
  belongs_to :lead_source, class_name: '::Clients::LeadSource', optional: true
  belongs_to :parent, class_name: 'Contact', optional: true
  belongs_to :stage, optional: true
  belongs_to :user

  has_one    :corp_client, dependent: nil, class_name: :Client

  has_many   :aiagent_sessions,         dependent: :nullify, class_name: '::Aiagent::SmsSession'
  has_many   :children,                 dependent: :nullify, class_name: 'Contact', foreign_key: 'parent_id'
  has_many   :contact_api_integrations, dependent: :destroy
  has_many   :contact_attachments,      dependent: :destroy
  has_many   :contact_campaigns,        dependent: :destroy, class_name: '::Contacts::Campaign'
  has_many   :contact_custom_fields,    dependent: :destroy
  has_many   :contact_phones,           dependent: :destroy
  has_many   :contacttags,              dependent: :destroy
  has_many   :delayed_jobs,             dependent: :delete_all
  has_many   :estimates,                dependent: :destroy,    class_name: '::Contacts::Estimate'
  has_many   :ext_references,           dependent: :delete_all, class_name: '::Contacts::ExtReference'
  has_many   :fb_pages,                 dependent: :delete_all, class_name: '::Contacts::FbPage'
  has_many   :ggl_conversations,        dependent: :delete_all, class_name: '::Contacts::GglConversation'
  has_many   :invoices,                 dependent: :destroy,    class_name: '::Contacts::Invoice'
  has_many   :jobs,                     dependent: :destroy,    class_name: '::Contacts::Job'
  has_many   :messages,                 dependent: :destroy,    class_name: '::Messages::Message'
  has_many   :notes,                    dependent: :destroy,    class_name: '::Contacts::Note'
  has_many   :postcards,                dependent: :delete_all
  has_many   :raw_posts,                dependent: :delete_all, class_name: '::Contacts::RawPost'
  has_many   :requests,                 dependent: :destroy,    class_name: '::Contacts::Request'
  has_many   :reviews,                  dependent: :nullify
  has_many   :subscriptions,            dependent: :destroy,    class_name: '::Contacts::Subscription'
  has_many   :survey_results,           dependent: :destroy,    class_name: '::Surveys::Result'
  has_many   :tasks,                    dependent: :destroy
  has_many   :trackable_short_links,    dependent: :destroy
  has_many   :user_chats,               dependent: :destroy
  has_many   :visits,                   dependent: :destroy, class_name: '::Contacts::Visit'

  has_many   :aiagents,                        through: :aiagent_sessions
  has_many   :campaigns, -> { distinct },      through: :contact_campaigns
  has_many   :contact_campaign_triggeractions, through: :contact_campaigns, source: :triggeractions
  has_many   :tags,                            through: :contacttags

  # miscellaneous data
  store_accessor :data, :trusted_form, :folders

  after_initialize :apply_defaults, if: :new_record?

  normalizes :firstname, with: ->(str) { str&.normalize_non_ascii }
  normalizes :lastname, with: ->(str) { str&.normalize_non_ascii }
  normalizes :companyname, with: ->(str) { str&.normalize_non_ascii }
  validate  :count_is_approved, on: [:create]
  validates :state, length: { maximum: 2 }
  validates_with EmailAddress::ActiveRecordValidator, field: :email

  before_validation    :before_validation_actions
  before_save          :before_save_actions

  scope :by_client_and_email, ->(client_id, email) {
    where(client_id:)
      .where(email:)
  }
  scope :by_client_and_phone, ->(client_id, phone) {
    left_outer_joins(:contact_phones)
      .where(client_id:)
      .where(contact_phones: { phone: })
  }
  scope :by_tenant, ->(tenant = 'chiirp') {
    joins(:client)
      .where(clients: { tenant: })
  }
  scope :by_user_and_email, ->(user_id, email) {
    joins(:contact_phones)
      .where(user_id:)
      .where(email:)
  }
  scope :by_user_and_phone, ->(user_id, phone) {
    joins(:contact_phones)
      .where(user_id:)
      .where(contact_phones: { phone: })
  }
  scope :group_by_client, ->(client_id, group_id, from_date = 50.years.ago, to_date = Time.current) {
    where(client_id:)
      .where(group_id:)
      .where(group_id_updated_at: from_date..to_date)
  }
  scope :group_by_user, ->(user_id, group_id, from_date = 50.years.ago, to_date = Time.current) {
    where(user_id:)
      .where(group_id:)
      .where(group_id_updated_at: from_date..to_date)
  }
  scope :lead_source_by_client, ->(client_id, lead_source_id, from_date = 50.years.ago, to_date = Time.current) {
    where(client_id:)
      .where(lead_source_id:)
      .where(lead_source_id_updated_at: from_date..to_date)
  }
  scope :lead_source_by_user, ->(user_id, lead_source_id, from_date = 50.years.ago, to_date = Time.current) {
    where(user_id:)
      .where(lead_source_id:)
      .where(lead_source_id_updated_at: from_date..to_date)
  }
  scope :string_search, ->(search_string, firstname = nil, lastname = nil) {
    left_outer_joins(:contact_phones).where(
      [
        "#{firstname.present? && lastname.present? ? '(' : ''}#{firstname.present? || search_string.present? ? 'firstname ilike ?' : ''}#{if firstname.present? && lastname.present?
                                                                                                                                            ' and '
                                                                                                                                          else
                                                                                                                                            (firstname.present? || search_string.present?) && (lastname.present? || search_string.present?) ? ' or ' : ''
                                                                                                                                          end}#{lastname.present? || search_string.present? ? 'lastname ilike ?' : ''}#{firstname.present? && lastname.present? ? ')' : ''}#{search_string.present? ? ' or contact_phones.phone ilike ? or address1 ilike ? or address2 ilike ? or city ilike ? or state ilike ? or zipcode ilike ? or companyname ilike ? or email ilike ?' : ''}",
        firstname.present? || search_string.present? ? "%#{firstname.presence || search_string}%" : nil,
        lastname.present? || search_string.present? ? "%#{lastname.presence || search_string}%" : nil,
        search_string.present? ? "%#{search_string&.strip_phone.presence || search_string}%" : nil,
        search_string.present? ? "%#{search_string}%" : nil,
        search_string.present? ? "%#{search_string}%" : nil,
        search_string.present? ? "%#{search_string}%" : nil,
        search_string.present? ? "%#{search_string}%" : nil,
        search_string.present? ? "%#{search_string}%" : nil,
        search_string.present? ? "%#{search_string}%" : nil,
        search_string.present? ? "%#{search_string}%" : nil
      ].compact_blank
    )
  }

  # collect Array of all active Campaigns
  # contact.active_campaigns
  def active_campaigns
    # collect incomplete Campaigns
    campaigns = self.contact_campaigns.where(completed: false).pluck(:campaign_id)

    # merge in incomplete Triggeractions in DelayedJob
    campaigns << self.delayed_jobs.where('contact_campaign_id > 0').joins(:contact_campaign).select('delayed_jobs.contact_id AS contact_id, contact_campaigns.campaign_id AS campaign_id').pluck(:campaign_id)

    # clean up duplicates
    campaigns.flatten.uniq
  end

  # collect Array of all active Contacts::Campaign IDs for this Contact
  # contact.active_contact_campaign_ids
  def active_contact_campaign_ids
    # collect incomplete Contacts::Campaigns
    contact_campaign_ids = self.contact_campaigns.where(completed: false).pluck(:id)

    # merge in incomplete Triggeractions in DelayedJob
    contact_campaign_ids += self.delayed_jobs.where(contact_campaign_id: 1..).pluck(:contact_campaign_id)

    # clean up duplicates
    contact_campaign_ids.uniq
  end

  # generate a string that will be used to query messages for specific message types
  # Contact.active_contacts_message_type_string()
  #   (req) msg_types: (Array) ['email', 'fb', 'ggl', 'rvm', 'text', 'voice', 'widget']
  def self.active_contacts_message_type_string(msg_types)
    msg_types = %w[email fb ggl rvm text video voice widget] unless msg_types.is_a?(Array) && msg_types.present?
    msg_types_email  = msg_types.include?('email') ? Messages::Message::MSG_TYPES_EMAIL : []
    msg_types_fb     = msg_types.include?('fb') ? Messages::Message::MSG_TYPES_FB : []
    msg_types_ggl    = msg_types.include?('ggl') ? Messages::Message::MSG_TYPES_GGL : []
    msg_types_rvm    = msg_types.include?('rvm') ? Messages::Message::MSG_TYPES_RVM : []
    msg_types_text   = msg_types.include?('text') ? Messages::Message::MSG_TYPES_TEXT : []
    msg_types_video  = msg_types.include?('video') ? Messages::Message::MSG_TYPES_VIDEO : []
    msg_types_voice  = msg_types.include?('voice') ? Messages::Message::MSG_TYPES_VOICE : []
    msg_types_widget = msg_types.include?('widget') ? Messages::Message::MSG_TYPES_WIDGET : []
    (msg_types_email + msg_types_fb + msg_types_ggl + msg_types_rvm + msg_types_text + msg_types_video + msg_types_voice + msg_types_widget).map { |item| %('#{item}') }.join(', ')
  end

  # select Contacts with last Messages::Message
  # Contact.active_contacts_with_last_message(user_id: Integer)
  # Contact.active_contacts_with_last_message(user_id: Integer, include_automated: Boolean (false), include_sleeping: Boolean, past_days: Integer (30), group_id: Integer (0))
  # Contact.active_contacts_with_last_message(client_id: Integer)
  # Contact.active_contacts_with_last_message(client_id: Integer, include_automated: Boolean (false), include_sleeping: Boolean, past_days: Integer (30), group_id: Integer (0))
  def self.active_contacts_with_last_message(args = {})
    if args.dig(:user_id).to_i.positive? || args.dig(:client_id).to_i.positive?
      Messages::Message.find_by_sql(self.active_contacts_with_last_message_query(args))
    else
      []
    end
  end

  # generate SQL query to select all Contacts with last Messages::Message
  # Contact.active_contacts_with_last_message_query()
  #   (opt) client_ids:        (Array / default: any)
  #   (opt) group_id:          (Integer / default: >=0)
  #   (opt) include_automated: (Boolean / default: true or false)
  #   (opt) include_sleeping:  (Boolean / default: true or false)
  #   (opt) msg_types:         (Array / default: [])
  #   (opt) past_days:         (Integer / default: 15)
  #   (opt) user_ids:          (Array / default: any)
  def self.active_contacts_with_last_message_query(args = {})
    <<~SQL.squish
      SELECT contacts.id AS contact_id, MAX(messages.created_at) AS created_at
      FROM messages
      INNER JOIN contacts ON contacts.id = messages.contact_id
      WHERE messages.created_at >= '#{(Time.current - (args.dig(:past_days) || 15).to_i.days).strftime('%Y-%m-%d %T')}'
        AND messages.automated IN #{args.dig(:include_automated).to_bool ? '(true, false)' : '(false)'}
        AND messages.msg_type IN (#{self.active_contacts_message_type_string(args.dig(:msg_types))})
        AND (#{if args.dig(:client_ids).present?
                 "contacts.client_id IN (#{args[:client_ids].join(',')}) "
               else
                 '1=0 '
               end}
          OR #{if args.dig(:user_ids).present?
                 "contacts.user_id IN (#{args[:user_ids].join(',')}) "
               else
                 '1=0 '
               end}
          )
        AND (contacts.sleep IN (#{args.dig(:include_sleeping).to_bool ? 'true, false' : 'false'}))
        AND (contacts.block = false)
        AND (contacts.group_id #{args.dig(:group_id).to_i.positive? ? "= #{args.dig(:group_id).to_i}" : '>= 0'})
      GROUP BY contacts.id
      ORDER BY created_at DESC
    SQL
  end

  # select sorted list of Contacts with last Messages::Message
  # Contact.active_contacts_list()
  #   (req) client_ids: (Array)
  #   (req) user_ids:   (Array)
  def self.active_contacts_list(args = {})
    return [] unless args.dig(:client_ids).is_a?(Array) && args.dig(:user_ids).is_a?(Array)

    sql = <<-SQL.squish
      SELECT
        contacts.id AS id,
        contacts.user_id AS user_id,
        contacts.client_id AS client_id,
        contacts.firstname AS firstname,
        contacts.lastname AS lastname,
        contacts.data AS data,
        contact_phones.phone AS phone,
        messages.id AS tw_id,
        messages.message AS tw_message,
        messages.msg_type AS tw_msg_type,
        messages.created_at AS tw_created_at,
        messages.read_at AS tw_read_at,
        MAX(tags.color) AS tag_color
      FROM (#{self.active_contacts_with_last_message_query(args)}) AS latest_messages
      INNER JOIN messages ON messages.contact_id = latest_messages.contact_id AND messages.created_at = latest_messages.created_at
      INNER JOIN contacts ON messages.contact_id = contacts.id
      LEFT OUTER JOIN contact_phones ON contact_phones.contact_id = contacts.id AND contact_phones.primary
      LEFT OUTER JOIN contacttags ON contacttags.contact_id = contacts.id
      LEFT OUTER JOIN tags ON contacttags.tag_id = tags.id
      GROUP BY contacts.id, contact_phones.phone, tw_id, tw_message, tw_msg_type, tw_created_at, tw_read_at
      ORDER BY tw_created_at DESC
    SQL

    self.find_by_sql(sql)
  end
  # client_id = 123
  # SELECT contacts.id AS contact_id, MAX(messages.created_at) AS created_at FROM messages INNER JOIN contacts ON contacts.id = messages.contact_id WHERE messages.automated IN (true, false) AND contacts.client_id = #{client_id} AND (contacts.sleep = '0' OR contacts.sleep IS NULL) GROUP BY contacts.id
  # SELECT contacts.id AS id, contacts.firstname AS firstname, contacts.lastname AS lastname, contact_phones.phone AS phone, messages.message AS tw_message, messages.created_at AS tw_created_at, messages.read_at AS tw_read_at, MAX(tags.color) AS tag_color FROM (SELECT contacts.id AS contact_id, MAX(messages.created_at) AS created_at FROM messages INNER JOIN contacts ON contacts.id = messages.contact_id WHERE messages.automated IN (true, false) AND contacts.client_id = #{client_id} AND (contacts.sleep = '0' OR contacts.sleep IS NULL) GROUP BY contacts.id) AS latest_messages INNER JOIN messages ON messages.contact_id = latest_messages.contact_id AND messages.created_at = latest_messages.created_at INNER JOIN contacts ON messages.contact_id = contacts.id LEFT OUTER JOIN contact_phones ON contact_phones.contact_id = contacts.id AND contact_phones.primary LEFT OUTER JOIN contacttags ON contacttags.contact_id = contacts.id LEFT OUTER JOIN tags ON contacttags.tag_id = tags.id GROUP BY contacts.id, contact_phones.phone, tw_message, tw_created_at, tw_read_at ORDER BY tw_created_at DESC

  # are there any active aiagent_sessions records?
  def active_aiagents?
    aiagent_sessions.active.any?
  end

  # start a new session with an aiagent
  def aiagent_stop_all_and_start_session(args = {})
    # stop any previous aiagent sessions
    self.aiagent_sessions.active.find_each do |session|
      session.stop!(:stopped)
    end

    self.aiagent_start_session(args)
  end

  def aiagent_start_session(args = {})
    aiagent = Aiagent.find_by(id: args[:aiagent_id])
    return unless aiagent

    # record aiagent session has begun
    aiagent_session = self.aiagent_sessions.create!(aiagent:, from_phone: args[:from_phone])

    content = aiagent_session.initial_prompt_for_contact
    aiagent_session.aiagent_messages.create!(role: :assistant, content:)

    return unless content

    self.send_text(
      automated:          true,
      content:,
      from_phone:         args[:from_phone] || '',
      to_label:           args[:to_label] || '',
      triggeraction_id:   self.id,
      aiagent_session_id: aiagent_session.id
    )
  end

  def aiagent_start_session_from_triggeraction(args = {})
    # stop any previous aiagent sessions
    active_aiagent_sessions = self.aiagent_sessions.active

    if active_aiagent_sessions.length > 1
      # shouldn't be more than one; something is wrong
      active_aiagent_sessions.find_each do |session|
        session.stop!(:stopped)
      end
    elsif active_aiagent_sessions.length == 1
      return if active_aiagent_sessions.first.aiagent_id.to_i == args[:aiagent_id]

      active_aiagent_sessions.first.stop!(:stopped)
    end

    self.aiagent_start_session(args)
  end

  # apply a system defined Tag denoting that a text message was undeliverable due to a carrier violation
  def apply_carrier_violation_tag
    Contacts::Tags::ApplyByNameJob.perform_now(
      contact_id: self.id,
      tag_name:   'Carrier Violation'
    )
  end

  # apply a system defined Tag denoting that the Contact opted out of further text communications
  def apply_stop_tag
    Contacts::Tags::ApplyByNameJob.perform_now(
      contact_id: self.id,
      tag_name:   'Opted Out'
    )
  end

  # DEPRECATED (delete after 2027-10-07)
  # replaced by Contacts::Tags::ApplyJob
  # apply a Tag to a Contact
  # @contact.apply_tag()
  def apply_tag(tag_id)
    return unless tag_id.to_i.positive? && (tag = Tag.find_by(client_id: self.client_id, id: tag_id.to_i))

    if (contacttag = Contacttag.find_by(contact_id: self.id, tag_id: tag.id))
      # update Contacttag (triggers Tag actions)
      contacttag.update(updated_at: Time.current)
      contacttag
    else
      # create new Contacttag (triggers Tag actions)
      self.contacttags.create(tag_id: tag.id)
    end
  end

  # apply a system defined Tag denoting that the Contact was sent a text that was undeliverable
  def apply_undeliverable_tag
    Contacts::Tags::ApplyByNameJob.perform_now(
      contact_id: self.id,
      tag_name:   'Undeliverable Text'
    )
  end

  # create CSV of Contacts
  # format.csv { send_data @contact.as_csv }
  def self.as_csv(standard_fields: [], phone_fields: [], custom_fields: [], integrations_fields: [])
    client_custom_field_ids = {}

    CSV.generate(headers: true) do |csv|
      csv << (standard_fields + phone_fields + custom_fields + integrations_fields)

      self.includes(:contact_phones).find_each do |c|
        phone_data = phone_fields.map do |field|
          c.contact_phones.find_by(label: field.gsub(%r{^phone_}, '')).try(:phone)
        end
        custom_data = custom_fields.map do |field|
          client_custom_field_id = client_custom_field_ids[field] ||= c.client_custom_fields.find_by(var_var: field)&.id
          c.contact_custom_fields.find_by(client_custom_field_id:)&.var_value
        end
        integrations_data = integrations_fields.map do |field|
          c.ext_references.find_by(target: field)&.ext_id
        end
        csv << (standard_fields.map { |attr| c.attributes[attr] } + phone_data + custom_data + integrations_data)
      end
    end
  end

  # assign Contact to a User
  # contact.assign_user()
  #   (req) user_id: (Integer)
  def assign_user(user_id)
    return unless user_id.to_i.positive? && self.user_id != user_id.to_i && self.client.users.find_by(id: user_id.to_i)

    self.update(user_id: user_id.to_i)
  end

  # call Contact
  # @contact.call( users_orgs: String, from_phone: String )
  #   1. Call User with callback
  #   2. User answers & triggers callback
  #   3. Call Contact & connect calls
  def call(args = {})
    users_orgs          = args.dig(:users_orgs).to_s
    from_phone          = args.dig(:from_phone).to_s.strip.downcase
    from_phone          = self.user.default_from_twnumber&.phonenumber.to_s if from_phone == 'user_number'
    from_phone          = self.latest_client_phonenumber(default_ok: true, phone_numbers_only: true)&.phonenumber.to_s if from_phone == 'last_number' || from_phone.blank?
    twnumber            = from_phone == 'user_number' ? self.user.default_from_twnumber : nil
    twnumber            = self.latest_client_phonenumber(default_ok: true, phone_numbers_only: true) if from_phone.empty? && twnumber.nil?
    contact_phone       = args.dig(:contact_phone).to_s
    machine_detection   = args.dig(:machine_detection).to_bool
    response            = { success: false, error_message: '' }

    contact_campaign_id = args.dig(:contact_campaign_id).to_i
    triggeraction_id    = args.dig(:triggeraction_id).to_i

    if from_phone.empty? && twnumber.nil?
      response[:error_message] = 'From Phone NOT Defined'
    elsif users_orgs.present?
      user_to_phones = self.org_users(users_orgs:, purpose: 'voice', default_to_all_users_in_org_position: false)
      to_phone       = user_to_phones.present? ? user_to_phones[0][0] : ''
      twnumber       = self.client.twnumbers.find_by(phonenumber: from_phone) if twnumber.nil?

      if to_phone.present? && twnumber.present?
        app_host     = I18n.with_locale(self.client.tenant) { I18n.t("tenant.#{Rails.env}.app_host") }
        app_protocol = I18n.with_locale(self.client.tenant) { I18n.t('tenant.app_protocol') }
        url_params   = []
        url_params  << "contact_id=#{self.id}"
        url_params  << "contact_campaign_id=#{contact_campaign_id}" if contact_campaign_id.positive?
        url_params  << "triggeraction_id=#{triggeraction_id}" if triggeraction_id.positive?
        url_params  << "contact_phone=#{contact_phone}" if contact_phone.present?

        case twnumber.phone_vendor
        when 'bandwidth'
          result = Voice::Bandwidth.call(
            to_phone:,
            from_phone:     twnumber.phonenumber,
            answer_url:     Rails.application.routes.url_helpers.voices_bandwidth_out_user_answered_url(host: app_host, protocol: app_protocol).to_s + (url_params.present? ? "?#{url_params.join('&')}" : '/'),
            disconnect_url: Rails.application.routes.url_helpers.voices_bandwidth_out_disconnected_call_url('initial', host: app_host, protocol: app_protocol)
          )
        when 'twilio'
          result = Voice::TwilioVoice.call(
            to_phone:,
            from_phone:        twnumber.phonenumber,
            callback_url:      Rails.application.routes.url_helpers.voices_twiliovoice_out_user_answered_url(host: app_host, protocol: app_protocol).to_s + (url_params.present? ? "?#{url_params.join('&')}" : '/'),
            machine_detection:
          )
        end

        if result[:success]
          response[:success] = true
        else
          response[:error_message] = result[:error_message]
        end
      else
        response[:error_message] = 'To phone is required.' if to_phone.blank?
        response[:error_message] = 'From phone is required.' if twnumber.blank?
      end
    end

    response
  end

  # A campaign was started for this contact
  # contact.campaign_started
  #   (req) campaign: (Campaign)
  def campaign_started(campaign)
    return unless campaign.campaign_group.present?

    # update the campaign group id for this Contact
    self.campaign_group_id = campaign.campaign_group.id

    self.save
  end

  # update read_at & read_at_user_id for all messages belonging to Contact
  def clear_unread_messages(user)
    return if !user.is_a?(User) || self.new_record? || (unread_messages = Messages::Message.unread_messages_by_contact(self.id)).blank?

    # rubocop:disable Rails/SkipsModelValidations
    unread_messages.update_all(read_at: DateTime.current, read_at_user_id: user.id, updated_at: DateTime.current)
    # rubocop:enable Rails/SkipsModelValidations

    Messages::UpdateUnreadMessageIndicatorsJob.perform_later(user_id: self.user_id)
  end

  # create a collection of ClientCustomFields that includes this Contact's data
  # contact.client_custom_fields
  def client_custom_fields
    self.client.client_custom_fields.joins("LEFT JOIN contact_custom_fields ON client_custom_fields.id = contact_custom_fields.client_custom_field_id AND contact_custom_fields.contact_id = #{self.id || 0}").select('client_custom_fields.*, contact_custom_fields.var_value AS var_value')
  end

  # DEPRECATED (delete after 2027-04-05)
  # replaced by Contacts::Campaigns::StopJob
  # return the Contacts::Campaign ids that will be stopped
  # only stop Campaigns related to contact_job_id, contact_invoice_id, contact_estimate_id, contact_subscription_id or contact_visit_id when limit_to_estimate_job_visit_id = true
  # contact.contact_campaign_ids_to_stop()
  #   (req) active_contact_campaign_ids:    (Array)
  #   (req) contact_campaign:               (Contacts::Campaign)
  #   (req) limit_to_estimate_job_visit_id: (Boolean)
  def contact_campaign_ids_to_stop(active_contact_campaign_ids, contact_campaign, limit_to_estimate_job_visit_id)
    return active_contact_campaign_ids unless limit_to_estimate_job_visit_id.to_bool && active_contact_campaign_ids.present?

    if contact_campaign&.data&.dig(:contact_estimate_id).present?

      if (contact_estimate = self.estimates.find_by(id: contact_campaign.data[:contact_estimate_id])) && contact_estimate.ext_source == 'servicemonster' && (contact_job = self.jobs.find_by(ext_id: contact_estimate.ext_id))
        Contacts::Campaign.where(id: active_contact_campaign_ids).map { |cc| cc.id if cc.data.dig(:contact_estimate_id).to_i == contact_campaign.data[:contact_estimate_id].to_i || cc.data.dig(:contact_job_id).to_i == contact_job.id }.compact_blank
      else
        Contacts::Campaign.where(id: active_contact_campaign_ids).map { |cc| cc.id if cc.data.dig(:contact_estimate_id).to_i == contact_campaign.data[:contact_estimate_id].to_i }.compact_blank
      end
    elsif contact_campaign&.data&.dig(:contact_invoice_id).present?

      if (contact_invoice = self.invoices.find_by(id: contact_campaign.data[:contact_invoice_id])) && contact_invoice.ext_source == 'servicemonster' && (contact_job = self.jobs.find_by(ext_id: contact_invoice.ext_id))
        Contacts::Campaign.where(id: active_contact_campaign_ids).map { |cc| cc.id if cc.data.dig(:contact_invoice_id).to_i == contact_campaign.data[:contact_invoice_id].to_i || cc.data.dig(:contact_job_id).to_i == contact_job.id }.compact_blank
      else
        Contacts::Campaign.where(id: active_contact_campaign_ids).map { |cc| cc.id if cc.data.dig(:contact_invoice_id).to_i == contact_campaign.data[:contact_invoice_id].to_i }.compact_blank
      end
    elsif contact_campaign&.data&.dig(:contact_job_id).present?

      if (contact_job = self.jobs.find_by(id: contact_campaign.data[:contact_job_id])) && contact_job.ext_source == 'servicemonster' && (contact_estimate = self.estimates.find_by(ext_id: contact_job.ext_id))
        Contacts::Campaign.where(id: active_contact_campaign_ids).map { |cc| cc.id if cc.data.dig(:contact_job_id).to_i == contact_campaign.data[:contact_job_id].to_i || cc.data.dig(:contact_estimate_id).to_i == contact_estimate.id }.compact_blank
      else
        Contacts::Campaign.where(id: active_contact_campaign_ids).map { |cc| cc.id if cc.data.dig(:contact_job_id).to_i == contact_campaign.data[:contact_job_id].to_i }.compact_blank
      end
    elsif contact_campaign&.data&.dig(:contact_subscription_id).present?
      Contacts::Campaign.where(id: active_contact_campaign_ids).map { |cc| cc.id if cc.data.dig(:contact_subscription_id).to_i == contact_campaign.data[:contact_subscription_id].to_i }.compact_blank
    elsif contact_campaign&.data&.dig(:contact_visit_id).present?
      Contacts::Campaign.where(id: active_contact_campaign_ids).map { |cc| cc.id if cc.data.dig(:contact_visit_id).to_i == contact_campaign.data[:contact_visit_id].to_i }.compact_blank
    else
      active_contact_campaign_ids
    end
  end

  # create a query based on my_contacts_settings
  # Contact.custom_search_query()
  #   (req) user:                 (User),
  #   (opt) my_contacts_settings: (Users::Setting),
  #   (opt) broadcast:            (Boolean),
  #   (opt) page_number:          (Integer),
  #   (opt) all_pages:            (Boolean),
  #   (opt) order:                (Boolean)
  def self.custom_search_query(args = {})
    return [] unless args.dig(:user).is_a?(User)
    return args[:user].contacts.page(1).per(25) if (my_contacts_settings = args.dig(:my_contacts_settings)&.data || {}).blank?

    group_by      = false
    clients_users = args[:my_contacts_settings].contacts_list_clients_users(controller: 'my_contacts')
    contacts      = Contact.where(user_id: clients_users[:user_ids]).or(Contact.where(client_id: clients_users[:client_ids])) if clients_users.dig(:user_ids).present? || clients_users.dig(:client_ids).present?

    # CONTACTS CREATED
    if my_contacts_settings.dig(:created_at_dynamic).present?
      #  dynamic created_at period selected to include in search
      date_range = Contact.dynamic_date_range(args[:user].client.time_zone, my_contacts_settings[:created_at_dynamic])
      contacts = contacts.where(created_at: [date_range[0]..date_range[1]])
    elsif my_contacts_settings.dig(:created_at_from).present? && my_contacts_settings.dig(:created_at_to).present?
      # created_at period selected to include in search
      contacts = contacts.where(created_at: [(Time.use_zone(args[:user].client.time_zone) { Chronic.parse(my_contacts_settings[:created_at_from]) })..(Time.use_zone(args[:user].client.time_zone) { Chronic.parse(my_contacts_settings[:created_at_to]) })])
    end

    # CONTACTS UPDATED
    if my_contacts_settings.dig(:updated_at_dynamic).present?
      #  dynamic updated_at period selected to include in search
      date_range = Contact.dynamic_date_range(args[:user].client.time_zone, my_contacts_settings[:updated_at_dynamic])
      contacts = contacts.where(updated_at: [date_range[0]..date_range[1]])
    elsif my_contacts_settings.dig(:updated_at_from).present? && my_contacts_settings.dig(:updated_at_to).present?
      # created_at period selected to include in search
      contacts = contacts.where(updated_at: [(Time.use_zone(args[:user].client.time_zone) { Chronic.parse(my_contacts_settings[:updated_at_from]) })..(Time.use_zone(args[:user].client.time_zone) { Chronic.parse(my_contacts_settings[:updated_at_to]) })])
    end

    # STAGE ID
    contacts = contacts.where(stage_id: my_contacts_settings[:stage_id].to_i) if my_contacts_settings.dig(:stage_id).to_i.positive?

    # GROUP ID
    contacts = contacts.where(group_id: my_contacts_settings[:group_id].to_i) if my_contacts_settings.dig(:group_id).to_i.positive?

    # LEAD SOURCE ID
    contacts = contacts.where(lead_source_id: my_contacts_settings[:lead_source_id].to_i) if my_contacts_settings.dig(:lead_source_id).to_i.positive?

    # SLEEP
    contacts = contacts.where(sleep: my_contacts_settings[:sleep].to_bool) unless my_contacts_settings.dig(:sleep).to_s == 'all'

    # BLOCK
    contacts = contacts.where(block: my_contacts_settings[:block].to_bool) unless my_contacts_settings.dig(:block).to_s == 'all'

    # OK2TEXT
    contacts = contacts.where(ok2text: my_contacts_settings[:ok2text].to_i.zero? ? [0, nil] : my_contacts_settings[:ok2text].to_i) unless my_contacts_settings.dig(:ok2text).nil? || my_contacts_settings[:ok2text].to_i == 2

    # OK2EMAIL
    contacts = contacts.where(ok2email: my_contacts_settings[:ok2email].to_i.zero? ? [0, nil] : my_contacts_settings[:ok2email].to_i) unless my_contacts_settings.dig(:ok2email).nil? || my_contacts_settings[:ok2email].to_i == 2

    # HAS PHONE LABELS
    contacts = contacts.where(id: contacts.joins(:contact_phones).where(contact_phones: { label: my_contacts_settings[:has_number] }).group(:contact_id).order(:contact_id).pluck(:contact_id)) if my_contacts_settings.dig(:has_number).present?

    # DOES NOT HAVE PHONE LABELS
    contacts = contacts.where.not(id: contacts.joins(:contact_phones).where(contact_phones: { label: my_contacts_settings[:not_has_number] }).group(:contact_id).order(:contact_id).pluck(:contact_id)) if my_contacts_settings.dig(:not_has_number).present?

    # SEARCH STRING
    if my_contacts_settings.dig(:search_string).present?
      group_by  = true
      phone     = my_contacts_settings[:search_string].parse_phone
      firstname = my_contacts_settings[:search_string].gsub(phone, '').strip.split.length > 1 ? my_contacts_settings[:search_string].gsub(phone, '').strip.parse_name.dig(:firstname).presence : nil
      lastname  = my_contacts_settings[:search_string].gsub(phone, '').strip.split.length > 1 ? my_contacts_settings[:search_string].gsub(phone, '').strip.parse_name.dig(:lastname).presence : nil
      contacts  = contacts.string_search(my_contacts_settings[:search_string], firstname, lastname)
    end

    # TAGS
    # tags selected to exclude from search
    # MUST be processed prior to searching for Tags included
    contacts = contacts.where.not(contacts: { id: contacts.joins(:contacttags).where(contacttags: { tag_id: my_contacts_settings[:tags_exclude] }) }) if my_contacts_settings.dig(:tags_exclude).present?

    if my_contacts_settings.dig(:tags_include).present?
      # tags selected to include in search
      group_by = true

      date_range = if my_contacts_settings.dig(:contacttag_created_at_dynamic).present?
                     #  dynamic contacttag_created_at period selected to include in search
                     Contact.dynamic_date_range(args[:user].client.time_zone, my_contacts_settings[:contacttag_created_at_dynamic])
                   elsif my_contacts_settings.dig(:contacttag_created_at_from).present? && my_contacts_settings.dig(:contacttag_created_at_to).present?
                     # created_at period selected to include in search
                     [Time.use_zone(args[:user].client.time_zone) { Chronic.parse(my_contacts_settings[:contacttag_created_at_from]) }, Time.use_zone(args[:user].client.time_zone) { Chronic.parse(my_contacts_settings[:contacttag_created_at_to]) }]
                   else
                     [Time.use_zone(args[:user].client.time_zone) { Chronic.parse('01/01/2018 12:00 PM') }, Time.current]
                   end

      contacts = contacts.joins(:contacttags)
                         .where(contacttags: { tag_id: my_contacts_settings[:tags_include] })
                         .where(contacttags: { created_at: [date_range[0]..date_range[1]] })

      contacts = contacts.having('count(contacts.id) = ?', my_contacts_settings[:tags_include].size) if my_contacts_settings.dig(:all_tags).to_i == 1
    end

    # CAMPAIGNS
    if my_contacts_settings.dig(:campaign_id).to_i.positive? ||
       (my_contacts_settings.dig(:campaign_id_completed).present? && !my_contacts_settings.dig(:campaign_id_completed).to_s.casecmp?('all'))
      group_by = true

      date_range = if my_contacts_settings.dig(:campaign_id_created_at_dynamic).present?
                     #  dynamic contacttag_created_at period selected to include in search
                     Contact.dynamic_date_range(args[:user].client.time_zone, my_contacts_settings[:campaign_id_created_at_dynamic])
                   elsif my_contacts_settings.dig(:campaign_id_created_at_from).present? && my_contacts_settings.dig(:campaign_id_created_at_to).present?
                     # created_at period selected to include in search
                     [Time.use_zone(args[:user].client.time_zone) { Chronic.parse(my_contacts_settings[:campaign_id_created_at_from]) }, Time.use_zone(args[:user].client.time_zone) { Chronic.parse(my_contacts_settings[:campaign_id_created_at_to]) }]
                   else
                     [Time.use_zone(args[:user].client.time_zone) { Chronic.parse('01/01/2018 12:00 PM') }, Time.current]
                   end

      contacts = contacts.joins(:contact_campaigns)

      contacts = case my_contacts_settings.dig(:campaign_id_completed).to_s.downcase
                 when 'active'
                   contacts.where(contact_campaigns: { created_at: [date_range[0]..date_range[1]], completed: false })
                 when 'completed'
                   contacts.where(contact_campaigns: { created_at: [date_range[0]..date_range[1]], completed: true })
                 else
                   contacts.where(contact_campaigns: { created_at: [date_range[0]..date_range[1]] })
                 end

      contacts = contacts.where(contact_campaigns: { campaign_id: my_contacts_settings[:campaign_id].to_i }) if my_contacts_settings.dig(:campaign_id).to_i.positive?
    end

    # TRACKABLE LINKS
    if my_contacts_settings.dig(:trackable_link_id).to_i.positive?
      group_by = true

      date_range = if my_contacts_settings.dig(:trackable_link_id_created_at_dynamic).present?
                     #  dynamic contacttag_created_at period selected to include in search
                     Contact.dynamic_date_range(args[:user].client.time_zone, my_contacts_settings[:trackable_link_id_created_at_dynamic])
                   elsif my_contacts_settings.dig(:trackable_link_id_created_at_from).present? && my_contacts_settings.dig(:trackable_link_id_created_at_to).present?
                     # created_at period selected to include in search
                     [Time.use_zone(args[:user].client.time_zone) { Chronic.parse(my_contacts_settings[:trackable_link_id_created_at_from]) }, Time.use_zone(args[:user].client.time_zone) { Chronic.parse(my_contacts_settings[:trackable_link_id_created_at_to]) }]
                   else
                     [Time.use_zone(args[:user].client.time_zone) { Chronic.parse('01/01/2018 12:00 PM') }, Time.current]
                   end

      contacts = contacts.joins(:trackable_short_links)

      contacts = if my_contacts_settings.dig(:trackable_link_clicked).to_bool
                   #  contacts.where(id: TrackableLink.contacts_delivered(my_contacts_settings[:trackable_link_id], date_range[0], date_range[1]).count.filter_map { |k, _v| k })
                   contacts.where(trackable_short_links: { trackable_link_id: my_contacts_settings[:trackable_link_id], created_at: date_range[0]..date_range[1] })
                 else
                   #  contacts.where(id: TrackableLink.contacts_clicked(my_contacts_settings[:trackable_link_id], date_range[0], date_range[1]).count.filter_map { |k, _v| k })
                   contacts.joins(trackable_short_links: :trackable_links_hits)
                           .where(trackable_short_links: { trackable_link_id: my_contacts_settings[:trackable_link_id] })
                           .where(trackable_links_hits: { created_at: [date_range[0]..date_range[1]] })
                 end
    end

    # CUSTOM FIELDS
    if my_contacts_settings.dig(:custom_fields).present?

      date_range = if my_contacts_settings.dig(:custom_fields_updated_at_dynamic).present?
                     # dynamic custom_fields_updated_at period selected to include in search
                     Contact.dynamic_date_range(args[:user].client.time_zone, my_contacts_settings[:custom_fields_updated_at_dynamic])
                   elsif my_contacts_settings.dig(:custom_fields_updated_at_from).present? && my_contacts_settings.dig(:custom_fields_updated_at_to).present?
                     # custom_fields_updated_at period selected to include in search
                     [Time.use_zone(args[:user].client.time_zone) { Chronic.parse(my_contacts_settings[:custom_fields_updated_at_from]) }, Time.use_zone(args[:user].client.time_zone) { Chronic.parse(my_contacts_settings[:custom_fields_updated_at_to]) }]
                   else
                     [Time.use_zone(args[:user].client.time_zone) { Chronic.parse('01/01/2018 12:00 PM') }, Time.current]
                   end

      custom_field_contacts_query = args[:user].client.contacts.select('contacts.id AS id').joins(:contact_custom_fields).where(contact_custom_fields: { updated_at: [date_range[0]..date_range[1]] })
      custom_field_contacts_array = []

      ClientCustomField.where(id: my_contacts_settings[:custom_fields].pluck(:id)).find_each do |custom_field|
        selected_custom_field = my_contacts_settings[:custom_fields].find { |this_custom_field| this_custom_field[:id] == custom_field.id }

        if selected_custom_field
          custom_field_contacts_query = custom_field_contacts_query.where(contact_custom_fields: { client_custom_field_id: custom_field.id })

          case custom_field.var_type
          when 'string'
            custom_field_contacts_array += custom_field_contacts_query.where("contact_custom_fields.var_value #{selected_custom_field[:operator]} ?", (selected_custom_field[:operator] == 'ILIKE' ? "%#{selected_custom_field[:value]}%" : selected_custom_field[:value])).pluck(:id)
          when 'currency', 'numeric', 'stars'
            custom_field_contacts_array += custom_field_contacts_query.where("CAST(SUBSTRING(contact_custom_fields.var_value from '(([0-9]+.*)*[0-9]+)') AS numeric) #{selected_custom_field[:operator]} ?", selected_custom_field[:value].to_s.delete(',').to_d).pluck(:id)
          when 'date'
            custom_field_contacts_array += custom_field_contacts_query.where("to_timestamp(contact_custom_fields.var_value, 'YYYY-MM-DDTHH24:MI:SS') #{selected_custom_field[:operator]} ?", Time.use_zone(args[:user].client.time_zone) { Chronic.parse(selected_custom_field[:value]) }.utc.iso8601).pluck(:id)
          end
        end
      end

      contacts = contacts.where(contacts: { id: custom_field_contacts_array })
    end

    # TEXT MESSAGES
    if my_contacts_settings.dig(:last_msg_string).to_s.present? || my_contacts_settings.dig(:last_msg_dynamic).to_s.present? ||
       (my_contacts_settings.dig(:last_msg_direction).present? && my_contacts_settings.dig(:last_msg_direction) != 'both') ||
       (my_contacts_settings.dig(:last_msg_absolute).present? && my_contacts_settings.dig(:last_msg_absolute) != 'last') ||
       (my_contacts_settings.dig(:last_msg_from).to_s.present? && my_contacts_settings.dig(:last_msg_to).to_s.present?)
      date_range   = if my_contacts_settings.dig(:last_msg_dynamic).present?
                       #  dynamic last_msg period selected to include in search
                       Contact.dynamic_date_range(args[:user].client.time_zone, my_contacts_settings[:last_msg_dynamic])
                     elsif my_contacts_settings.dig(:last_msg_from).present? && my_contacts_settings.dig(:last_msg_to).present?
                       # last_msg period selected to include in search
                       [Time.use_zone(args[:user].client.time_zone) { Chronic.parse(my_contacts_settings[:last_msg_from]) }, Time.use_zone(args[:user].client.time_zone) { Chronic.parse(my_contacts_settings[:last_msg_to]) }]
                     else
                       []
                     end

      msg_contacts = if my_contacts_settings.dig(:last_msg_absolute) == 'all'
                       if ['', 'both'].include?(my_contacts_settings.dig(:last_msg_direction))
                         args[:user].client.contacts.select('contacts.id AS id').joins(:messages).where(messages: { msg_type: (Messages::Message::MSG_TYPES_TEXT + Messages::Message::MSG_TYPES_VOICE) })
                       elsif my_contacts_settings.dig(:last_msg_direction) == 'sent'
                         args[:user].client.contacts.select('contacts.id AS id').joins(:messages).where(messages: { msg_type: (Messages::Message::MSG_TYPES_TEXTOUT + Messages::Message::MSG_TYPES_VOICEOUT) })
                       else
                         args[:user].client.contacts.select('contacts.id AS id').joins(:messages).where(messages: { msg_type: (Messages::Message::MSG_TYPES_TEXTIN + Messages::Message::MSG_TYPES_VOICEIN) })
                       end
                     elsif ['', 'both'].include?(my_contacts_settings.dig(:last_msg_direction))
                       args[:user].client.contacts.select('contacts.id AS id, MAX(messages.created_at) AS msg_created_at').joins(:messages).where(messages: { msg_type: (Messages::Message::MSG_TYPES_TEXT + Messages::Message::MSG_TYPES_VOICE) })
                     elsif my_contacts_settings.dig(:last_msg_direction) == 'sent'
                       args[:user].client.contacts.select('contacts.id AS id, MAX(messages.created_at) AS msg_created_at').joins(:messages).where(messages: { msg_type: (Messages::Message::MSG_TYPES_TEXTOUT + Messages::Message::MSG_TYPES_VOICEOUT) })
                     else
                       args[:user].client.contacts.select('contacts.id AS id, MAX(messages.created_at) AS msg_created_at').joins(:messages).where(messages: { msg_type: (Messages::Message::MSG_TYPES_TEXTIN + Messages::Message::MSG_TYPES_VOICEIN) })
                     end
      msg_contacts = msg_contacts.where(messages: { created_at: [date_range[0]..date_range[1]] }) if date_range.length == 2
      msg_contacts = msg_contacts.where('message ILIKE ?', "%#{my_contacts_settings.dig(:last_msg_string)}%") if my_contacts_settings.dig(:last_msg_string).present?
      msg_contacts = msg_contacts.group('id').pluck(:id)
      contacts     = contacts.where(contacts: { id: msg_contacts })
    end

    # GROUPS
    if my_contacts_settings.dig(:group_id_updated_dynamic).present?
      #  dynamic group_id_updated_at period selected to include in search
      date_range = Contact.dynamic_date_range(args[:user].client.time_zone, my_contacts_settings[:group_id_updated_dynamic])
      contacts = contacts.where(group_id_updated_at: [date_range[0]..date_range[1]])
    elsif my_contacts_settings.dig(:group_id_updated_from).present? && my_contacts_settings.dig(:group_id_updated_to).present?
      # created_at period selected to include in search
      contacts = contacts.where(group_id_updated_at: [(Time.use_zone(args[:user].client.time_zone) { Chronic.parse(my_contacts_settings[:group_id_updated_from]) })..(Time.use_zone(args[:user].client.time_zone) { Chronic.parse(my_contacts_settings[:group_id_updated_to]) })])
    end

    # LEAD SOURCES
    if my_contacts_settings.dig(:lead_source_id_updated_dynamic).present?
      #  dynamic lead_source_id_updated_at period selected to include in search
      date_range = Contact.dynamic_date_range(args[:user].client.time_zone, my_contacts_settings[:lead_source_id_updated_dynamic])
      contacts = contacts.where(lead_source_id_updated_at: [date_range[0]..date_range[1]])
    elsif my_contacts_settings.dig(:lead_source_id_updated_from).present? && my_contacts_settings.dig(:lead_source_id_updated_to).present?
      # created_at period selected to include in search
      contacts = contacts.where(lead_source_id_updated_at: [(Time.use_zone(args[:user].client.time_zone) { Chronic.parse(my_contacts_settings[:lead_source_id_updated_from]) })..(Time.use_zone(args[:user].client.time_zone) { Chronic.parse(my_contacts_settings[:lead_source_id_updated_to]) })])
    end

    # STAGES
    if my_contacts_settings.dig(:stage_id_updated_dynamic).present?
      #  dynamic stage_id_updated_at period selected to include in search
      date_range = Contact.dynamic_date_range(args[:user].client.time_zone, my_contacts_settings[:stage_id_updated_dynamic])
      contacts = contacts.where(stage_id_updated_at: [date_range[0]..date_range[1]])
    elsif my_contacts_settings.dig(:stage_id_updated_from).present? && my_contacts_settings.dig(:stage_id_updated_to).present?
      # created_at period selected to include in search
      contacts = contacts.where(stage_id_updated_at: [(Time.use_zone(args[:user].client.time_zone) { Chronic.parse(my_contacts_settings[:stage_id_updated_from]) })..(Time.use_zone(args[:user].client.time_zone) { Chronic.parse(my_contacts_settings[:stage_id_updated_to]) })])
    end

    if my_contacts_settings.dig(:since_last_contact).to_i.positive?
      # only search for Contacts that have not been contacted for since_last_contact days
      contacts = contacts.where(last_contacted: ...Time.current - my_contacts_settings[:since_last_contact].to_i.days).or(contacts.where(last_contacted: nil))
    end

    contacts = contacts.group('contacts.id') if group_by

    if args.dig(:all_pages).to_bool
      # no pagination

      if args.dig(:order).to_bool && my_contacts_settings.dig(:sort, :col).to_s.present? && my_contacts_settings.dig(:sort, :dir).to_s.present?
        contacts.order(my_contacts_settings[:sort][:col].to_s.to_sym => my_contacts_settings[:sort][:dir].to_s.to_sym)
      else
        contacts
      end
    else
      # results per page range = 10 - 200
      results_per_page = my_contacts_settings.dig(:per_page).to_i.clamp(10, 200)

      if args.dig(:order).to_bool && my_contacts_settings.dig(:sort, :col).to_s.present? && my_contacts_settings.dig(:sort, :dir).to_s.present?
        contacts.order(my_contacts_settings[:sort][:col].to_s.to_sym => my_contacts_settings[:sort][:dir].to_s.to_sym).page((args.dig(:page_number) || 1).to_i).per(results_per_page)
      else
        contacts.page((args.dig(:page_number) || 1).to_i).per(results_per_page)
      end
    end
  end

  # act on a custom field
  # contact.custom_field_action()
  #   (req) client_custom_field_id:  (Integer)
  #   (opt) contact_estimate_id:     (Integer)
  #   (opt) contact_invoice_id:      (Integer)
  #   (opt) contact_job_id:          (Integer)
  #   (opt) contact_subscription_id: (Integer)
  #   (opt) contact_visit_id:        (Integer)
  #   (req) triggeraction_id:        (Integer)
  def custom_field_action(args)
    return false unless args.dig(:client_custom_field_id).to_i.positive? && args.dig(:triggeraction_id).to_i.positive? &&
                        (client_custom_field = self.client.client_custom_fields.find_by(id: args[:client_custom_field_id].to_i)) &&
                        (triggeraction = Triggeraction.find_by(id: args[:triggeraction_id].to_i))

    contact_estimate_id     = args.dig(:contact_estimate_id).to_i
    contact_invoice_id      = args.dig(:contact_invoice_id).to_i
    contact_job_id          = args.dig(:contact_job_id).to_i
    contact_subscription_id = args.dig(:contact_subscription_id).to_i
    contact_visit_id        = args.dig(:contact_visit_id).to_i
    contact_custom_field    = self.contact_custom_fields.find_by(client_custom_field_id: client_custom_field.id)

    if client_custom_field.var_type == 'string'

      if contact_custom_field&.var_value&.strip.blank?
        self.process_actions(
          campaign_id:             triggeraction.response_range.dig('empty', 'campaign_id'),
          group_id:                triggeraction.response_range.dig('empty', 'group_id'),
          stage_id:                triggeraction.response_range.dig('empty', 'stage_id'),
          tag_id:                  triggeraction.response_range.dig('empty', 'tag_id'),
          stop_campaign_ids:       triggeraction.response_range.dig('empty', 'stop_campaign_ids'),
          contact_estimate_id:,
          contact_invoice_id:,
          contact_job_id:,
          contact_subscription_id:,
          contact_visit_id:
        )
      elsif client_custom_field.image_is_valid && contact_custom_field.var_value.strip == '<image>'
        self.process_actions(
          campaign_id:             triggeraction.response_range.dig('image', 'campaign_id'),
          group_id:                triggeraction.response_range.dig('image', 'group_id'),
          stage_id:                triggeraction.response_range.dig('image', 'stage_id'),
          tag_id:                  triggeraction.response_range.dig('image', 'tag_id'),
          stop_campaign_ids:       triggeraction.response_range.dig('image', 'stop_campaign_ids'),
          contact_estimate_id:,
          contact_invoice_id:,
          contact_job_id:,
          contact_subscription_id:,
          contact_visit_id:
        )
      else
        was_processed = self.process_actions(
          campaign_id:             triggeraction.response_range.dig(contact_custom_field.var_value, 'campaign_id').to_i,
          group_id:                triggeraction.response_range.dig(contact_custom_field.var_value, 'group_id').to_i,
          stage_id:                triggeraction.response_range.dig(contact_custom_field.var_value, 'stage_id').to_i,
          tag_id:                  triggeraction.response_range.dig(contact_custom_field.var_value, 'tag_id').to_i,
          stop_campaign_ids:       triggeraction.response_range.dig(contact_custom_field.var_value, 'stop_campaign_ids'),
          contact_estimate_id:,
          contact_invoice_id:,
          contact_job_id:,
          contact_subscription_id:,
          contact_visit_id:
        )

        unless was_processed
          self.process_actions(
            campaign_id:             triggeraction.response_range.dig('invalid', 'campaign_id'),
            group_id:                triggeraction.response_range.dig('invalid', 'group_id'),
            stage_id:                triggeraction.response_range.dig('invalid', 'stage_id'),
            tag_id:                  triggeraction.response_range.dig('invalid', 'tag_id'),
            stop_campaign_ids:       triggeraction.response_range.dig('invalid', 'stop_campaign_ids'),
            contact_estimate_id:,
            contact_invoice_id:,
            contact_job_id:,
            contact_subscription_id:,
            contact_visit_id:
          )
        end
      end
    elsif %w[numeric currency stars].include?(client_custom_field.var_type)
      # process Triggeraction for numeric/currency/stars ClientCustomFields
      was_processed = false

      triggeraction.response_range.each_value do |values|
        if (values.dig('range_type').to_s == 'empty' && contact_custom_field&.var_value&.strip.blank?) ||
           (values.dig('range_type').to_s == 'range' && contact_custom_field&.var_value&.strip.present? && contact_custom_field&.var_value&.strip.to_s != '<image>' && (values.dig('minimum').to_i..values.dig('maximum').to_i).cover?(contact_custom_field&.var_value&.to_i)) ||
           (values.dig('range_type').to_s == 'image' && client_custom_field&.image_is_valid && contact_custom_field&.var_value&.strip.to_s == '<image>')

          was_processed = self.process_actions(
            campaign_id:             values.dig('campaign_id'),
            group_id:                values.dig('group_id'),
            stage_id:                values.dig('stage_id'),
            tag_id:                  values.dig('tag_id'),
            stop_campaign_ids:       values.dig('stop_campaign_ids'),
            contact_estimate_id:,
            contact_invoice_id:,
            contact_job_id:,
            contact_subscription_id:,
            contact_visit_id:
          )
        end
      end

      if !was_processed && (keys_values = triggeraction.response_range.find { |_key, values| values.dig('range_type').to_s == 'invalid' })
        self.process_actions(
          campaign_id:             keys_values[1].dig('campaign_id'),
          group_id:                keys_values[1].dig('stage_id'),
          stage_id:                keys_values[1].dig('group_id'),
          tag_id:                  keys_values[1].dig('tag_id'),
          stop_campaign_ids:       keys_values[1].dig('stop_campaign_ids'),
          contact_estimate_id:,
          contact_invoice_id:,
          contact_job_id:,
          contact_subscription_id:,
          contact_visit_id:
        )
      end
    end

    true
  end

  # find a Contact by closest match to last name & first name
  # Contact.find_by_closest_match(client_id, lastname, firstname)
  def self.find_by_closest_match(client_id, lastname, firstname)
    return nil unless client_id.to_i.positive? && lastname.present? && firstname.present?

    contact = self.find_by(client_id: client_id.to_i, lastname: lastname.to_s, firstname: firstname.to_s)
    contact ||= self.where(client_id: client_id.to_i).where('lower(lastname) = ?', lastname.to_s.downcase).find_by('lower(firstname) = ?', firstname.to_s.downcase)
    contact ||= self.where(client_id: client_id.to_i).where('lastname ILIKE ?', (lastname.length > 1 ? "%#{lastname}%" : "#{lastname}%")).find_by('firstname ILIKE ?', (firstname.length > 1 ? "%#{firstname}%" : "#{firstname}%"))
    contact ||= self.where(client_id: client_id.to_i).where('SIMILARITY(lastname, ?) > 0.4', lastname.to_s.downcase).find_by('SIMILARITY(firstname, ?) > 0.4', firstname.to_s.downcase)

    contact
  end

  # find a Contact using ext_references
  # Contact.find_by_ext_reference(model, model_id, ext_refs)
  # (req) model:    (String)  'client' or 'user'
  # (req) model_id: (Integer) Client or User ID
  # (req) ext_refs: (Hash)    { target => id, target => id, ... }
  def self.find_by_ext_reference(model, model_id, ext_refs)
    contact = nil

    ext_refs.each do |target, id|
      next if id.nil? || (id.is_a?(Integer) && !id.positive?) || (id.is_a?(String) && (id.empty? || id == '0'))

      contact = Contact.joins(:ext_references).find_by("#{model}_id": model_id, ext_references: { target:, ext_id: id })

      break if contact
    end

    contact
  end

  # Contact.find_or_initialize_by_phone_or_email_or_ext_ref()
  #   (req) client_id:             (Integer)
  #   (opt) emails:                (Array)
  #   (opt) ext_refs               (Hash) ex: { target => id, target => id, ... }
  #   (opt) phones:                (Hash) ex: { number => type, number => type, ... }
  #   (opt) update_primary_phone:  (Boolean)
  def self.find_or_initialize_by_phone_or_email_or_ext_ref(args)
    JsonLog.info 'Contact.find_or_initialize_by_phone_or_email_or_ext_ref', { args: }
    return nil unless args.dig(:client_id).positive? && (client = Client.find_by(id: args[:client_id].to_i))

    contact   = nil
    emails    = [args.dig(:emails) || []].flatten.map(&:to_s).map { |email| EmailAddress.normal(email) if EmailAddress.valid?(email) }.compact_blank - (client.contact_matching_ignore_emails || [])
    phones    = args.dig(:phones).is_a?(Hash) ? args[:phones] : {}

    contact = Contact.find_by_ext_reference('client', client.id, args[:ext_refs].compact_blank) if args.dig(:ext_refs).is_a?(Hash)
    contact = Contact.by_client_and_phone(client.id, phones.keys.compact_blank.map(&:clean_phone)).first if contact.nil? && phones.keys.compact_blank.present?
    contact = Contact.by_client_and_email(client.id, emails).first if contact.nil? && emails.present? && client.contact_matching_with_email?
    contact = client.contacts.new if contact.nil?

    contact.firstname  = 'Friend' if (contact.lastname + contact.firstname).empty?
    contact.email      = if emails.present?
                           emails[0]
                         else
                           contact.email.presence
                         end
    contact.ok2text    = 1 if contact.new_record?
    contact.ok2email   = 1 if contact.new_record?

    contact.update_contact_phones(phones, false, (args.dig(:update_primary_phone).to_bool || contact.new_record?))
    contact.update_ext_references(args[:ext_refs])

    contact
  end

  def firstname_last_initial
    [self.firstname, self.lastname[0].to_s].compact_blank.join(' ')
  end

  def firstname_or_phone
    if ['friend', ''].include?(self.firstname.downcase) && (contact_phone = self.primary_phone&.phone.to_s)
      ActionController::Base.helpers.number_to_phone(contact_phone)
    else
      self.firstname
    end
  end

  def fullname
    Friendly.new.fullname(self.firstname, self.lastname)
  end

  def fullname_or_phone
    if ['friend', ''].include?(self.fullname.downcase) && (contact_phone = self.primary_phone&.phone.to_s)
      ActionController::Base.helpers.number_to_phone(contact_phone)
    else
      self.fullname
    end
  end

  # return Contact initials
  def initials
    self.firstname[0].to_s + self.lastname[0].to_s
  end

  # return Twnumber to use for this Contact
  # contact.latest_client_phonenumber(
  #   (opt) current_session:    (Session)
  #   (opt) default_ok:         (Boolean)
  #   (opt) phone_numbers_only: (Boolean)
  def latest_client_phonenumber(args = {})
    current_session       = (args.dig(:current_session) || {}).to_h
    phone_number          = current_session.dig(:selected_number).to_s
    client_phone_numbers  = Twnumber.client_phone_numbers(self.user&.client_id).pluck(:phonenumber)
    contact_phone_numbers = self.contact_phones.pluck(:phone)

    messages = self.messages.where(from_phone: client_phone_numbers, to_phone: contact_phone_numbers).or(self.messages.where(from_phone: contact_phone_numbers, to_phone: client_phone_numbers))
    messages = messages.or(self.messages.where(msg_type: Messages::Message::MSG_TYPES_FB)).or(self.messages.where(msg_type: Messages::Message::MSG_TYPES_GGL)).or(self.messages.where(msg_type: Messages::Message::MSG_TYPES_EMAIL)) unless args.dig(:phone_numbers_only).to_bool

    messages.order(created_at: :desc).each do |message|
      if Messages::Message::MSG_TYPES_FB.include?(message.msg_type)
        phone_number = 'fb'
        break
      elsif Messages::Message::MSG_TYPES_GGL.include?(message.msg_type)
        phone_number = 'ggl'
        break
      elsif Messages::Message::MSG_TYPES_EMAIL.include?(message.msg_type)
        phone_number = 'email'
        break
      elsif client_phone_numbers.include?(message.from_phone)
        phone_number = message.from_phone
        break
      elsif client_phone_numbers.include?(message.to_phone)
        phone_number = message.to_phone
        break
      end
    end

    if phone_number.empty? && args.dig(:default_ok).to_bool
      self.user&.latest_client_phonenumber(current_session:)
    elsif phone_number.empty?
      nil
    elsif phone_number == 'fb'
      self.client.twnumbers.new(phonenumber: 'fb')
    elsif phone_number == 'ggl'
      self.client.twnumbers.new(phonenumber: 'ggl')
    elsif phone_number == 'email'
      self.client.twnumbers.new(phonenumber: 'email')
    else
      self.client&.twnumbers&.find_by(phonenumber: phone_number)
    end
  end

  # return the latest phone number used by the Contact to send a message by label
  # contact.latest_contact_phone_by_label( label: String )
  def latest_contact_phone_by_label(args = {})
    label    = args.dig(:label).to_s
    response = nil

    if label.empty?
      response = self.messages.where(from_phone: self.contact_phones.pluck(:phone)).order(created_at: :desc).pick(:from_phone)

      response = self.primary_phone&.phone.to_s if response.nil?
    else
      response = self.messages.where(from_phone: self.contact_phones.where(label:).pluck(:phone)).order(created_at: :desc).pick(:from_phone)

      if response.nil?
        primary_phone = self.primary_phone

        if primary_phone&.label.to_s == label
          response = primary_phone.phone
        elsif (contact_phone = self.contact_phones.find_by(label:))
          response = contact_phone.phone
        end
      end
    end

    response || ''
  end

  # replace Tags in message content with Contact data
  # content = contact.message_tag_replace(String)
  def message_tag_replace(message, payment_request: nil)
    # rubocop:disable Lint/InterpolationCheck
    message = message.to_s
                     .tr('‘', "'")
                     .tr('’', "'")
                     .tr('”', '"')
                     .tr('“', '"')
                     .tr(' ', ' ')

    # add payment url to the end of the message if the tag is not present
    message << "\n#{payment_request_url(contact: self, amount: payment_request)}" if payment_request&.positive? && message.exclude?('#{request_payment_link}')

    if message.include?('#{')
      message = message
                .gsub('#{firstname}', (self.firstname || ''))
                .gsub('#{lastname}', (self.lastname || ''))
                .gsub('#{fullname}', self.fullname)
                .gsub('#{companyname}', self.companyname || '')
                .gsub('#{contact-company-name}', self.companyname || '')
                .gsub('#{address1}', (self.address1 || ''))
                .gsub('#{address2}', (self.address2 || ''))
                .gsub('#{city}', (self.city || ''))
                .gsub('#{state}', (self.state || ''))
                .gsub('#{zipcode}', (self.zipcode || ''))
                .gsub('#{email}', (self.email || ''))
                .gsub('#{a-firstname}', (self.user.firstname || ''))
                .gsub('#{a-lastname}', (self.user.lastname || ''))
                .gsub('#{a-fullname}', self.user.fullname)
                .gsub('#{a-phone}', (self.user.phone ? ActionController::Base.helpers.number_to_phone(self.user.phone) : ''))
                .gsub('#{a-default-phone}', ActionController::Base.helpers.number_to_phone(self.user.default_from_twnumber&.phonenumber.to_s))
                .gsub('#{a-email}', (self.user.email || ''))
                .gsub('#{c-name}', (self.client.name || ''))
                .gsub('#{my-company-name}', (self.client.name || ''))
                .gsub('#{today}', (Time.use_zone(self.client.time_zone) { Chronic.parse(Time.current.to_s) }).strftime('%m/%d/%Y').gsub('  ', ' '))
                .gsub('#{today_ext}', (Time.use_zone(self.client.time_zone) { Chronic.parse(Time.current.to_s) }).strftime('%A, %B %d, %Y at %l:%M%P').gsub('  ', ' '))
                .gsub('#{user_ext_ref_id}', (self.user.ext_ref_id.empty? ? '' : self.user.ext_ref_id))
                .gsub('#{contact_ext_ref_id}', '')
                .gsub('#{opt_out}', 'Reply STOP to opt out')

      # request a payment if needed
      message = message.gsub('#{request_payment_link}', payment_request_url(contact: self, amount: payment_request)) if message.include?('#{request_payment_link}')

      if message.include?('#{contact-')
        ApplicationController.helpers.ext_references_options(self.client).each do |e|
          contact_ext_reference_id = self.ext_references.find_by(target: e[1])&.ext_id.to_s
          message = message.gsub(format('#{contact-%s-id}', e[1]), contact_ext_reference_id)
        end
      end

      if message.include?('#{phone-')
        contact_phones = self.contact_phones.distinct.pluck(:label, :phone).to_h

        self.client.contact_phone_labels.each do |label|
          phone   = contact_phones.dig(label).to_s
          message = message.gsub(format('#{phone-%s}', label), ActionController::Base.helpers.number_to_phone(phone))
        end
      end

      self.client.client_custom_fields.each do |ccf|
        hashtag = format('#{%s}', ccf.var_var) # '#{asdf}'

        case ccf.var_type
        when 'stars'
          if message.include?(hashtag)
            contact_custom_field = self.contact_custom_fields.find_by(client_custom_field_id: ccf.id)
            message = message.gsub(hashtag, (contact_custom_field ? ActionController::Base.helpers.pluralize(contact_custom_field.var_value.to_i, 'Star', plural: 'Stars') : '0'))
          end
        when 'currency'
          if message.include?(hashtag)
            contact_custom_field = self.contact_custom_fields.find_by(client_custom_field_id: ccf.id)
            message = message.gsub(hashtag, (contact_custom_field ? ActionController::Base.helpers.number_to_currency(contact_custom_field.var_value.to_d) : '$0.00'))
          end

          hashtag = format('\#{%s_in_text}', ccf.var_var) # '#{asdf_in_text}'

          if message.include?(hashtag)
            contact_custom_field = self.contact_custom_fields.find_by(client_custom_field_id: ccf.id)

            if contact_custom_field && contact_custom_field.var_value.to_d.positive?
              Linguistics.use(:en)
              currency = contact_custom_field.var_value.to_d.to_s.split('.')
              message = message.gsub(hashtag, "#{currency[0].en.numwords} DOLLARS AND #{format('%02d/100', currency[1].to_i)}".upcase)
            else
              message = message.gsub(hashtag, 'ZERO DOLLARS AND 00/100')
            end
          end
        when 'date'
          if message.include?(hashtag)

            if (contact_custom_field = self.contact_custom_fields.find_by(client_custom_field_id: ccf.id))
              contact_custom_field = Time.use_zone(self.client.time_zone) { Chronic.parse(contact_custom_field.var_value) }
              message = message.gsub(hashtag, (contact_custom_field ? contact_custom_field.strftime('%A, %B %d, %Y at %l:%M%P').gsub('  ', ' ') : '(undetermined)'))
            else
              message = message.gsub(hashtag, '(undetermined)')
            end
          end
        else
          if message.include?(hashtag)
            contact_custom_field = self.contact_custom_fields.find_by(client_custom_field_id: ccf.id)
            message = message.gsub(hashtag, (contact_custom_field ? contact_custom_field.var_value : ''))
          end
        end
      end

      if message.include?('#{trackable_link_')

        self.client.trackable_links.each do |tl|
          hashtag = format('#{trackable_link_%s}', tl.id.to_s) # '#{trackable_link_1234}'

          message = message.gsub(hashtag, tl.create_short_url(self)) if message.include?(hashtag)
        end
      end

      if message.include?('#{survey_link_')

        self.client.surveys.each do |s|
          hashtag = format('#{survey_link_%s}', s.id.to_s) # '#{survey_link_1234}'

          message = message.gsub(hashtag, "#{s.landing_page_url}?cid=#{self.id}") if message.include?(hashtag)
        end
      end

      if message.include?('#{google-reviews_') && (self.client.integrations_allowed.include?('google') && (client_api_integration = self.client.client_api_integrations.find_by(target: 'google', name: '')) && (user_api_integration = UserApiIntegration.find_by(user_id: client_api_integration.user_id, target: 'google', name: '')) && Integration::Google.valid_token?(user_api_integration))
        ggl_client = Integrations::Ggl::Base.new(user_api_integration.token, I18n.t('tenant.id'))

        client_api_integration.active_locations_reviews.each do |account, locations|
          locations.each do |location|
            reviews_count = ggl_client.total_reviews(account, location).to_s
            reviews_stars = ggl_client.average_reviews_rating(account, location).to_s

            message = message.gsub("\#{google-reviews_count_#{account.split('/').last}_#{location.split('/').last}}", reviews_count)
            message = message.gsub("\#{google-reviews_stars_#{account.split('/').last}_#{location.split('/').last}}", reviews_stars)
            message = message.gsub("\#{google-reviews_link_#{account.split('/').last}_#{location.split('/').last}}", client_api_integration.reviews_links.dig(account, location).to_s)
            message = message.gsub("\#{google-reviews_contact_stars}", self.reviews.order(target_created_at: :desc).first&.star_rating.to_s)
          end
        end
      end

      if message.include?('#{estimate-last_date}') || message.include?('#{estimate-time_since_last_date}')

        message = if (contact_estimate = self.estimates.where.not(scheduled_end_at: nil).order(scheduled_end_at: :desc).limit(1).first)
                    message
                      .gsub('#{estimate-last_date}', Friendly.new.date(contact_estimate.scheduled_end_at, self.client.time_zone, false))
                      .gsub('#{estimate-time_since_last_date}', ActionController::Base.helpers.time_ago_in_words(contact_estimate.scheduled_end_at, include_seconds: false))
                  else
                    message
                      .gsub('#{estimate-last_date}', '')
                      .gsub('#{estimate-time_since_last_date}', '')
                  end
      end

      if message.include?('#{job-last_date}') || message.include?('#{job-time_since_last_date}')

        message = if (contact_job = self.jobs.where.not(actual_completed_at: nil).order(actual_completed_at: :desc).limit(1).first)
                    message
                      .gsub('#{job-last_date}', Friendly.new.date(contact_job.actual_completed_at, self.client.time_zone, false))
                      .gsub('#{job-time_since_last_date}', ActionController::Base.helpers.time_ago_in_words(contact_job.actual_completed_at, include_seconds: false))
                  else
                    message
                      .gsub('#{job-last_date}', '')
                      .gsub('#{job-time_since_last_date}', '')
                  end
      end
    end
    # rubocop:enable Lint/InterpolationCheck

    message
  end

  # set ok2email on for this Contact
  # contact.ok2email_off
  def ok2email_off
    contact = Contact.find(self.id)
    contact.update(ok2email: '0')
    self.ok2email = '0'
  end

  # set ok2email on for this Contact
  # contact.ok2email_on
  def ok2email_on
    contact = Contact.find(self.id)
    contact.update(ok2email: '1')
    self.ok2email = '1'
  end

  # set ok2text off for this Contact
  # contact.ok2text_off
  def ok2text_off
    contact = Contact.find(self.id)
    contact.update(ok2text: '0')
    self.ok2text = '0'
  end

  # set ok2text on for this Contact
  # contact.ok2text_on
  def ok2text_on
    contact = Contact.find(self.id)
    contact.update(ok2text: '1')
    self.ok2text = '1'
  end

  # collect array of phone numbers based on OrgPositions
  # contact.org_users(users_orgs: String)
  def org_users(args)
    users_orgs                           = args.dig(:users_orgs).to_s
    purpose                              = (args.dig(:purpose) || 'text').to_s
    default_to_all_users_in_org_position = args.dig(:default_to_all_users_in_org_position).to_bool
    response                             = []

    if users_orgs.present?
      users_orgs = users_orgs.split('_')

      case users_orgs[0]
      when 'contact'
        contact_phones = self.contact_phones

        contact_phones = contact_phones.where(label: users_orgs[1]) if users_orgs.length == 2

        response += contact_phones.map { |contact_phone| [contact_phone.phone, "#{self.fullname} (#{contact_phone.label})"] } unless contact_phones.empty?
      when 'user'

        case users_orgs.length
        when 1

          case purpose
          when 'text'
            response << [self.user.phone, self.user.fullname] unless self.user.phone.empty?
          when 'voice'
            response << [self.user.phone_out, self.user.fullname] unless self.user.phone_out.empty?
          when 'email'
            response << [self.user.email, self.user.fullname] unless self.user.email.empty?
          end
        when 2

          if (user = self.client.users.find_by(id: users_orgs[1].to_i))

            case purpose
            when 'text'
              response << [user.phone, user.fullname] unless user.phone.empty?
            when 'voice'
              response << [user.phone_out, user.fullname] unless user.phone_out.empty?
            when 'email'
              response << [user.email, user.fullname] unless user.email.empty?
            end
          end
        end
      when 'orgposition'

        # find the Contact's User in the OrgChart
        if users_orgs.length == 2 && (org_user = self.client.org_users.find_by(user_id: self.user_id))
          response_org_users = []

          # find the User's OrgGroup & OrgPosition
          org_position = self.client.org_positions.find_by(id: users_orgs[1].to_i)

          # if that OrgPosition is related to a ContactCustomField find that ContactCustomField
          if org_position&.client_custom_field_id&.positive? && (contact_custom_field = self.contact_custom_fields.find_by(client_custom_field_id: org_position.client_custom_field_id)) && contact_custom_field.var_value.present?

            if (new_org_user_01 = self.client.org_users.find_by(org_group: org_user.org_group, org_position_id: users_orgs[1].to_i, phone: contact_custom_field.var_value))
              # found the phone number from the ContactCustomField in the OrgGroup/OrgPosition requested (write-in users)
              case purpose
              when 'text', 'voice'
                response_org_users << [new_org_user_01.phone, Friendly.new.fullname(new_org_user_01.firstname, new_org_user_01.lastname)]
              when 'email'
                response_org_users << [new_org_user_01.email, Friendly.new.fullname(new_org_user_01.firstname, new_org_user_01.lastname)]
              end
            elsif (new_org_user_01 = self.client.org_users.joins(:user).where(org_group: org_user.org_group, org_position_id: users_orgs[1].to_i).find_by(users: { phone: contact_custom_field.var_value }))
              # found the phone number from the ContactCustomField in the OrgGroup/OrgPosition requested (Users)
              case purpose
              when 'text', 'voice'
                response_org_users << [new_org_user_01.user.phone, new_org_user_01.user.fullname]
              when 'email'
                response_org_users << [new_org_user_01.user.email, new_org_user_01.user.fullname]
              end
            end
          end

          if response_org_users.empty? && (org_position&.client_custom_field_id&.zero? || default_to_all_users_in_org_position)

            self.client.org_users.where(org_group: org_user.org_group, org_position_id: users_orgs[1].to_i).find_each do |new_org_user_02|
              if new_org_user_02.user_id.positive?

                case purpose
                when 'text'
                  response_org_users << [new_org_user_02.user.phone, new_org_user_02.user.fullname] unless new_org_user_02.user.phone.empty?
                when 'voice'
                  response_org_users << [new_org_user_02.user.phone_out, new_org_user_02.user.fullname] unless new_org_user_02.user.phone_out.empty?
                when 'email'
                  response_org_users << [new_org_user_02.user.email, new_org_user_02.user.fullname] unless new_org_user_02.user.email.empty?
                end
              elsif %w[text voice].include?(purpose) && new_org_user_02.phone.present?
                response_org_users << [new_org_user_02.phone, Friendly.new.fullname(new_org_user_02.firstname, new_org_user_02.lastname)]
              elsif purpose == 'email' && new_org_user_02.email.present?
                response_org_users << [new_org_user_02.email, Friendly.new.fullname(new_org_user_02.firstname, new_org_user_02.lastname)]
              end
            end
          end

          response += response_org_users
        end
      end
    end

    response
  end

  def phone_numbers(len)
    response = ([self.primary_phone&.phone] + self.contact_phones.pluck(:phone)).uniq
    response << '' while response.length < len
    response[0, len]
  end

  # find the primary ContactPhone for a Contact
  # contact.primary_phone
  def primary_phone
    self.contact_phones.find_by(primary: true)
  end

  # process actions for Contact
  # contact.process_actions()
  #   (opt) campaign_id:                (Integer)
  #   (opt) stop_campaign_ids:          (Array<Integer|String>)
  #   (opt) contact_estimate_id:        (Integer)
  #   (opt) contact_invoice_id:         (Integer)
  #   (opt) contact_job_id:             (Integer)
  #   (opt) contact_location_id:        (Integer)
  #   (opt) contact_membership_type_id: (Integer)
  #   (opt) contact_subscription_id:    (Integer)
  #   (opt) contact_visit_id:           (Integer)
  #   (opt) group_id:                   (Integer)
  #   (opt) st_membership_id:           (Integer)
  #   (opt) stage_id:                   (Integer)
  #   (opt) tag_id:                     (Integer)
  #   (opt) user_id:                    (Integer)
  def process_actions(args = {})
    JsonLog.info 'Contact.process_actions', { args: }, contact_id: self.id
    processed_something = false

    if args.dig(:campaign_id).to_i.positive? && args.dig(:stop_campaign_ids).present?
      # we must stop, then start a campaign
      Contacts::Campaigns::StartAndStopCampaignsJob.perform_later(
        contact_id:                 self.id,
        start_campaign_id:          args.dig(:campaign_id).to_i,
        stop_campaign_ids:          args.dig(:stop_campaign_ids),
        contact_estimate_id:        args.dig(:contact_estimate_id).to_i,
        contact_invoice_id:         args.dig(:contact_invoice_id).to_i,
        contact_job_id:             args.dig(:contact_job_id).to_i,
        contact_location_id:        args.dig(:contact_location_id).to_i,
        contact_membership_type_id: args.dig(:contact_membership_type_id).to_i,
        contact_subscription_id:    args.dig(:contact_subscription_id).to_i,
        contact_visit_id:           args.dig(:contact_visit_id).to_i,
        st_membership_id:           args.dig(:st_membership_id).to_i
      )
      processed_something = true
    elsif args.dig(:campaign_id).to_i.positive?
      # start a campaign
      Contacts::Campaigns::StartJob.perform_later(
        campaign_id:                args[:campaign_id].to_i,
        client_id:                  self.client_id,
        contact_estimate_id:        args.dig(:contact_estimate_id).to_i,
        contact_id:                 self.id,
        contact_invoice_id:         args.dig(:contact_invoice_id).to_i,
        contact_job_id:             args.dig(:contact_job_id).to_i,
        contact_location_id:        args.dig(:contact_location_id).to_i,
        contact_membership_type_id: args.dig(:contact_membership_type_id).to_i,
        contact_subscription_id:    args.dig(:contact_subscription_id).to_i,
        contact_visit_id:           args.dig(:contact_visit_id).to_i,
        st_membership_id:           args.dig(:st_membership_id).to_i,
        user_id:                    self.user_id
      )

      processed_something = true
    elsif args.dig(:stop_campaign_ids).present?
      # stop campaigns
      args[:stop_campaign_ids].each do |id|
        Contacts::Campaigns::StopJob.perform_later(
          campaign_id: id.to_i.zero? ? 'all' : id.to_i,
          contact_id:  self.id,
          user_id:     self.user_id
        )
      end

      processed_something = true
    end

    if args.dig(:group_id).to_i.positive?
      Contacts::Groups::AddJob.perform_later(
        contact_id: self.id,
        group_id:   args[:group_id],
        user_id:    self.user_id
      )
      processed_something = true
    end

    if args.dig(:stage_id).to_i.positive?
      Contacts::Stages::AddJob.perform_later(
        client_id:  self.client_id,
        contact_id: self.id,
        stage_id:   args[:stage_id],
        user_id:    self.user_id
      )
      processed_something = true
    end

    if args.dig(:tag_id).to_i.positive?
      Contacts::Tags::ApplyJob.perform_later(
        contact_id: self.id,
        tag_id:     args[:tag_id],
        user_id:    self.user_id
      )
      processed_something = true
    end

    processed_something
  end

  # remove a system defined Tag denoting that the Contact opted out of further text communications
  # contact.remove_stop_tag
  def remove_stop_tag
    self.client.tags.where(name: ['Opted Out', 'Opted out', 'opted Out', 'opted out', 'OPTED OUT']).find_each do |tag|
      Contacts::Tags::RemoveJob.perform_now(
        contact_id: self.id,
        tag_id:     tag.id
      )
    end
  end

  # DEPRECATED (delete after 2026-08-02)
  # replaced by Contacts::Tags::RemoveJob
  # remove a Tag from a Contact
  # contact.remove_tag()
  def remove_tag(tag_id)
    return unless tag_id.to_i.positive?

    self.contacttags.where(tag_id: tag_id.to_i).destroy_all
  end

  def scheduled_actions?
    self.scheduled_actions.any?
  end

  def scheduled_actions
    self.delayed_jobs.where(process: %w[send_email send_rvm send_text start_campaign stop_campaign]).order(run_at: :asc)
  end

  def scheduled_actions_count
    self.scheduled_actions.count
  end

  # send a email to this Contact
  # @contact.send_email(content: String, subject: String)
  # (req)
  #   (req) email_template_id: (Integer)
  #   ~ or ~
  #   (req) subject:           (String) email subject
  #   (req) content:           (String) email body
  #
  #   (opt) automated:            (Boolean)
  #   (opt) bcc_email:            (Array or String)
  #            [{ email: '', name: ''}]
  #   (opt) cc_email:             (Array or String)
  #            [{ email: '', name: ''}]
  #   (opt) content:              (String) email body
  #   (opt) email_template_yield: (String)
  #   (opt) file_attachements:    (Array) Array of file attachments that includes a signed_id pointing to an ActiveStorage::Blob, as well as filename and content_type
  #   (opt) from_email:           (Hash or String) email to send from / blank for User email
  #            { email: '', name: ''}
  #   (opt) reply_email:          (Hash or String)
  #            { email: '', name: ''}
  #   (opt) subject:              (String) email subject
  #   (opt) to_email:             (Array or String)
  #            [{ email: '', name: ''}]
  #   (opt) triggeraction_id:     (Integer) Triggeraction that initiated this message
  #
  def send_email(args = {})
    return unless self.ok2email.to_i == 1 && self.client.active?
    return unless (args.dig(:email_template_id).to_i.positive? && (email_template = self.client.email_templates.find_by(id: args.dig(:email_template_id)))) || ((args.dig(:email_template_yield).present? || args.dig(:content).present?) && args.dig(:subject).present?)

    JsonLog.info 'Contact#send_email', { args: }, contact_id: self.id

    payment_request = args.dig(:payment_request)

    # set email template for default/generic template
    # if args[:email_template_id] is not specified then leave email_template nil. this would be caused by old calls to Contact#send_email in DelayedJob
    email_template ||= EmailTemplate.new(subject: args[:subject], content: "\#{custom_email_section}") if args.include?(:email_template_id) && args.dig(:email_template_id).to_i.zero?

    # use the Contact email if to_email not provided
    to_email         = if args.dig(:to_email).is_a?(Array)
                         args[:to_email]
                       else
                         args.dig(:to_email).is_a?(String) && args[:to_email].present? ? args[:to_email].split(',').map { |email| { email: email.strip, name: '' } } : [{ email: self.email, name: self.fullname }]
                       end
    # use the User email if from_email not provided
    from_email       = if args.dig(:from_email).is_a?(Hash)
                         args[:from_email]
                       else
                         args.dig(:from_email).is_a?(String) && args[:from_email].present? ? { email: args[:from_email], name: '' } : { email: self.user.email, name: self.user.fullname }
                       end
    cc_email         = if args.dig(:cc_email).is_a?(Array)
                         args[:cc_email]
                       else
                         args.dig(:cc_email).is_a?(String) && args[:cc_email].present? ? args[:cc_email].split(',').map { |email| { email: email.strip, name: '' } } : []
                       end
    bcc_email        = if args.dig(:bcc_email).is_a?(Array)
                         args[:bcc_email]
                       else
                         args.dig(:bcc_email).is_a?(String) && args[:bcc_email].present? ? args[:bcc_email].split(',').map { |email| { email: email.strip, name: '' } } : []
                       end
    reply_email      = if args.dig(:reply_email).is_a?(Hash)
                         args[:reply_email]
                       else
                         args.dig(:reply_email).is_a?(String) && args[:reply_email].present? ? { email: args[:reply_email], name: '' } : from_email
                       end
    triggeraction    = Triggeraction.find_by(id: args.dig(:triggeraction_id))

    return unless from_email.present? && to_email.any? { |to| to[:email].present? }

    # get content for v2 EmailTemplate if it doesn't exist
    email_template.render_content if email_template && !email_template.new_record? && email_template.content.blank? && email_template.v2?

    content_yield = triggeraction&.email_template_yield.presence || args.dig(:email_template_yield).presence || args.dig(:content).presence

    content = (email_template&.content.presence || args.dig(:email_template_yield).presence || args.dig(:content).presence).to_s.gsub("\#{custom_email_section}", content_yield.to_s)
    content = self.message_tag_replace(content, payment_request:)
    subject = self.message_tag_replace((args.dig(:subject) || email_template&.subject).to_s)

    if args.dig(:contact_estimate_id).to_i.positive? && (contact_estimate = self.estimates.find_by(id: args[:contact_estimate_id]))
      content = contact_estimate.message_tag_replace(content)
      subject = contact_estimate.message_tag_replace(subject)
    end

    if args.dig(:contact_invoice_id).to_i.positive? && (contact_invoice = self.invoices.find_by(id: args[:contact_invoice_id]))
      content = contact_invoice.message_tag_replace(content)
      subject = contact_invoice.message_tag_replace(subject)
    end

    if args.dig(:contact_job_id).to_i.positive? && (contact_job = self.jobs.find_by(id: args[:contact_job_id]))
      content = contact_job.message_tag_replace(content)
      subject = contact_job.message_tag_replace(subject)
    end

    if args.dig(:contact_subscription_id).to_i.positive? && (contact_subscription = self.subscriptions.find_by(id: args[:contact_subscription_id]))
      content = contact_subscription.message_tag_replace(content)
      subject = contact_subscription.message_tag_replace(subject)
    end

    if args.dig(:contact_visit_id).to_i.positive? && (contact_visit = self.visits.find_by(id: args[:contact_visit_id]))
      content = contact_visit.message_tag_replace(content)
      subject = contact_visit.message_tag_replace(subject)
    end

    # convert links tagged as attachments to email attachments
    parsed_content = Nokogiri::HTML.parse(content)
    attachments    = []

    parsed_content.xpath('//a').each do |e|
      if e.attributes.dig('title')&.content.to_s[0, 11] == 'attachment_'
        attachments << {
          content:     Base64.strict_encode64(Faraday.get(e.attributes.dig('href').content).body),
          type:        'text/html',
          filename:    e.attributes.dig('title').content[11..],
          disposition: 'attachment'
        }
        e.parent.replace('')
      end
    end

    # attach direct attachments
    args.dig(:file_attachments)&.each do |attachment|
      blob = ActiveStorage::Blob.find_signed(attachment[:id])
      next unless blob

      attachments << {
        content:     Base64.strict_encode64(blob.download),
        type:        attachment[:content_type],
        filename:    attachment[:filename],
        disposition: 'attachment'
      }
    end

    content = parsed_content.to_html

    e_client = Email::Base.new
    e_client.send(
      client:      self.client,
      from_email:,
      to_email:,
      cc_email:,
      bcc_email:,
      reply_email:,
      subject:,
      content:,
      contact_id:  self.id,
      attachments:
    )

    message = self.messages.create({
                                     account_sid:   0,
                                     automated:     args.dig(:automated).to_bool,
                                     cost:          0,
                                     error_code:    e_client.error,
                                     error_message: e_client.message,
                                     from_phone:    from_email.dig(:email).to_s,
                                     message:       subject,
                                     message_sid:   0,
                                     msg_type:      'emailout',
                                     read_at:       Time.current,
                                     status:        (e_client.success? ? 'sent' : 'failed'),
                                     to_phone:      to_email.first&.dig(:email).to_s,
                                     triggeraction:
                                   })

    JsonLog.info 'Contact#send_email', { message_id: message.id }, contact_id: self.id

    # Messages::Email.where(html_body: "<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\" \"http://www.w3.org/TR/REC-html40/loose.dtd\">\n\n").last
    if content.strip == '<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">' || content.strip == ''
      error = ContactEmailNoBodyError.new("Email sent to Contact #{self.fullname} (#{self.id}) with no body")
      error.set_backtrace(BC.new.clean(caller))

      Appsignal.report_error(error) do |transaction|
        # Only needed if it needs to be different or there's no active transaction from which to inherit it
        Appsignal.set_action('Contact.send_email')

        # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
        Appsignal.add_params(args)

        Appsignal.set_tags(
          error_level: 'error',
          error_code:  0
        )
        Appsignal.add_custom_data(
          messages_message_id: message.id,
          file:                __FILE__,
          line:                __LINE__
        )
      end
    end

    message_email = message.create_email(
      html_body:  content,
      bcc_emails: bcc_email.map { |e| e.dig(:email) },
      cc_emails:  cc_email.map { |e| e.dig(:email) },
      to_emails:  [to_email]
    )

    attachments.each do |attachment|
      begin
        blob = ActiveStorage::Blob.create_and_upload!(
          io:           StringIO.new(Base64.decode64(attachment.dig(:content))),
          filename:     attachment.dig(:filename).to_s,
          content_type: attachment.dig(:type).to_s
        )

        message_email.images.attach(blob)
      rescue StandardError => e
        e.set_backtrace(BC.new.clean(caller))

        Appsignal.report_error(e) do |transaction|
          # Only needed if it needs to be different or there's no active transaction from which to inherit it
          Appsignal.set_action('Contact.send_email')

          # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
          Appsignal.add_params(args)

          Appsignal.set_tags(
            error_level: 'error',
            error_code:  0
          )
          Appsignal.add_custom_data(
            attachment:    attachment.inspect,
            attachments:   attachments.inspect,
            message_email: message_email.inspect,
            file:          __FILE__,
            line:          __LINE__
          )
        end
      end
    end

    # update Contact list in Message Central and navbar
    show_live_messenger = ShowLiveMessenger.new(message:)
    show_live_messenger.queue_broadcast_active_contacts
    show_live_messenger.queue_broadcast_message_thread_message

    self.update(last_contacted: Time.current)
  end

  def send_fb_message(args)
    automated           = args.dig(:automated).to_bool
    content             = args.dig(:content).to_s
    image_id_array      = args.dig(:image_id_array) || []
    msg_type            = Messages::Message::MSG_TYPES_FB.include?(args.dig(:msg_type).to_s.downcase) ? args[:msg_type].to_s.downcase : 'fbout'
    page_id             = args.dig(:page_id).to_s
    page_scoped_id      = args.dig(:page_scoped_id).to_s
    page_token          = args.dig(:page_token).to_s
    triggeraction_id    = args.dig(:triggeraction_id)

    return false if page_id.empty? || page_scoped_id.empty? || page_token.empty? || (content.empty? && image_id_array.blank?) || !self.client.active?

    # collect images & video
    image_id_hash, _video_id_array = parse_image_id_array(self, image_id_array)

    # replace all hashtags in content
    content = self.message_tag_replace(content)

    fb_client = Integrations::FaceBook::Base.new

    if content.present?
      fb_client.messenger_send(page_token:, page_scoped_id:, content:)

      message = self.messages.create({
                                       account_sid:   '',
                                       automated:,
                                       cost:          0.0,
                                       error_code:    fb_client.error,
                                       error_message: fb_client.message,
                                       from_phone:    page_id,
                                       message:       content,
                                       message_sid:   fb_client.result.dig(:message_id).to_s,
                                       msg_type:,
                                       status:        (fb_client.success? ? 'sent' : 'undelivered'),
                                       to_phone:      fb_client.result.dig(:recipient_id).to_s,
                                       triggeraction: Triggeraction.find_by(id: triggeraction_id)
                                     })

      # update Contact list in Message Central and navbar
      if message
        show_live_messenger = ShowLiveMessenger.new(message:)
        show_live_messenger.queue_broadcast_active_contacts
        show_live_messenger.queue_broadcast_message_thread_message
      end
    end

    image_id_hash.each do |id, url|
      fb_client.messenger_send(page_token:, page_scoped_id:, content: url, media_type: 'image')

      message = self.messages.create({
                                       automated:,
                                       account_sid:   '',
                                       cost:          0.0,
                                       error_code:    fb_client.error,
                                       error_message: fb_client.message,
                                       from_phone:    page_id,
                                       message:       content,
                                       message_sid:   fb_client.result.dig(:message_id).to_s,
                                       msg_type:,
                                       status:        (fb_client.success? ? 'sent' : 'undelivered'),
                                       to_phone:      fb_client.result.dig(:recipient_id).to_s,
                                       triggeraction: Triggeraction.find_by(id: triggeraction_id)
                                     })
      message.attachments.create(contact_attachment_id: id)

      # update Contact list in Message Central and navbar
      if message
        show_live_messenger = ShowLiveMessenger.new(message:)
        show_live_messenger.queue_broadcast_active_contacts
        show_live_messenger.queue_broadcast_message_thread_message
      end
    end

    self.update(last_contacted: Time.current) if fb_client.success?
    self.clear_unread_messages(self.user) unless automated

    true
  end

  def send_ggl_message(args)
    agent_id            = args.dig(:agent_id).to_s
    automated           = args.dig(:automated).to_bool
    content             = args.dig(:content).to_s
    conversation_id     = args.dig(:conversation_id).to_s
    image_id_array      = args.dig(:image_id_array) || []
    msg_type            = Messages::Message::MSG_TYPES_GGL.include?(args.dig(:msg_type).to_s.downcase) ? args[:msg_type].to_s.downcase : 'gglout'
    triggeraction_id    = args.dig(:triggeraction_id)

    return false if agent_id.empty? || conversation_id.empty? || (content.empty? && image_id_array.blank?) || !self.client.active?

    # collect images & video
    image_id_hash, _video_id_array = parse_image_id_array(self, image_id_array)

    # replace all hashtags in content
    content = self.message_tag_replace(content)

    client_api_integration = self.client.client_api_integrations.find_by(target: 'google', name: '')
    ggl_client = Integrations::Ggl::Base.new(client_api_integration.token, I18n.t('tenant.id'))

    if content.present?
      ggl_client.send_message(content:, agent_id:, conversation_id:)

      message = self.messages.create({
                                       account_sid:   '',
                                       automated:,
                                       cost:          0.0,
                                       error_code:    ggl_client.error,
                                       error_message: ggl_client.message,
                                       from_phone:    conversation_id,
                                       message:       content,
                                       message_sid:   ggl_client.result.dig(:name).to_s,
                                       msg_type:,
                                       status:        (ggl_client.success? ? 'sent' : 'undelivered'),
                                       to_phone:      ggl_client.result.dig(:recipient_id).to_s,
                                       triggeraction: Triggeraction.find_by(id: triggeraction_id)
                                     })

      # update Contact list in Message Central and navbar
      if message
        show_live_messenger = ShowLiveMessenger.new(message:)
        show_live_messenger.queue_broadcast_active_contacts
        show_live_messenger.queue_broadcast_message_thread_message
      end
    end

    image_id_hash.each do |id, url|
      ggl_client.send_message(content: url, agent_id:, conversation_id:)

      message = self.messages.create({
                                       automated:,
                                       account_sid:   '',
                                       cost:          0.0,
                                       error_code:    ggl_client.error,
                                       error_message: ggl_client.message,
                                       from_phone:    conversation_id,
                                       message:       content,
                                       message_sid:   ggl_client.result.dig(:message_id).to_s,
                                       msg_type:,
                                       status:        (ggl_client.success? ? 'sent' : 'undelivered'),
                                       to_phone:      ggl_client.result.dig(:recipient_id).to_s,
                                       triggeraction: Triggeraction.find_by(id: triggeraction_id)
                                     })
      message.attachments.create(contact_attachment_id: id)

      # update Contact list in Message Central and navbar
      if message
        show_live_messenger = ShowLiveMessenger.new(message:)
        show_live_messenger.queue_broadcast_active_contacts
        show_live_messenger.queue_broadcast_message_thread_message
      end
    end

    self.update(last_contacted: Time.current) if ggl_client.success?
    self.clear_unread_messages(self.user) unless automated

    true
  end

  # send a ringless voicemail to this Contact
  # contact.send_rvm(
  #   from_phone: String,
  #   voice_recording_id: Integer,
  #   rvm_url: String,
  #   triggeraction_id: Integer
  # )
  def send_rvm(args)
    from_phone          = args.dig(:from_phone).to_s.strip.downcase
    from_phone          = self.user.default_from_twnumber&.phonenumber.to_s if from_phone == 'user_number'
    from_phone          = self.latest_client_phonenumber(default_ok: true, phone_numbers_only: true)&.phonenumber.to_s if from_phone == 'last_number' || from_phone.blank?
    message             = args.dig(:message).to_s
    to_phone            = (args.dig(:to_phone) || self.primary_phone&.phone).to_s
    triggeraction_id    = args.dig(:triggeraction_id)
    user                = args.dig(:user)
    voice_recording_id  = args.dig(:voice_recording_id).to_i
    voice_recording_url = args.dig(:voice_recording_url).to_s

    return { success: false, session_id: '', number_of_phone: '', error_code: '1000000', error_message: 'Client is NOT Active' } unless self.client.active?
    return { success: false, session_id: '', number_of_phone: '', error_code: '1000001', error_message: 'From Phone NOT Defined' } if from_phone.empty?

    response = if (self.client.current_balance.to_f / BigDecimal(100)) >= self.client.rvm_credits.to_d
                 # account credits sufficient
                 RinglessVoicemail.send_rvm(from_phone:, to_phone:, media_url: voice_recording_url, title: "client-#{self.client_id}", tenant: self.client.tenant)
               else
                 # account credits NOT insufficient
                 { success: false, session_id: '', number_of_phone: '', error_code: '1000001', error_message: 'Insufficient Client Funds' }
               end

    message = self.messages.create({
                                     account_sid:        Rails.application.credentials[:slybroadcast][:uid],
                                     automated:          true,
                                     cost:               0.10,
                                     error_code:         response[:error_code],
                                     error_message:      response[:error_message],
                                     from_phone:,
                                     message:            "Ringless VM: #{message}",
                                     message_sid:        response[:session_id],
                                     msg_type:           'rvmout',
                                     read_at:            Time.current,
                                     status:             (response[:success] ? 'sent' : 'undelivered'),
                                     to_phone:,
                                     triggeraction_id:,
                                     user:,
                                     voice_recording_id:
                                   })

    # update Contact list in Message Central and navbar
    show_live_messenger = ShowLiveMessenger.new(message:)
    show_live_messenger.queue_broadcast_active_contacts
    show_live_messenger.queue_broadcast_message_thread_message

    self.update(last_contacted: Time.current) if response[:success]

    response
  end

  # send a text message to this Contact
  # contact.send_text(content: String)
  def send_text(args = {})
    from_phone          = args.dig(:from_phone).to_s.strip.downcase
    from_phone          = self.user.default_from_twnumber&.phonenumber.to_s if from_phone == 'user_number'
    from_phone          = self.latest_client_phonenumber(default_ok: true, phone_numbers_only: true)&.phonenumber.to_s if from_phone == 'last_number' || from_phone.empty?
    response            = true
    to_label            = args.dig(:to_label).to_s
    to_label_fallback   = args.dig(:to_label_fallback).to_s
    to_phones           = args.dig(:to_phone).to_s.present? ? [args[:to_phone].to_s] : [self.primary_phone&.phone.to_s]

    # to_label supersedes to_phone
    # ex: "contact", "contact_mobile"
    to_phones  = [self.primary_phone&.phone.to_s].compact_blank if to_label.to_s.casecmp?('primary')
    to_phones  = [self.latest_contact_phone_by_label(label: to_label)].compact_blank if to_label.present? && !to_label.to_s.casecmp?('primary') && !to_label.to_s.casecmp?('technician')
    to_phones  = [self.latest_contact_phone_by_label(label: to_label_fallback)].compact_blank if to_phones.blank? && to_label_fallback.present?
    to_phones -= self.contact_phones.pluck(:phone) unless self.ok2text.to_i == 1

    to_phones.each do |to_phone|
      result = text_send(
        automated:               args.dig(:automated).to_bool,
        client:                  self.client,
        contact:                 self,
        content:                 args.dig(:content).to_s,
        from_phone:,
        image_id_array:          args.dig(:image_id_array) || [],
        msg_type:                args.include?(:msg_type) && Messages::Message::MSG_TYPES_TEXTOUT.include?(args[:msg_type].to_s.downcase) ? args[:msg_type].to_s.downcase : 'textout',
        payment_request:         args.dig(:payment_request),
        to_phone:,
        triggeraction_id:        args.dig(:triggeraction_id),
        aiagent_session_id:      args.dig(:aiagent_session_id),
        sending_user:            args.dig(:user) || self.user,
        contact_estimate_id:     args.dig(:contact_estimate_id),
        contact_invoice_id:      args.dig(:contact_invoice_id),
        contact_job_id:          args.dig(:contact_job_id),
        contact_subscription_id: args.dig(:contact_subscription_id),
        contact_visit_id:        args.dig(:contact_visit_id)
      )

      # only set to false if any text fails
      response = result[:success]
    end

    Contacts::Campaigns::Triggeraction.completed(args.dig(:contact_campaign_id), args.dig(:triggeraction_id))

    response
  end

  # send Contact data to Five9
  def send_to_five9(args = {})
    action = args.dig(:action).to_s

    return unless self.client.active? && self.client.integrations_allowed.include?('five9') &&
                  %w[book create update].include?(action) &&
                  (client_api_integration = ClientApiIntegration.find_by(client_id: self.client_id, target: 'five9', name: '')) &&
                  client_api_integration.contact_lists.dig(action).to_s.present?

    contact_hash = Integration::Five9::Base.new(client_api_integration).call(:contact_prep_for_five9, self)
    Integrations::FiveNine::Base.new(client_api_integration.credentials).delay(
      priority:   DelayedJob.job_priority('add_contact_to_five9_list'),
      queue:      DelayedJob.job_queue('add_contact_to_five9_list'),
      process:    'add_contact_to_five9_list',
      contact_id: self.id,
      user_id:    self.user_id,
      data:       { contact: contact_hash, list_name: client_api_integration.contact_lists[action].to_s }
    ).call(:add_contact_to_list, { contact: contact_hash, list_name: client_api_integration.contact_lists[action].to_s })
  end

  # send Contact data to Five9
  def send_to_outreach
    return unless self.client.active? && self.client.integrations_allowed.include?('outreach') &&
                  (user_api_integration = UserApiIntegration.find_by(user_id: self.user_id, target: 'outreach')) &&
                  user_api_integration.webhook_actions.map(&:deep_symbolize_keys).find { |w| w.dig(:resource).to_s == 'prospect' && w.dig(:action).to_s == 'updated' }

    contact_hash = {
      firstname:     self.firstname,
      lastname:      self.lastname,
      address1:      self.address1,
      address2:      self.address2,
      city:          self.city,
      state:         self.state,
      zipcode:       self.zipcode,
      birthdate:     self.birthdate,
      outreach_id:   self.ext_references.find_by(target: 'outreach')&.ext_id.to_s,
      email:         self.email,
      mobile_phones: self.contact_phones.where(label: 'mobile').map { |contact_phone| "+1#{contact_phone.phone}" },
      home_phones:   self.contact_phones.where(label: 'home').map { |contact_phone| "+1#{contact_phone.phone}" },
      work_phones:   self.contact_phones.where(label: 'work').map { |contact_phone| "+1#{contact_phone.phone}" }
    }

    Integrations::OutReach.new(user_api_integration.token, user_api_integration.refresh_token, user_api_integration.expires_at, self.client.tenant).delay(
      priority:   DelayedJob.job_priority('send_to_outreach'),
      queue:      DelayedJob.job_queue('send_to_outreach'),
      process:    'send_to_outreach',
      contact_id: self.id,
      user_id:    self.user_id,
      data:       { contact: contact_hash }
    ).prospect_update(contact_hash)
  end

  # process SalesRabbit integrations
  def send_to_salesrabbit
    return unless self.client.active? && self.client.integrations_allowed.include?('salesrabbit') && (contact_ext_reference = self.ext_references.find_by(target: 'salesrabbit')) &&
                  (client_api_integration = self.user.client.client_api_integrations.find_by(target: 'salesrabbit', name: '')) && client_api_integration.api_key.present?

    Integrations::SalesRabbit::Base.new(client_api_integration.api_key).delay(
      priority:   DelayedJob.job_priority('send_to_salesrabbit'),
      queue:      DelayedJob.job_queue('send_to_salesrabbit'),
      process:    'send_to_salesrabbit',
      contact_id: self.id,
      user_id:    self.user_id
    ).put_lead(
      lead_id:   contact_ext_reference.ext_id,
      lastname:  self.lastname,
      firstname: self.firstname,
      phone:     self.primary_phone&.phone.to_s,
      email:     self.email
    )
  end

  # send a message to a Slack channel
  def send_to_slack(args = {})
    error_message = ''

    slack_channel           = args.dig(:slack_channel).to_s
    message                 = args.dig(:message).to_s
    contact_estimate_id     = args.dig(:contact_estimate_id)
    contact_invoice_id      = args.dig(:contact_invoice_id)
    contact_job_id          = args.dig(:contact_job_id)
    contact_subscription_id = args.dig(:contact_subscription_id)
    contact_visit_id        = args.dig(:contact_visit_id)

    return unless self.client.active?

    if message.blank?
      error_message = 'Message must be defined.'
    elsif slack_channel.blank?
      error_message = 'Slack channel must be defined.'
    elsif (user_api_integration = self.user.user_api_integrations.find_by(target: 'slack', name: '')).nil? || user_api_integration.token.blank?
      error_message = 'User must have a Slack connection.'
    end

    if contact_estimate_id.to_i.positive? && (contact_estimate = self.estimates.find_by(id: contact_estimate_id))
      message = contact_estimate.message_tag_replace(message)
    end

    if contact_invoice_id.to_i.positive? && (contact_invoice = self.invoices.find_by(id: contact_invoice_id))
      message = contact_invoice.message_tag_replace(message)
    end

    if contact_job_id.to_i.positive? && (contact_job = self.jobs.find_by(id: contact_job_id))
      message = contact_job.message_tag_replace(message)
    end

    if contact_subscription_id.to_i.positive? && (contact_subscription = self.jobs.find_by(id: contact_subscription_id))
      message = contact_subscription.message_tag_replace(message)
    end

    if contact_visit_id.to_i.positive? && (contact_visit = self.visits.find_by(id: contact_visit_id))
      message = contact_visit.message_tag_replace(message)
    end

    if error_message.blank?
      Integrations::Slack::PostMessageJob.perform_later(
        channel: self.message_tag_replace(slack_channel),
        content: self.message_tag_replace(message),
        token:   user_api_integration.token
      )
    else
      Users::SendPushOrTextJob.perform_later(
        content:    "A message could not be sent to Slack channel (#{self.message_tag_replace(slack_channel)}) for #{self.user.fullname}. #{error_message} Contact: #{self.fullname}.",
        contact_id: self.id,
        from_phone: self.user.default_from_twnumber&.phonenumber.to_s,
        user_id:    self.user_id
      )
    end
  end

  # send Contact to a URL
  # contact.send_to_url()
  #   webhooks: (Hash)
  def send_to_url(webhooks)
    return unless webhooks.is_a?(Hash) && self.client.active?

    webhooks.each_value do |values|
      next if values.dig(:url).blank? || values.dig(:fields).blank?

      contact_fields       = (::Webhook.internal_key_hash(self.client, 'contact', %w[personal]).keys + %w[ok2text ok2email last_updated last_contacted notes tags trusted_form_token trusted_form_cert_url trusted_form_ping_url]) & (values.dig(:fields) || [])
      ext_reference_fields = ::Webhook.internal_key_hash(self.client, 'contact', %w[ext_references]).keys & (values.dig(:fields) || [])
      phone_fields         = (::Webhook.internal_key_hash(self.client, 'contact', %w[phones]).keys + %w[phone_primary]) & (values.dig(:fields) || [])
      custom_fields        = ::Webhook.internal_key_hash(self.client, 'contact', %w[custom_fields]).keys & (values.dig(:fields) || [])
      user_fields          = ::Webhook.internal_key_hash(self.client, 'contact', %w[user]).keys & (values.dig(:fields) || [])
      data                 = {}

      contact_fields.each do |field|
        data[field.to_sym] = case field
                             when 'ok2text'
                               self.ok2text.to_i == 1 ? 'yes' : 'no'
                             when 'ok2email'
                               self.ok2email.to_i == 1 ? 'yes' : 'no'
                             when 'birthdate'
                               self.birthdate&.strftime('%Y/%m/%d').to_s
                             when 'last_updated'
                               self.updated_at.in_time_zone(self.client.time_zone).strftime('%Y/%m/%d %T')
                             when 'last_contacted'
                               self.last_contacted&.in_time_zone(self.client.time_zone)&.strftime('%Y/%m/%d %T').to_s
                             when 'notes'
                               ActionController::Base.helpers.safe_join(self.notes.pluck(:note), ', ')
                             when 'tags'
                               ActionController::Base.helpers.safe_join(self.tags.pluck(:name), ',')
                             when 'trusted_form_token'
                               self.trusted_form&.dig(:token).to_s
                             when 'trusted_form_cert_url'
                               self.trusted_form&.dig(:cert_url).to_s
                             when 'trusted_form_ping_url'
                               self.trusted_form&.dig(:ping_url).to_s
                             else
                               self.send(field).to_s
                             end
      end

      if ext_reference_fields.present?
        ext_references = self.ext_references.pluck(:target, :ext_id).to_h

        ext_reference_fields.each do |field|
          data[field.to_sym] = ext_references.dig(field.sub('contact-', '').sub('-id', '')).to_s
        end
      end

      if phone_fields.present?
        phones = self.contact_phones.pluck(:label, :phone).to_h

        phone_fields.each do |field|
          data[field.to_sym] = if field == 'phone_primary'
                                 self.primary_phone&.phone.to_s
                               else
                                 phones.dig(field.sub('phone_', '')).to_s
                               end
        end
      end

      if custom_fields.present?
        client_custom_fields = self.contact_custom_fields.where(client_custom_field_id: client.client_custom_fields.where(var_var: custom_fields).pluck(:id)).includes(:client_custom_field).pluck(:'client_custom_fields.var_var', :var_value).to_h

        custom_fields.each do |field|
          data[field.to_sym] = client_custom_fields.dig(field).to_s
        end
      end

      user_fields.each do |field|
        data[field.to_sym] = case field
                             when 'user_name'
                               self.user.fullname.to_s
                             when 'user_id'
                               self.user_id.to_s
                             when 'user_phone'
                               self.user.phone.to_s
                             end
      end

      Integrations::WebHook.new.delay(
        run_at:     Time.current,
        priority:   DelayedJob.job_priority('webhook_action'),
        queue:      DelayedJob.job_queue('webhook_action'),
        process:    'webhook_action',
        contact_id: self.id,
        user_id:    self.user_id,
        data:       { url: values.dig(:url).to_s, data: }
      ).send_json_to_url(values.dig(:url).to_s, data)
      # Integrations::WebHook.new.send_json_to_url(values.dig(:url).to_s, data)
    end
  end

  # send Contact data to Zapier
  #   (req) action:   (String)
  #   (opt) tag_data: (Hash)
  def send_to_zapier(args = {})
    return unless args.dig(:action).to_s.present?

    # process Tags for all Users / anything else only for User to whom Contact belongs
    user_ids = %w[receive_new_tag receive_remove_tag].include?(args[:action].to_s) ? self.client.users.pluck(:id) : [self.user_id]

    UserApiIntegration.where(user_id: user_ids, target: 'zapier', name: args[:action]).find_each do |user_api_integration|
      Integrations::Zapier::SendJob.set(wait_until: args[:action].to_s.include?('_new_') ? Time.current : 20.seconds.from_now).perform_later(
        action:                  args[:action],
        contact_id:              self.id,
        process:                 "zapier_#{args[:action]}",
        user_api_integration_id: user_api_integration.id,
        user_id:                 user_api_integration.user_id,
        tag_data:                args.dig(:tag_data).is_a?(Hash) ? args[:tag_data] : {}
      )
    end
  end

  # send Contact data to Xencall
  # contact.send_to_xencall( tag_id: Integer )
  def send_to_xencall(params)
    tag_id = params.include?(:tag_id) ? params[:tag_id].to_s : '0'

    return unless self.client.active? && self.client.integrations_allowed.include?('xencall') &&
                  tag_id.present? &&
                  (client_api_integration = self.client.client_api_integrations.find_by(target: 'xencall')) &&
                  (client_api_integration.channels.present? && client_api_integration.channels.invert.include?(tag_id))

    st_customer_id = self.ext_references.find_by(target: 'servicetitan')&.ext_id.to_s
    # Tag is assigned to a Xencall channel
    channel_id = client_api_integration.channels.invert[tag_id].to_s

    return if channel_id.blank?

    contact_phones = self.contact_phones.pluck(:phone, :primary).sort_by { |phone| phone[1] ? 0 : 1 }

    result = Xencall.send_lead(
      api_key:             client_api_integration.api_key,
      channel:             channel_id,
      phone:               contact_phones.present? ? contact_phones[0] : '',
      firstname:           self.firstname,
      lastname:            self.lastname,
      address:             self.address1,
      city:                self.city,
      state:               self.state,
      zip:                 self.zipcode,
      phone_alt:           contact_phones.length > 1 ? contact_phones[1] : '',
      email:               self.email,
      st_customer_id:,
      contact_id:          self.id,
      custom_field_name:   client_api_integration.gen_field_id,
      custom_field_string: client_api_integration.gen_field_string,
      test_send:           client_api_integration.live_mode.to_i.zero?
    )
    # logger.debug "Xencall result: #{result.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"

    return unless result[:success] && result[:xencall_lead_id].present? && (contact_api_integration = self.contact_api_integrations.find_or_initialize_by(target: 'xencall'))

    contact_api_integration.update(xencall_lead_id: result[:xencall_lead_id])
  end

  # create a Slack channel using the Contact's current User assignment
  # MUST be created through the Contact because the User may have been reassigned prior
  def slack_channel_create(args = {})
    error_message           = ''
    slack_channel           = args.dig(:slack_channel).to_s
    contact_estimate_id     = args.dig(:contact_estimate_id)
    contact_invoice_id      = args.dig(:contact_invoice_id)
    contact_job_id          = args.dig(:contact_job_id)
    contact_subscription_id = args.dig(:contact_subscription_id)
    contact_visit_id        = args.dig(:contact_visit_id)

    return unless self.client.active?

    if slack_channel.blank?
      error_message = 'Slack channel must be defined.'
    elsif (user_api_integration = self.user.user_api_integrations.find_by(target: 'slack', name: '')).nil? || user_api_integration.token.blank?
      error_message = 'User must have a Slack connection.'
    end

    if error_message.blank?
      if contact_estimate_id.to_i.positive? && (contact_estimate = self.estimates.find_by(id: contact_estimate_id))
        slack_channel = contact_estimate.message_tag_replace(slack_channel)
      end

      if contact_invoice_id.to_i.positive? && (contact_invoice = self.invoices.find_by(id: contact_invoice_id))
        slack_channel = contact_invoice.message_tag_replace(slack_channel)
      end

      if contact_job_id.to_i.positive? && (contact_job = self.jobs.find_by(id: contact_job_id))
        slack_channel = contact_job.message_tag_replace(slack_channel)
      end

      if contact_subscription_id.to_i.positive? && (contact_subscription = self.subscriptions.find_by(id: contact_subscription_id))
        slack_channel = contact_subscription.message_tag_replace(slack_channel)
      end

      if contact_visit_id.to_i.positive? && (contact_visit = self.visits.find_by(id: contact_visit_id))
        slack_channel = contact_visit.message_tag_replace(slack_channel)
      end

      slack_client = Integrations::Slacker::Base.new(user_api_integration.token)
      slack_client.channel_create(self.message_tag_replace(slack_channel))
    else
      Users::SendPushOrTextJob.perform_later(
        content:    "Slack channel (#{self.message_tag_replace(slack_channel)}) could NOT be created for #{self.user.fullname}. #{error_message} Contact: #{self.fullname}.",
        contact_id: self.id,
        from_phone: self.user.default_from_twnumber&.phonenumber.to_s,
        user_id:    self.user_id
      )
    end
  end

  def slack_channel_invite(args = {})
    error_message           = ''
    slack_channel           = args.dig(:slack_channel).to_s
    users                   = args.dig(:users)
    org_user_emails         = args.dig(:org_user_emails).to_a
    contact_estimate_id     = args.dig(:contact_estimate_id)
    contact_invoice_id      = args.dig(:contact_invoice_id)
    contact_job_id          = args.dig(:contact_job_id)
    contact_subscription_id = args.dig(:contact_subscription_id)
    contact_visit_id        = args.dig(:contact_visit_id)

    return unless self.client.active?

    if slack_channel.blank?
      error_message = 'Slack channel must be defined.'
    elsif (user_api_integration = self.user.user_api_integrations.find_by(target: 'slack', name: '')).nil? || user_api_integration.token.blank?
      error_message = 'User must have a Slack connection.'
    elsif users.blank? && org_user_emails.blank?
      error_message = 'Users must be defined.'
    elsif org_user_emails.blank? && (org_user_emails = users.map { |u| self.org_users(users_orgs: u, purpose: 'email', default_to_all_users_in_org_position: false).flatten }.map(&:first).compact_blank).blank?
      error_message = 'User emails must be defined.'
    end

    if error_message.blank?
      if contact_estimate_id.to_i.positive? && (contact_estimate = self.estimates.find_by(id: contact_estimate_id))
        slack_channel = contact_estimate.message_tag_replace(slack_channel)
      end

      if contact_invoice_id.to_i.positive? && (contact_invoice = self.invoices.find_by(id: contact_invoice_id))
        slack_channel = contact_invoice.message_tag_replace(slack_channel)
      end

      if contact_job_id.to_i.positive? && (contact_job = self.jobs.find_by(id: contact_job_id))
        slack_channel = contact_job.message_tag_replace(slack_channel)
      end

      if contact_subscription_id.to_i.positive? && (contact_subscription = self.subscriptions.find_by(id: contact_subscription_id))
        slack_channel = contact_subscription.message_tag_replace(slack_channel)
      end

      if contact_visit_id.to_i.positive? && (contact_visit = self.visits.find_by(id: contact_visit_id))
        slack_channel = contact_visit.message_tag_replace(slack_channel)
      end

      normalized_slack_channel = self.message_tag_replace(slack_channel)
      slack_client             = Integrations::Slacker::Base.new(user_api_integration.token)

      org_user_emails.each do |email|
        slack_client.channel_invite(normalized_slack_channel, email)
      end
    else
      Users::SendPushOrTextJob.perform_later(
        content:    "Slack channel (#{self.message_tag_replace(slack_channel)}) could NOT be accessed for #{self.user.fullname} to send an invitation. #{error_message} Contact: #{self.fullname}.",
        contact_id: self.id,
        from_phone: self.user.default_from_twnumber&.phonenumber.to_s,
        user_id:    self.user_id
      )
    end
  end

  # set sleep off for this Contact
  # contact.sleep_off
  def sleep_off
    contact = Contact.find(self.id)
    contact.update(sleep: false)
    self.sleep = false
  end

  # set sleep on for this Contact
  # contact.sleep_on
  def sleep_on
    contact = Contact.find(self.id)
    contact.update(sleep: true)
    self.sleep = true
  end

  # DEPRECATED (delete after 2029-03-30)
  # start Contact on a new Campaign
  # always start a Campaign using DelayedJobs
  # target_time is required when starting a reverse Campaign on a future target date
  # ex: contact.delay(
  #   priority:            DelayedJob.job_priority('start_campaign'),
  #   process:             'start_campaign',
  #   contact_id:          contact.id,
  #   user_id:             user.id,
  #   data:                { campaign_id: Integer }
  # ).start_campaign(campaign_id: Integer)
  # ex: contact.delay(
  #   priority:            DelayedJob.job_priority('start_campaign'),
  #   process:             'start_campaign',
  #   contact_id:          contact.id,
  #   user_id:             user.id,
  #   data:                { campaign_id: Integer, target_time: Time, message: Messages::Message }
  # ).start_campaign(campaign_id: Integer, target_time: Time, message: Messages::Message)
  def start_campaign(args = {})
    campaign_id             = args.dig(:campaign_id).to_i
    target_time             = args.dig(:target_time).respond_to?(:strftime) ? args[:target_time] : nil
    message                 = args.dig(:message).is_a?(Messages::Message) ? args[:message] : nil
    contact_estimate_id     = args.dig(:contact_estimate_id).to_i
    contact_invoice_id      = args.dig(:contact_invoice_id).to_i
    contact_job_id          = args.dig(:contact_job_id).to_i
    contact_subscription_id = args.dig(:contact_subscription_id).to_i
    contact_visit_id        = args.dig(:contact_visit_id).to_i
    error_message           = ''

    if campaign_id.positive? && (campaign = self.client.campaigns.find_by(id: campaign_id))

      if campaign.active

        if campaign.repeatable?(self)
          return if campaign.client.integrations_allowed.include?('google') && campaign.client.client_api_integrations.find_by(target: 'google', name: '')&.review_campaign_ids_excluded&.include?(campaign.id) && Review.find_by(contact_id: self.id)

          if (trigger = campaign.triggers.order(:step_numb).first) && (Trigger::FORWARD_TYPES + Trigger::REVERSE_TYPES + [155]).include?(trigger.trigger_type)
            contact_campaign_data = {}
            contact_campaign_data[:contact_estimate_id]     = contact_estimate_id if contact_estimate_id.positive?
            contact_campaign_data[:contact_invoice_id]      = contact_invoice_id if contact_invoice_id.positive?
            contact_campaign_data[:contact_job_id]          = contact_job_id if contact_job_id.positive?
            contact_campaign_data[:contact_subscription_id] = contact_subscription_id if contact_subscription_id.positive?
            contact_campaign_data[:contact_visit_id]        = contact_visit_id if contact_visit_id.positive?
            contact_campaign_data[:st_membership_id]        = args[:st_membership_id] if args.dig(:st_membership_id).to_i.positive?
            contact_campaign = self.contact_campaigns.create(campaign_id:, data: contact_campaign_data)

            trigger.fire(contact: self, contact_campaign:, message:, target_time:)

            if trigger.repeatable? && trigger.data.dig(:repeat).to_i == 1 && trigger.data.dig(:repeat_interval).to_i.positive? && trigger.data.dig(:repeat_period).to_s.present?
              # Trigger is repeatable
              Contacts::Campaigns::StartJob.set(wait_until: Time.current + trigger.data[:repeat_interval].to_i.send(trigger.data[:repeat_period].to_s)).perform_later(
                campaign_id:,
                client_id:               self.client_id,
                contact_campaign_id:     contact_campaign.id,
                contact_estimate_id:,
                contact_id:              self.id,
                contact_invoice_id:,
                contact_job_id:,
                contact_subscription_id:,
                contact_visit_id:,
                message:,
                user_id:                 self.user_id
              )
            end
          else
            error_message = "Campaign (#{campaign.name}) could NOT be started for Contact (#{self.fullname}). The Campaign is NOT allowed to start in this manner."
          end
        end
      else
        error_message = "Campaign (#{campaign.name}) could NOT be started for Contact (#{self.fullname}). The Campaign is NOT active."
      end
    else
      error_message = "Campaign (Unknown) could NOT be started for Contact (#{self.fullname}). A Campaign was NOT selected or could NOT be found."
    end

    return if error_message.blank?

    Users::SendPushOrTextJob.perform_later(
      content:    error_message,
      contact_id: self.id,
      from_phone: self.user.default_from_twnumber&.phonenumber.to_s,
      ok2push:    self.user.notifications.dig('campaigns', 'by_push'),
      ok2text:    self.user.notifications.dig('campaigns', 'by_text'),
      to_phone:   self.user.phone,
      user_id:    self.user_id
    )
  end

  # scan through Campaigns and start any that meet criteria
  def start_campaigns_on_incoming_call(args = {})
    client_phone_number = args.dig(:client_phone_number).to_s
    contact_is_new      = args.dig(:contact_is_new).to_bool

    return unless client_phone_number.present? &&
                  (client_number = Twnumber.find_by(phonenumber: client_phone_number)) &&
                  (new_contact_by_phone_triggers = Trigger.where(trigger_type: 150, campaign_id: client_number.client.campaigns))

    dayofweek = Time.current.in_time_zone(client_number.client.time_zone).strftime('%a').downcase
    minuteofday = (Time.current.in_time_zone(client_number.client.time_zone).hour * 60) + Time.current.in_time_zone(client_number.client.time_zone).min
    active_campaigns = self.active_campaigns

    new_contact_by_phone_triggers.each do |trigger|
      if trigger.data&.include?(:phone_number) && (trigger.data[:phone_number].to_s.empty? || trigger.data[:phone_number].to_s == client_phone_number) &&
         trigger.data.include?(:new_contacts_only) && ((trigger.data[:new_contacts_only].to_i.positive? && contact_is_new) || trigger.data[:new_contacts_only].to_i.zero?) &&
         trigger.data.include?(:process_times_a) && trigger.data.include?(:process_times_b) &&
         (minuteofday.between?(trigger.data[:process_times_a].split(';')[0].to_i, trigger.data[:process_times_a].split(';')[1].to_i) ||
         minuteofday.between?(trigger.data[:process_times_b].split(';')[0].to_i, trigger.data[:process_times_b].split(';')[1].to_i)) &&
         trigger.data.include?(:"process_#{dayofweek}") && trigger.data[:"process_#{dayofweek}"].to_i == 1 && active_campaigns.exclude?(trigger.campaign_id.to_i)
        # criteria is met to start Campaign

        Contacts::Campaigns::StartJob.perform_later(
          campaign_id: trigger.campaign_id,
          client_id:   self.client_id,
          contact_id:  self.id,
          user_id:     self.user_id
        )
      end
    end
  end

  def stop_aiagents
    aiagent_sessions.active.find_each do |session|
      session.stop!(:stopped)
    end
  end

  # stop and start Campaigns on this Contact
  # contact.stop_and_start_contact_campaigns()
  #   (req) stop_campaign_ids:          (Array<Integer>)
  #   (req) start_campaign_id:          (Integer)
  #   (opt) contact_estimate_id:        (Integer)
  #   (opt) contact_invoice_id:         (Integer)
  #   (opt) contact_job_id:             (Integer)
  #   (opt) contact_location_id:        (Integer)
  #   (opt) contact_membership_type_id: (Integer)
  #   (opt) contact_subscription_id:    (Integer)
  #   (opt) contact_visit_id:           (Integer)
  def stop_and_start_contact_campaigns(args = {})
    # stop all campaigns first
    args.dig(:stop_campaign_ids).each do |id|
      Contacts::Campaigns::StopJob.perform_now(
        campaign_id: id.to_i.zero? ? 'all' : id.to_i,
        contact_id:  self.id
      )
    end

    # start the campaign
    Contacts::Campaigns::StartJob.perform_later(
      campaign_id:                args.dig(:start_campaign_id).to_i,
      client_id:                  self.client_id,
      contact_estimate_id:        args.dig(:contact_estimate_id).to_i,
      contact_id:                 self.id,
      contact_invoice_id:         args.dig(:contact_invoice_id).to_i,
      contact_job_id:             args.dig(:contact_job_id).to_i,
      contact_location_id:        args.dig(:contact_location_id).to_i,
      contact_membership_type_id: args.dig(:contact_membership_type_id).to_i,
      contact_subscription_id:    args.dig(:contact_subscription_id).to_i,
      contact_visit_id:           args.dig(:contact_visit_id).to_i,
      st_membership_id:           args.dig(:st_membership_id).to_i,
      user_id:                    self.user_id
    )
  end

  # DEPRECATED (delete after 2027-04-05)
  # replaced by Contacts::Campaigns::StopJob
  # stop a Campaign running on this Contact
  # contact.stop_contact_campaigns()
  #   (opt) contact_campaign_id:            (Integer)
  #   (opt) campaign_id:                    (Integer)
  #   (opt) limit_to_estimate_job_visit_id: (Boolean)
  #   (opt) keep_triggeraction_ids          (Array)
  #   (opt) multi_stop:                     (String)
  #   (opt) triggeraction_id:               (Integer)
  def stop_contact_campaigns(args = {})
    JsonLog.info 'Contact.stop_contact_campaigns', { args: }
    contact_campaign = (args.dig(:contact_campaign_id).to_i.positive? && self.contact_campaigns.find_by(id: args.dig(:contact_campaign_id).to_i)) || nil

    case args.dig(:campaign_id).to_s[0, 6]
    when 'all'
      contact_campaigns = Contacts::Campaign.where(contact_id: self.id)
      delayed_jobs      = {}
    when 'this'
      contact_campaigns = Contacts::Campaign.where(id: [contact_campaign&.id])
      delayed_jobs      = {}
    when 'all_ot'
      stop_ids = self.contact_campaign_ids_to_stop(self.active_contact_campaign_ids, contact_campaign, args.dig(:limit_to_estimate_job_visit_id))
      stop_ids.delete(contact_campaign&.id)
      contact_campaigns, delayed_jobs = self.stop_contact_campaigns_all_other(stop_ids, (args.dig(:multi_stop) || 'all'), contact_campaign)
    when 'group_'
      contact_campaign_ids            = self.active_contact_campaign_ids & self.contact_campaigns.where(campaign_id: self.client.campaigns.where(campaign_group_id: args.dig(:campaign_id).to_s.split('_').last.to_i)).pluck(:id)
      stop_ids                        = self.contact_campaign_ids_to_stop(contact_campaign_ids, contact_campaign, args.dig(:limit_to_estimate_job_visit_id))
      contact_campaigns, delayed_jobs = self.stop_contact_campaigns_group(stop_ids, args.dig(:multi_stop), contact_campaign)
    else
      contact_campaign_ids            = self.active_contact_campaign_ids & self.contact_campaigns.where(campaign_id: args.dig(:campaign_id).to_i).pluck(:id)
      stop_ids                        = self.contact_campaign_ids_to_stop(contact_campaign_ids, contact_campaign, args.dig(:limit_to_estimate_job_visit_id))
      contact_campaigns, delayed_jobs = self.stop_contact_campaigns_everything_else(stop_ids, args.dig(:multi_stop), args.dig(:campaign_id), contact_campaign)
    end

    JsonLog.info 'Contact.stop_contact_campaigns', { contact_campaigns:, delayed_jobs: }

    contact_campaigns.each { |cc| cc.stop(keep_triggeraction_ids: [args.dig(:keep_triggeraction_ids) || []].flatten) }
    self.stop_scheduled_campaigns(campaign_id: args.dig(:campaign_id))

    delayed_jobs.each do |delayed_job|
      delayed_job.destroy if delayed_job.locked_at.nil?
    end
  end

  # DEPRECATED (delete after 2027-04-05)
  # replaced by Contacts::Campaigns::StopJob
  # return Contacts::Campaigns & DelayedJobs to destroy
  # contact.stop_contact_campaigns_all_other()
  #   (req) active_contact_campaign_ids: (Array)
  #   (req) multi_stop:                  (String)
  #   (req) contact_campaign:            (Contacts::Campaign)
  def stop_contact_campaigns_all_other(active_contact_campaign_ids, multi_stop, contact_campaign)
    case (multi_stop.presence || 'all').to_s.downcase
    when 'first'
      contact_campaigns = Contacts::Campaign.where(id: active_contact_campaign_ids).order(created_at: :asc).limit(1)
      delayed_jobs      = contact_campaigns.present? ? {} : self.delayed_jobs.where(process: 'start_campaign').where.not(contact_campaign_id: contact_campaign&.id).order(created_at: :asc).limit(1)
    when 'last'
      delayed_jobs      = self.delayed_jobs.where(process: 'start_campaign').where.not(contact_campaign_id: contact_campaign&.id).order(created_at: :desc).limit(1)
      contact_campaigns = if delayed_jobs.present?
                            {}
                          elsif Contacts::Campaign.where(id: active_contact_campaign_ids).length > 1
                            Contacts::Campaign.where(id: active_contact_campaign_ids).order(created_at: :desc).limit(1)
                          else
                            active_contact_campaign_ids.delete(contact_campaign&.id)
                            Contacts::Campaign.where(id: active_contact_campaign_ids).order(created_at: :desc).limit(1)
                          end
    else
      contact_campaigns = Contacts::Campaign.where(id: active_contact_campaign_ids)
      delayed_jobs      = self.delayed_jobs.where(process: 'start_campaign').where.not(contact_campaign_id: contact_campaign&.id)
    end

    [contact_campaigns, delayed_jobs]
  end

  # DEPRECATED (delete after 2027-04-05)
  # replaced by Contacts::Campaigns::StopJob
  # return Contacts::Campaigns & DelayedJobs to destroy
  # contact.stop_contact_campaigns_everything_else()
  #   (req) active_contact_campaign_ids: (Array)
  #   (req) multi_stop:                  (String)
  #   (req) campaign_id:                 (Integer)
  #   (req) contact_campaign:            (Contacts::Campaign)
  def stop_contact_campaigns_everything_else(active_contact_campaign_ids, multi_stop, campaign_id, contact_campaign)
    case (multi_stop || 'all').to_s.downcase
    when 'first'
      active_contact_campaign_ids.delete(contact_campaign&.id)
      contact_campaigns = Contacts::Campaign.where(id: active_contact_campaign_ids).order(created_at: :asc).limit(1)
      delayed_jobs      = contact_campaigns.present? ? {} : self.delayed_jobs.where(process: 'start_campaign').where('data @> ?', { campaign_id: }.to_json).order(created_at: :asc).limit(1)
    when 'last'
      delayed_jobs      = self.delayed_jobs.where(process: 'start_campaign').where('data @> ?', { campaign_id: }.to_json).order(created_at: :desc).limit(1)
      contact_campaigns = if delayed_jobs.present?
                            {}
                          elsif Contacts::Campaign.where(id: active_contact_campaign_ids).length > 1
                            Contacts::Campaign.where(id: active_contact_campaign_ids).order(created_at: :desc).limit(1)
                          else
                            active_contact_campaign_ids.delete(contact_campaign&.id)
                            Contacts::Campaign.where(id: active_contact_campaign_ids).order(created_at: :desc).limit(1)
                          end
    else
      # active_contact_campaign_ids.delete(contact_campaign&.id)
      contact_campaigns = Contacts::Campaign.where(id: active_contact_campaign_ids)
      delayed_jobs      = self.delayed_jobs.where(process: 'start_campaign').where('data @> ?', { campaign_id: }.to_json)
    end

    [contact_campaigns, delayed_jobs]
  end

  # DEPRECATED (delete after 2027-04-05)
  # replaced by Contacts::Campaigns::StopJob
  # return Contacts::Campaigns & DelayedJobs to destroy
  # contact.stop_contact_campaigns_group()
  #   (req) active_contact_campaign_ids: (Array)
  #   (req) multi_stop:                  (String)
  #   (req) contact_campaign:            (Contacts::Campaign)multi_stop
  def stop_contact_campaigns_group(active_contact_campaign_ids, multi_stop, contact_campaign)
    case (multi_stop || 'all').to_s.downcase
    when 'first'
      active_contact_campaign_ids.delete(contact_campaign&.id)
      contact_campaigns = Contacts::Campaign.where(id: active_contact_campaign_ids).order(created_at: :asc).limit(1)
      delayed_jobs      = contact_campaigns.present? ? {} : self.delayed_jobs.where(process: 'start_campaign').where.not(contact_campaign_id: contact_campaign&.id).order(created_at: :asc).limit(1)
    when 'last'
      delayed_jobs      = self.delayed_jobs.where(process: 'start_campaign').where.not(contact_campaign_id: contact_campaign&.id).order(created_at: :desc).limit(1)
      contact_campaigns = if delayed_jobs.present?
                            {}
                          elsif Contacts::Campaign.where(id: active_contact_campaign_ids).length > 1
                            Contacts::Campaign.where(id: active_contact_campaign_ids).order(created_at: :desc).limit(1)
                          else
                            active_contact_campaign_ids.delete(contact_campaign&.id)
                            Contacts::Campaign.where(id: active_contact_campaign_ids).order(created_at: :desc).limit(1)
                          end
    else
      active_contact_campaign_ids.delete(contact_campaign&.id)
      contact_campaigns = Contacts::Campaign.where(id: active_contact_campaign_ids)
      delayed_jobs      = self.delayed_jobs.where(process: 'start_campaign').where.not(contact_campaign_id: contact_campaign&.id)
    end

    [contact_campaigns, delayed_jobs]
  end

  # DEPRECATED (delete after 2027-04-05)
  # replaced by Contacts::Campaigns::StopJob
  # stop scheduled Campaigns on this Contact
  # contact.stop_scheduled_campaigns()
  #   (req) campaign_id: (Integer)
  def stop_scheduled_campaigns(**args)
    # return if args.dig(:campaign_id).to_i.negative?

    # Delayed::Job.where(process: 'group_start_campaign', locked_at: nil).where("run_at > '#{10.seconds.from_now}'").where('data @> ?', { apply_campaign_id: args[:campaign_id].to_i }.to_json).where("data->'contacts' @> '#{self.id}'").find_each do |dj|
    #   dj.with_lock do
    #     job_data = dj.payload_object.job_data
    #     contacts = job_data.dig('arguments')&.first&.dig('data', 'contacts')

    #     if contacts.is_a?(Array) && contacts.include?(self.id)
    #       job_data['arguments'].first['data']['contacts'] = contacts - [self.id]
    #       dj.payload_object.job_data = job_data
    #       dj.handler = dj.payload_object.to_yaml
    #       dj.data['contacts'] = contacts - [self.id]
    #       dj.save
    #     end
    #   end
    # end
  end

  # add a record to Contacts::Campaign::Triggeraction to track completion of a Triggeraction
  # contact.triggeraction_complete()
  #   (req) contact_campaign:    (Contacts::Campaign)
  #     ~ or ~
  #   (req) contact_campaign_id: (Integer)
  #
  #   (req) triggeraction:       (Triggeraction)
  #     ~ or ~
  #   (req) triggeraction_id:    (Integer)
  def triggeraction_complete(args = {})
    return unless (triggeraction = if args.dig(:triggeraction).is_a?(Triggeraction)
                                     args[:triggeraction]
                                   elsif args.dig(:triggeraction_id).to_i.positive?
                                     Triggeraction.find_by(id: args[:triggeraction_id].to_i)
                                   end)

    return unless (contact_campaign = if args.dig(:contact_campaign).is_a?(Contacts::Campaign)
                                        args[:contact_campaign]
                                      elsif args.dig(:contact_campaign_id).to_i.positive?
                                        triggeraction.campaign.contact_campaigns.where(id: args.dig(:contact_campaign_id).to_i).first
                                      end)

    contact_campaign.contact_campaign_triggeractions.create(triggeraction_id: triggeraction.id, outcome: contact_campaign.delayed_jobs.find_by(triggeraction_id: triggeraction.id) ? 'scheduled' : 'completed')

    UserCable.new.broadcast self.client, self.user, { campaign_activity: 'complete', id: contact_campaign.id, trigger_name: triggeraction.trigger.data[:name], triggeraction_name: triggeraction.type_name, created_at: Friendly.new.date(contact_campaign.created_at, self.client.time_zone, true) }
  end

  # confirm/update phones for Contact
  # contact.update_contact_phones()
  #   (req) phones          (Array) ex: [[number, label, primary], ...]
  #                                       number  (String)  ex: '1234567890'
  #                                       label   (String)  ex: 'mobile'
  #                                       primary (Boolean) ex: true
  #   (opt) delete_unfound: (Boolean) delete all phone numbers not found in phones
  #   (opt) update_primary  (Boolean) update the primary phone number from phones
  # rubocop:disable Style/OptionalBooleanParameter
  def update_contact_phones(phones, delete_unfound = false, update_primary = false)
    JsonLog.info 'Contact.update_contact_phones', { phones:, delete_unfound:, update_primary:, contact: self }, contact_id: self.id
    return false if phones.blank?

    contact_phone_ids    = self.contact_phones.pluck(:id)
    primary_phone_number = self.contact_phones.find_by(primary: true)&.phone

    if update_primary || primary_phone_number.blank?
      primary_phone_number = phones.find { |_phone, _label, primary| primary }&.first.to_s.clean_phone(self.client.primary_area_code)
      primary_phone_number = phones.find { |_phone, label, _primary| label.include?('mobile') }&.first.to_s.clean_phone(self.client.primary_area_code) if primary_phone_number.blank?
      primary_phone_number = phones.find { |_phone, label, _primary| label.include?('cell') }&.first.to_s.clean_phone(self.client.primary_area_code) if primary_phone_number.blank?
      primary_phone_number = self.contact_phones.find_by(primary: true)&.phone if primary_phone_number.blank?
    end

    phones.each do |phone, label, _primary|
      next if phone.blank?

      phone = phone.clean_phone(self.client.primary_area_code)

      next if phone.blank? || label.blank?

      contact_phone         = self.contact_phones.find_or_initialize_by(phone:)
      contact_phone.label   = label

      if primary_phone_number.present?
        contact_phone.primary = contact_phone.phone == primary_phone_number
      else
        contact_phone.primary = true
        primary_phone_number = phone
      end

      contact_phone.save unless self.new_record?
      contact_phone_ids.delete(contact_phone.id)
    end

    self.contact_phones.where(id: contact_phone_ids).destroy_all if delete_unfound && contact_phone_ids.present?

    true
  end
  # rubocop:enable Style/OptionalBooleanParameter

  # save ContactCustomFields data
  # contact.update_custom_fields(custom_fields: Hash)
  #   (req) custom_fields:       (Hash) ex: { ClientCustomField.id => value, ... }
  def update_custom_fields(args = {})
    custom_fields     = args.dig(:custom_fields).is_a?(Hash) ? args[:custom_fields] : {}
    numeric_var_types = %w[numeric currency stars]
    string_chars      = ['', '.']

    custom_fields.each do |key, value|
      if (client_custom_field = ClientCustomField.find_by(client_id: self.client_id, id: key)) && (contact_custom_field = self.contact_custom_fields.find_or_initialize_by(client_custom_field_id: key))

        value = if numeric_var_types.include?(client_custom_field.var_type)
                  string_chars.include?(value.to_s.gsub(%r{[^\d.]}, '')) ? '' : value.to_s.gsub(%r{[^\d.]}, '').to_d.to_s
                elsif client_custom_field.var_type == 'date' && value.is_a?(String)
                  Time.use_zone(self.client.time_zone) { Chronic.parse(value.to_s) }
                else
                  value.to_s
                end

        contact_custom_field.update(var_value: value)
      end
    end
  end

  # confirm/update Contacts::ExtReference for Contact
  # (req) ext_refs:      (Hash) { target (String) => id (String), ...}
  # (opt) delete_unfound (Boolean)
  # rubocop:disable Style/OptionalBooleanParameter
  def update_ext_references(ext_refs, delete_unfound = false)
    JsonLog.info 'Contact.update_ext_references', { ext_refs:, delete_unfound:, contact: self }, contact_id: self.id
    return if ext_refs.blank?

    ext_reference_ids = self.ext_references.pluck(:id)

    ext_refs&.each do |target, ext_id|
      if target.present? && ext_id.present? && ext_id.to_s != '0'
        ext_reference = self.ext_references.find_or_initialize_by(target:, ext_id:)

        ext_reference_ids.delete(ext_reference.id)
      end
    end

    self.ext_references.where(id: ext_reference_ids).destroy_all if delete_unfound && ext_reference_ids.present?
  end
  # rubocop:enable Style/OptionalBooleanParameter

  private

  def after_create_commit_actions
    super

    self.send_to_five9(action: 'create')
    self.send_to_outreach
    self.send_to_zapier(action: 'receive_new_contact')

    return unless (client_api_integration = self.client.client_api_integrations.find_by(target: 'webhook', name: '')) && client_api_integration.webhooks.deep_symbolize_keys.find { |_k, v| v.dig(:type) == 'contact_created' }.present?

    self.send_to_url(client_api_integration.webhooks.deep_symbolize_keys.select { |_k, v| v.dig(:type) == 'contact_created' })
  end

  def after_destroy_commit_actions
    super

    return unless (client_api_integration = self.client.client_api_integrations.find_by(target: 'webhook', name: '')) && client_api_integration.webhooks.deep_symbolize_keys.find { |_k, v| v.dig(:type) == 'contact_deleted' }.present?

    self.send_to_url(client_api_integration.webhooks.deep_symbolize_keys.select { |_k, v| v.dig(:type) == 'contact_deleted' })
  end

  def after_update_commit_actions
    super

    previous_changes = self.previous_changes
    previous_changes.delete('updated_at')
    previous_changes.delete('data') if previous_changes.dig('asdf')&.uniq&.length == 1

    return if previous_changes.blank?

    self.send_to_five9(action: 'update')
    self.send_to_outreach

    if (client_api_integration = self.client.client_api_integrations.find_by(target: 'webhook', name: '')) && client_api_integration.webhooks.deep_symbolize_keys.find { |_k, v| v.dig(:type) == 'contact_updated' }.present?
      self.send_to_url(client_api_integration.webhooks.deep_symbolize_keys.select { |_k, v| v.dig(:type) == 'contact_updated' })
    end

    self.send_to_zapier(action: 'receive_updated_contact')

    return unless self.saved_change_to_lastname? || self.saved_change_to_firstname? || self.saved_change_to_email?

    self.send_to_salesrabbit
  end

  def apply_defaults
    self.user_id                   = self.client.def_user_id if self.client_id.to_i.positive? && self.user_id.to_i.zero?
    self.client_id                 = self.user.client_id if self.user_id.to_i.positive?
    self.trusted_form            ||= {}
    self.trusted_form              = self.trusted_form.symbolize_keys
    self.trusted_form[:token]    ||= ''
    self.trusted_form[:cert_url] ||= ''
    self.trusted_form[:ping_url] ||= ''
    self.folders                 ||= []
  end

  def before_save_actions
    self.group_id_updated_at       = Time.current if self.group_id_changed?
    self.lead_source_id_updated_at = Time.current if self.lead_source_id_changed?
    self.stage_id_updated_at       = Time.current if self.stage_id_changed?
    self.trusted_form              = {} if (self.trusted_form&.dig(:token).to_s + self.trusted_form&.dig(:cert_url).to_s + self.trusted_form&.dig(:ping_url).to_s).blank?
  end

  def before_validation_actions
    self.state = self.state[0, 2].upcase
    self.email = EmailAddress.valid?(self.email) ? EmailAddress.normal(self.email) : nil
    self.sleep = true if self.block
    self.firstname = self.firstname.titleize if self.firstname == self.firstname.downcase || self.firstname == self.firstname.upcase
    self.lastname = self.lastname.titleize if self.lastname == self.lastname.downcase || self.lastname == self.lastname.upcase
  end

  def count_is_approved
    return if self.client.max_contacts_count.to_i == -1 || self.client.contacts.count < self.client.max_contacts_count.to_i

    errors.add(:base, "Maximum Contacts for #{self.client.name} has been met.")

    Users::SendPushOrTextJob.perform_later(
      title:            "Maximum Contacts (#{self.client.max_contacts_count.to_i}) met.",
      content:          "Unable to add #{self.fullname}.",
      contact_id:       self.id,
      from_phone:       self.latest_client_phonenumber(default_ok: true, phone_numbers_only: true)&.phonenumber.to_s,
      to_phone:         self.user.phone,
      triggeraction_id: 0,
      user_id:          self.user_id
    )
  end
end
