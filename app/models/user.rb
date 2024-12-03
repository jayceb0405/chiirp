# frozen_string_literal: true

# app/models/user.rb
class User < ApplicationRecord
  # require 'facebookbusiness'
  include Integrationable
  include MessageCentral
  include Textable

  encrypts :otp_secret, :otp_secret_at

  has_one_attached :avatar

  mount_uploader :user_avatar, UserAvatarUploader
  attr_accessor :skip_password_validation # virtual attribute to skip password validation while saving
  attr_reader :raw_invitation_token # used when sending User text message to accept invitation to create password

  # Include default devise modules.
  devise :database_authenticatable, :registerable, :recoverable,
         :trackable, :validatable, :invitable, :lockable, :timeoutable,
         :omniauthable, omniauth_providers: %i[facebook google_oauth2_chiirp outreach_chiirp slack_chiirp]

  belongs_to :client

  # rubocop:disable Rails/InverseOf
  has_many   :access_grants,          dependent: :delete_all, class_name: 'Doorkeeper::AccessGrant', foreign_key: :resource_owner_id
  has_many   :access_tokens,          dependent: :delete_all, class_name: 'Doorkeeper::AccessToken', foreign_key: :resource_owner_id
  # rubocop:enable Rails/InverseOf
  has_many   :contact_notes,          dependent: :destroy,    class_name: '::Contacts::Note'
  has_many   :contacts,               dependent: nil
  has_many   :delayed_jobs,           dependent: :delete_all
  has_many   :org_users,              dependent: :delete_all
  has_many   :user_pushes,            dependent: :destroy
  has_many   :tasks,                  dependent: :destroy
  has_many   :messages,               dependent: :nullify, class_name: '::Messages::Message'
  has_many   :messages_read,          dependent: :nullify, class_name: '::Messages::Message', foreign_key: :read_at_user_id, inverse_of: :read_at_user
  has_many   :notes,                  dependent: :nullify, class_name: '::Clients::Note'
  has_many   :twnumberusers,          dependent: :delete_all
  has_many   :twnumbers,              through:   :twnumberusers
  has_many   :user_attachments,       dependent: :destroy
  has_many   :user_api_integrations,  dependent: :destroy
  has_many   :user_contact_forms,     dependent: :destroy
  has_many   :user_settings,          dependent: :destroy, class_name: '::Users::Setting'

  has_many   :from_user_chats,        dependent: nil,      foreign_key: 'from_user_id', class_name: 'UserChat', inverse_of: :from_user
  has_many   :to_user_chats,          dependent: nil,      foreign_key: 'to_user_id', class_name: 'UserChat', inverse_of: :to_user

  has_many :sign_in_debugs,           dependent: :nullify, class_name: 'Users::SignInDebug'

  attr_accessor :otp_method, :otp_attempt

  store_accessor :data, :agency_user_tokens, :agent, :default_stage_parent_id, :incoming_call_popup, :integrations_order,
                 :my_agent_token, :notifications, :phone_in, :phone_in_with_action, :phone_out, :ring_duration,
                 :submit_text_on_enter, :super_admin, :team_member, :trainings_editable, :version_notification
  store_accessor :permissions, :aiagents_controller, :campaigns_controller, :central_controller, :clients_controller, :companies_controller, :dashboard_controller, :email_templates_controller, :import_contacts_controller, :integrations_controller, :integrations_servicetitan_controller,
                 :my_contacts_controller, :stages_controller, :surveys_controller, :trackable_links_controller, :trainings_controller,
                 :user_controller, :user_contact_forms_controller, :users_controller, :widgets_controller

  validates :firstname, presence: true, length: { minimum: 2 }
  validates :lastname, presence: true, length: { minimum: 2 }
  validate  :count_is_approved, on: [:create]
  validates_with EmailAddress::ActiveRecordValidator, field: :email

  after_initialize :apply_defaults, if: :new_record?
  after_validation     :after_validation_actions
  before_create        :before_create_actions
  before_destroy       :before_destroy_actions

  scope :client_admins, ->(client_id) {
    where(client_id:)
      .where('permissions @> ?', { users_controller: ['permissions'] }.to_json)
      .or(User.where(client_id:).where('data @> ?', { super_admin: true }.to_json))
      .or(User.where(client_id:).where('data @> ?', { team_member: true }.to_json))
      .or(User.where(client_id:).where('data @> ?', { agent: true }.to_json))
  }
  scope :with_tasks, -> {
    joins(:tasks)
      .group('users.id')
  }

  # can this User access the contact?
  # user.access_contact?(contact)
  #   (req) contact: (Contact)
  def access_contact?(contact)
    contact.user_id == self.id || (contact.client_id == self.client_id && self.access_controller?('central', 'all_contacts')) || (self.client.agency_access && self.agent? && contact.client.my_agencies.include?(self.client_id))
  end

  # current_user.access_controller?(Controller, Action)
  def access_controller?(controller, action, session = nil)
    return false if self.suspended?

    return false if session && self.agency_user_logged_in_as(session) && !self.agency_user_logged_in_as(session).access_controller?(controller, action)

    case controller
    when 'aiagents'
      self.aiagents_controller&.include?('allowed') && self.client.active? && !self.client.aiagent_included_count.to_i.zero?
    when 'campaigns'
      self.campaigns_controller.include?('allowed') && self.client.active? && self.client.campaigns_count.positive?
    when 'central'
      case action
      when 'all_contacts'
        self.central_controller.include?('allowed') && self.client.active? && self.central_controller.include?('all_contacts') && self.client.message_central_allowed
      when 'allowed'
        self.central_controller.include?('allowed') && self.client.active? && self.client.message_central_allowed
      else
        false
      end
    when 'clients'
      case action
      when 'allowed'
        self.clients_controller.include?('allowed')
      when 'billing'
        self.clients_controller.include?('allowed') && self.clients_controller.include?('billing')
      when 'custom_fields'
        self.clients_controller.include?('allowed') && self.client.active? && self.clients_controller.include?('custom_fields') && self.client.custom_fields_count.positive?
      when 'dlc10'
        self.clients_controller.include?('allowed') && self.client.active? && self.client.usa? && self.clients_controller.include?('dlc10') && self.client.dlc10_required
      when 'features'
        self.team_member? && self.client.active?
      when 'groups'
        self.clients_controller.include?('allowed') && self.client.active? && self.clients_controller.include?('groups') && self.client.groups_count.positive?
      when 'holidays'
        self.clients_controller.include?('allowed') && self.client.active? && self.clients_controller.include?('holidays')
      when 'kpis'
        self.clients_controller.include?('allowed') && self.client.active? && self.clients_controller.include?('kpis')
      when 'lead_sources'
        self.clients_controller.include?('allowed') && self.client.active? && self.clients_controller.include?('lead_sources')
      when 'folder_assignments'
        self.clients_controller.include?('allowed') && self.client.active? && self.clients_controller.include?('folder_assignments') && self.client.folders_count.positive?
      when 'org_chart'
        self.clients_controller.include?('allowed') && self.client.active? && self.clients_controller.include?('org_chart')
      when 'phone_numbers'
        self.clients_controller.include?('allowed') && self.client.active? && self.clients_controller.include?('phone_numbers')
      when 'profile'
        self.clients_controller.include?('allowed') && self.client.active? && self.clients_controller.include?('profile')
      when 'stages', 'pipelines'
        self.clients_controller.include?('allowed') && self.client.active? && self.clients_controller.include?('pipelines') && self.client.stages_count.positive?
      when 'settings'
        self.clients_controller.include?('allowed') && self.client.active? && self.clients_controller.include?('settings')
      when 'statements'
        self.clients_controller.include?('allowed') && self.client.active? && self.clients_controller.include?('statements')
      when 'tags'
        self.clients_controller.include?('allowed') && self.client.active? && self.clients_controller.include?('tags')
      when 'task_actions'
        self.clients_controller.include?('allowed') && self.client.active? && self.clients_controller.include?('task_actions') && self.client.tasks_allowed
      when 'terms'
        self.clients_controller.include?('allowed') && self.client.active? && self.clients_controller.include?('terms')
      when 'users'
        self.clients_controller.include?('allowed') && self.client.active? && self.clients_controller.include?('users')
      when 'voice_recordings'
        self.clients_controller.include?('allowed') && self.client.active? && self.clients_controller.include?('voice_recordings')
      else
        false
      end
    when 'companies'
      self.client.active? && (self.team_member? || (self.agent? && self.companies_controller.include?('allowed') && self.client.agency_access))
    when 'dashboard'
      case action
      when 'allowed'
        self.dashboard_controller.include?('allowed')
      when 'calendar'
        self.dashboard_controller.include?('allowed') && self.client.active? && self.dashboard_controller.include?('calendar')
      when 'tasks'
        self.dashboard_controller.include?('allowed') && self.client.active? && self.dashboard_controller.include?('tasks') && self.client.tasks_allowed
      when 'company_tiles'
        self.dashboard_controller.include?('allowed') && self.client.active? && self.dashboard_controller.include?('company_tiles')
      when 'all_contacts'
        self.dashboard_controller.include?('allowed') && self.client.active? && self.dashboard_controller.include?('all_contacts')
      else
        false
      end
    when 'email_templates'
      self.email_templates_controller.include?('allowed') && self.client.active? && !self.client.max_email_templates.to_i.zero?
    when 'import_contacts'
      self.import_contacts_controller.include?('allowed') && self.client.active? && self.client.import_contacts_count.to_i.positive?
    when 'integrations'
      case action
      when 'client'
        self.integrations_controller.include?('client') && self.client.active? && self.client.integrations_allowed.present?
      when 'user'
        self.integrations_controller.include?('user') && self.client.active? && self.client.integrations_allowed.present?
      when 'google_messages'
        self.integrations_controller.include?('google_messages') && self.client.active? && self.client.integrations_allowed.include?('google')
      when 'google_reviews'
        self.integrations_controller.include?('google_reviews') && self.client.active? && self.client.integrations_allowed.include?('google')
      when 'google_review_replies'
        self.integrations_controller.include?('google_review_replies') && self.client.active? && self.client.integrations_allowed.include?('google')
      else
        false
      end
    when 'integrations_servicetitan'
      if action == 'contact_balances'
        self.integrations_servicetitan_controller.include?('contact_balances') && self.client.active? && self.client.integrations_allowed.include?('servicetitan')
      else
        false
      end
    when 'my_contacts'
      case action
      when 'allowed'
        self.my_contacts_controller.include?('allowed') && self.client.active? && self.client.my_contacts_allowed
      when 'all_contacts'
        self.my_contacts_controller.include?('allowed') && self.client.active? && self.client.my_contacts_allowed && self.my_contacts_controller.include?('all_contacts')
      when 'schedule_actions'
        self.my_contacts_controller.include?('allowed') && self.client.active? && self.client.my_contacts_allowed && self.my_contacts_controller.include?('schedule_actions')
      else
        false
      end
    when 'stages'
      case action
      when 'allowed'
        self.stages_controller.include?('allowed') && self.client.active? && self.client.stages_count.positive?
      when 'all_contacts'
        self.stages_controller.include?('allowed') && self.client.active? && self.client.stages_count.positive? && self.stages_controller.include?('all_contacts')
      else
        false
      end
    when 'surveys'
      self.surveys_controller.include?('allowed') && self.client.active? && self.client.surveys_count.to_i.positive?
    when 'trackable_links'
      self.trackable_links_controller.include?('allowed') && self.client.active? && self.client.trackable_links_count.to_i.positive?
    when 'trainings'
      self.trainings_controller.include?('allowed') && self.client.active? && self.client.training.present?
    when 'user_contact_forms'
      self.user_contact_forms_controller.include?('allowed') && self.client.active? && self.client.quick_leads_count.to_i.positive?
    when 'users'
      case action
      when 'admin_settings'
        self.users_controller.include?('allowed') && self.client.active? && self.users_controller.include?('admin_settings')
      when 'allowed'
        self.users_controller.include?('allowed') && self.client.active?
      when 'notifications'
        self.users_controller.include?('allowed') && self.client.active? && self.users_controller.include?('notifications')
      when 'permissions'
        self.users_controller.include?('allowed') && self.client.active? && self.users_controller.include?('permissions')
      when 'phone_processing'
        self.users_controller.include?('allowed') && self.client.active? && self.users_controller.include?('phone_processing') && self.client.phone_calls_allowed && self.client.current_max_phone_numbers.positive?
      when 'profile'
        self.users_controller.include?('allowed') && self.client.active? && self.users_controller.include?('profile')
      when 'tasks'
        self.users_controller.include?('allowed') && self.client.active? && self.users_controller.include?('tasks') && self.client.tasks_allowed
      else
        false
      end
    when 'widgets'
      self.widgets_controller.include?('allowed') && self.client.active? && self.client.widgets_count.to_i.positive?
    else
      false
    end
  end

  def agency_user_logged_in_as(session)
    session.dig(:agency_user_token).to_s.present? && self.agency_user_tokens.include?(session[:agency_user_token].to_s) ? User.find_by('data @> ?', { my_agent_token: session[:agency_user_token].to_s }.to_json) : nil
  end

  def admin?
    self.super_admin? || self.access_controller?('users', 'permissions')
  end

  def agent?
    self.team_member? || (self.agent && self.client.agency_access)
  end

  def self.all_users
    User.joins(:client).includes(:client).where('clients.data @> ?', { active: true }.to_json).where(suspended_at: nil).or(User.joins(:client).includes(:client).where('clients.data @> ?', { active: true }.to_json).where('suspended_at > ?', Time.current))
  end

  def apply_omniauth(auth)
    self.update(
      provider: auth.provider,
      uid:      auth.uid
    )
  end

  def assign_to_all_client_phone_numbers!
    self.transaction do
      self.client.twnumbers.each do |twnumber|
        twnumber.twnumberusers.find_or_create_by(user_id: self.id) do |twnumberuser|
          twnumberuser.def_user = false
        end
      end
    end
  end

  # verify that avatar file exists in Cloudinary
  # User.avatar_exists?
  def avatar_exists?
    response = false

    if self.avatar&.file&.public_id
      cloudinary_url = Cloudinary::Utils.cloudinary_url(self.avatar.file.public_id)
      conn = Faraday.new(url: cloudinary_url)
      head = conn.head

      response = true if head.status >= 200 && head.status < 300
    end

    response
  end

  def by_last_chat
    users_last_chat = {}

    self.client.users.where.not(id: self.id).find_each do |user|
      chats = UserChat.where(from_user_id: self.id, to_user_id: user.id).or(UserChat.where(from_user_id: user.id, to_user_id: self.id)).order(:created_at)
      users_last_chat[user.id] = chats.last if chats.any?
    end

    users = {}

    self.client.users.where.not(id: self.id).find_each do |user|
      users[user.id] = {
        user:,
        last_chat:  users_last_chat[user.id].nil? ? UserChat.new : users_last_chat[user.id],
        created_at: users_last_chat[user.id].nil? ? 10.years.ago : users_last_chat[user.id].created_at
      }
    end

    users.sort_by { |_k, v| v[:created_at] }.reverse.to_h
  end

  def clear_unread_messages
    # rubocop:disable Rails/SkipsModelValidations
    Messages::Message.unread_messages_by_user(self.id).update_all(read_at: DateTime.current.to_s, read_at_user_id: self.id, updated_at: DateTime.current.to_s)
    # rubocop:enable Rails/SkipsModelValidations

    Messages::UpdateUnreadMessageIndicatorsJob.perform_later(user_id: self.id)
  end

  # find User settings for a controller/action
  # controller_action_settings(controller_action, session)
  def controller_action_settings(controller_action, id = 0)
    user_setting = nil
    user_setting = self.user_settings.find_by(id:) if id.to_i.positive?
    user_setting = self.user_settings.where(controller_action:).find_by(current: 1) if user_setting.nil?
    user_setting = self.user_settings.where(controller_action:).find_by(name: 'Last Used') if user_setting.nil?
    user_setting = self.user_settings.new(name: 'Last Used', controller_action:, current: 1) if user_setting.nil?

    user_setting
  end

  # determine if there are any User settings for a controller/action
  # controller_action_settings?(controller_action)
  def controller_action_settings?(controller_action)
    self.user_settings.where(controller_action:).any?
  end

  # create a collection of all User settings saved for a controller/action
  # controller_action_settings_collection(controller_action)
  def controller_action_settings_collection(controller_action)
    self.user_settings.where(controller_action:).order(:name)
  end

  # count User settings saved for a controller/action
  # controller_action_settings_count(controller_action)
  def controller_action_settings_count(controller_action)
    self.user_settings.where(controller_action:).count
  end

  # create options for select of all User settings saved for a controller/action
  # controller_action_settings_options(controller_action)
  def controller_action_settings_options(controller_action)
    self.controller_action_settings_collection(controller_action).pluck(:name, :id)
  end

  # clear all default User settings and destroy any "Last Used" User settings for a controller/action
  # controller_action_settings_reset(controller_action)
  def controller_action_settings_reset(controller_action)
    # rubocop:disable Rails/SkipsModelValidations
    self.user_settings.where(controller_action:).update_all(current: '0')
    # rubocop:enable Rails/SkipsModelValidations
    self.user_settings.where(controller_action:).where(name: ['Last Used', '']).destroy_all
  end

  # is this the default/primary user for the client?
  def default?
    self.id == self.client.def_user_id
  end
  alias primary? default?

  # return a phone number to send messages to User from
  # user.default_from_twnumber
  def default_from_twnumber
    twnumber = Twnumber.user_phone_numbers(self.id).find_by(twnumberusers: { def_user: true })
    twnumber = Twnumber.user_phone_numbers(self.id).first if twnumber.nil?
    twnumber = Twnumber.client_phone_numbers(self.client.id).first if twnumber.nil?

    twnumber
  end

  def facebook_linked?
    self.provider.present? && self.provider.casecmp?('facebook') && self.uid.present?
  end

  def firstname_last_initial
    [self.firstname, self.lastname[0].to_s].compact_blank.join(' ')
  end

  # allow User login using social media
  # User.from_omniauth(auth: ??)
  def self.from_omniauth(auth)
    user = User.find_by(provider: auth.provider, uid: auth.uid)

    if !user && auth.info.email && (user = User.where('lower(email) = ?', auth.info.email.downcase).first)
      user.update(
        provider: auth.provider,
        uid:      auth.uid
      )
    end

    # if auth.info.email and !auth.info.email.empty?
    #   user = User.find_by_email(auth.info.email)

    #   if @user
    #     user.password = Devise.friendly_token[0,20]
    #     user.save

    #   else
    #     user = Users.new
    #   end
    # else
    #   user = User.new
    # end

    # where(provider: auth.provider, uid: auth.uid).first_or_create do |u|
    #   u.email = auth.info.email
    #   u.password = Devise.friendly_token[0,20]
    #   u.name = auth.info.name   # assuming the user model has a name
    #   u.image = auth.info.image # assuming the user model has an image
    # If you are using confirmable and the provider(s) you use validate emails,
    # uncomment the line below to skip the confirmation emails.
    # u.skip_confirmation!
    # end

    user
  end

  def fullname
    Friendly.new.fullname(self.firstname, self.lastname)
  end

  # return an Array of User's selected Google calendars
  # User.google_calendar_array(UserApiIntegration)
  def google_calendar_array(user_api_integration = nil)
    response               = []
    user_api_integration ||= self.user_api_integrations.find_or_create_by(target: 'google', name: '')

    return response unless Integration::Google.valid_token?(user_api_integration)

    ggl_client = Integrations::Ggl::Calendar.new(user_api_integration.token, I18n.t('tenant.id'))
    ggl_client.calendar_list

    return response unless ggl_client.success?

    user_api_integration.dashboard_calendars.each do |dashboard_calendar|
      dashboard_calendar = dashboard_calendar.deep_symbolize_keys

      if (google_calendar = ggl_client.result.find { |x| x[:id] == dashboard_calendar[:id] })
        response << [google_calendar[:summary], google_calendar[:id]]
      end
    end

    response
  end

  # DEPRECATED (delete after 2030-10-21)
  # replaced by MyContacts::GroupActionJob
  # process a group action on Contacts
  # @user.group_action(action: String, contacts: Array)
  # (req) action:             (String)
  # (req) contacts:           (Array)
  # (opt) add_tag_id:         (Integer)
  # (opt) lead_source_id:     (Integer)
  # (opt) remove_tag_id:      (Integer)
  # (opt) add_stage_id:       (Integer)
  # (opt) remove_stage_id:    (Integer)
  # (opt) add_group_id:       (Integer)
  # (opt) apply_campaign_id:  (Integer)
  # (opt) target_time:        (Time)
  # (opt) stop_campaign_id:   (Integer)
  # (opt) user_id:            (Integer)
  # (opt) file_attachments:   (Array)
  # (opt) to_label:           (String)
  # (opt) from_phones:        (Array)
  # (opt) message:            (String)
  # (opt) voice_recording_id: (Integer)
  # (opt) selected_number:    (String)
  def group_action(args)
    JsonLog.info 'User.group_action', { args: }
    return unless args.include?(:action)

    # if User is an Admin & the Client that the first Contact belongs to is active
    # the Client may not be active after the Client is deactivated by a SuperAdmin
    if self.admin? && Contact.find_by(id: args[:contacts].first)&.client&.active?
      # add new message to div
      group_actions_count = DelayedJob.scheduled_actions(self.id, Time.current.beginning_of_month, Time.current.end_of_month + 12.months).count
      UserCable.new.broadcast self.client, self, { id: "mycontacts_group_action_count_#{self.id}", append: 'false', scrollup: 'false', html: group_actions_count.to_s }
    end

    case args[:action]
    when 'add_tag'
      Contact.where(id: args[:contacts]).find_each do |contact|
        Contacts::Tags::ApplyJob.perform_now(
          contact_id: contact.id,
          tag_id:     args.dig(:add_tag_id)
        )
      end
    when 'assign_lead_source'
      Contact.where(id: args[:contacts]).find_each do |contact|
        Contacts::LeadSources::AssignJob.perform_now(
          contact_id:     contact.id,
          lead_source_id: args[:lead_source_id]
        )
      end
    when 'remove_tag'
      Contact.where(id: args[:contacts]).find_each do |contact|
        Contacts::Tags::RemoveJob.perform_now(
          contact_id: contact.id,
          tag_id:     args[:remove_tag_id]
        )
      end
    when 'add_stage'
      Contact.where(id: args[:contacts]).find_each do |contact|
        Contacts::Stages::AddJob.perform_now(
          client_id:  contact.client_id,
          contact_id: contact.id,
          stage_id:   args[:add_stage_id]
        )
      end
    when 'remove_stage'
      Contact.where(id: args[:contacts], stage_id: args[:remove_stage_id]).find_each do |contact|
        Contacts::Stages::RemoveJob.perform_now(
          contact_id: contact.id,
          stage_id:   args[:remove_stage_id]
        )
      end
    when 'add_group'
      Contact.where(id: args[:contacts]).find_each do |contact|
        Contacts::Groups::AddJob.perform_now(
          contact_id: contact.id,
          group_id:   args[:add_group_id]
        )
      end
    when 'remove_group'
      Contact.where(id: args[:contacts]).find_each do |contact|
        Contacts::Groups::RemoveJob.perform_now(
          contact_id: contact.id,
          group_id:   args[:remove_group_id]
        )
      end
    when 'start_campaign'
      run_at = AcceptableTime.new(group_action_common_args(args)).new_time(Time.current)
      JsonLog.info 'User.group_action-start_campaign', { run_at: }

      return if run_at.blank?

      Contact.where(id: args[:contacts]).find_each do |contact|
        Contacts::Campaigns::StartJob.set(wait_until: run_at).perform_later(
          campaign_id:   args[:apply_campaign_id],
          client_id:     contact.client_id,
          contact_id:    contact.id,
          group_process: 1,
          target_time:   args[:target_time],
          user_id:       self.id
        )

        run_at += 1.second
      end
    when 'stop_campaign'
      Contact.where(id: args[:contacts]).find_each do |contact|
        Contacts::Campaigns::StopJob.set(wait_until: 1.day.from_now).perform_later(
          campaign_id:   args[:stop_campaign_id],
          contact_id:    contact.id,
          group_process: 1,
          process:       'broadcast_stop_campaign',
          user_id:       self.id
        )
      end
    when 'contact_sleep'
      Contact.where(id: args[:contacts]).find_each do |contact|
        contact.update(sleep: true)
      end
    when 'contact_awake'
      Contact.where(id: args[:contacts]).find_each do |contact|
        contact.update(sleep: false)
      end
    when 'ok2text_on'
      Contact.where(id: args[:contacts]).find_each do |contact|
        contact.update(ok2text: 1)
      end
    when 'ok2text_off'
      Contact.where(id: args[:contacts]).find_each do |contact|
        contact.update(ok2text: 0)
      end
    when 'contact_delete'
      Contact.where(id: args[:contacts]).destroy_all
    when 'assign_user'
      Contact.where(id: args[:contacts]).find_each do |contact|
        contact.assign_user(args[:user_id])
      end
    when 'send_email'
      run_at = AcceptableTime.new(group_action_common_args(args)).new_time(Time.current)

      return if run_at.blank?

      Contact.where(id: args[:contacts]).find_each do |contact|
        contact.delay(
          run_at:,
          priority:   DelayedJob.job_priority('group_send_email'),
          queue:      DelayedJob.job_queue('group_send_email'),
          contact_id: contact.id,
          user_id:    contact.user_id,
          process:    'group_send_email',
          data:       { email_template_id: args[:email_template_id], contact:, user: self }
        ).send_email(
          email_template_id:    args[:email_template_id].to_i,
          email_template_yield: args[:email_template_yield],
          subject:              args[:email_template_subject],
          from_email:           self.email,
          file_attachments:     args[:file_attachments],
          payment_request:      args[:payment_request].to_f
        )
      end
    when 'send_text'
      run_at = AcceptableTime.new(group_action_common_args(args)).new_time(Time.current)

      return if run_at.blank?

      from_phones_element = 0

      Contact.where(id: args[:contacts]).find_each do |contact|
        # add images to message
        image_id_array = []

        args[:file_attachments].each do |fa|
          fa.deep_symbolize_keys!

          case fa[:type].to_s
          when 'user'
            file_attachment = self.user_attachments.find_by(id: fa[:id])
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
                  Appsignal.set_action('User.group_action')

                  # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
                  Appsignal.add_params(args)

                  Appsignal.set_tags(
                    error_level: 'error',
                    error_code:  0
                  )
                  Appsignal.add_custom_data(
                    fa:                           fa.inspect,
                    file_attachment:              file_attachment.inspect,
                    user_action_file_attachments: args[:file_attachments].inspect,
                    contact_attachment:           defined?(contact_attachment) ? contact_attachment.inspect : 'Undefined',
                    file:                         __FILE__,
                    line:                         __LINE__
                  )
                end
              rescue ActiveRecord::RecordInvalid => e
                e.set_backtrace(BC.new.clean(caller))

                Appsignal.report_error(e) do |transaction|
                  # Only needed if it needs to be different or there's no active transaction from which to inherit it
                  Appsignal.set_action('User.group_action')

                  # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
                  Appsignal.add_params(args)

                  Appsignal.set_tags(
                    error_level: 'error',
                    error_code:  0
                  )
                  Appsignal.add_custom_data(
                    fa:                           fa.inspect,
                    file_attachment:              file_attachment.inspect,
                    user_action_file_attachments: args[:file_attachments].inspect,
                    contact_attachment:           defined?(contact_attachment) ? contact_attachment.inspect : 'Undefined',
                    file:                         __FILE__,
                    line:                         __LINE__
                  )
                end
              rescue StandardError => e
                e.set_backtrace(BC.new.clean(caller))

                Appsignal.report_error(e) do |transaction|
                  # Only needed if it needs to be different or there's no active transaction from which to inherit it
                  Appsignal.set_action('User.group_action')

                  # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
                  Appsignal.add_params(args)

                  Appsignal.set_tags(
                    error_level: 'error',
                    error_code:  0
                  )
                  Appsignal.add_custom_data(
                    fa:                           fa.inspect,
                    file_attachment:              file_attachment.inspect,
                    user_action_file_attachments: args[:file_attachments].inspect,
                    contact_attachment:           defined?(contact_attachment) ? contact_attachment.inspect : 'Undefined',
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

        contact_phones = if args.include?(:to_label) && !args[:to_label].to_s.strip.empty?
                           contact.contact_phones.where(label: args[:to_label]).pluck(:phone)
                         else
                           contact.contact_phones.where(primary: true).pluck(:phone)
                         end

        contact_phones.each do |to_phone|
          from_phone = if args[:from_phones].include?('last') || args[:from_phones].blank?

                         if (message = contact.messages.where(to_phone:).or(contact.messages.where(from_phone: to_phone)).order(created_at: :desc).limit(1).first)
                           message.to_phone == to_phone ? message.from_phone : message.to_phone
                         elsif args[:from_phones][from_phones_element] == 'last' && args[:from_phones].length > 1
                           args[:from_phones][from_phones_element = from_phones_element + 1 == args[:from_phones].length ? 0 : from_phones_element + 1]
                         else
                           self.default_from_twnumber&.phonenumber.to_s
                         end
                       else
                         args[:from_phones][from_phones_element]
                       end

          JsonLog.info 'User.group_action-send_text', { message: 'From Phone Number Empty', args: }, user_id: self.id, contact_id: contact.id

          run_at = PhoneNumberReservations.new(from_phone).reserve(group_action_common_args(args).merge(action_time: run_at)) if from_phone.present?
          JsonLog.info 'User.group_action-send_text', { run_at: }

          if run_at.present?
            contact.delay(
              run_at:,
              priority:            DelayedJob.job_priority('broadcast_send_text'),
              queue:               DelayedJob.job_queue('broadcast_send_text'),
              user_id:             self.id,
              contact_id:          contact.id,
              triggeraction_id:    0,
              contact_campaign_id: 0,
              data:                { content: args[:message], image_id_array: },
              group_process:       1,
              process:             'broadcast_send_text'
            ).send_text(
              automated:      true,
              content:        args[:message],
              from_phone:,
              image_id_array:,
              msg_type:       'textout',
              to_phone:,
              user:           self
            )

            # run_at += (self.client.text_delay.to_i / args[:from_phones].length).seconds unless args[:from_phones].empty?
          end
        end

        from_phones_element = from_phones_element + 1 == args[:from_phones].length ? 0 : from_phones_element + 1
      end
    when 'send_rvm'
      voice_recording = self.client.voice_recordings.find_by(id: args[:voice_recording_id].to_i)

      if voice_recording
        run_at = AcceptableTime.new(group_action_common_args(args)).new_time(Time.current)

        if run_at.present?
          voice_recording_url = if voice_recording.audio_file.attached?
                                  "#{Cloudinary::Utils.cloudinary_url(voice_recording.audio_file.key, resource_type: 'video', secure: true)}.mp3"
                                else
                                  voice_recording.url
                                end

          Contact.where(id: args[:contacts]).find_each do |contact|
            contact_phones = if args.include?(:to_label) && !args[:to_label].to_s.strip.empty?
                               contact.contact_phones.where(label: args[:to_label]).pluck(:phone)
                             else
                               contact.contact_phones.where(primary: true).pluck(:phone)
                             end

            contact_phones.each do |to_phone|
              JsonLog.info 'User.group_action-send_rvm', { run_at: }
              data = {
                from_phone:          args[:selected_number],
                message:             voice_recording.recording_name,
                to_phone:,
                user:                self,
                voice_recording_id:  voice_recording.id,
                voice_recording_url:
              }
              contact.delay(
                run_at:,
                priority:            DelayedJob.job_priority('group_send_rvm'),
                queue:               DelayedJob.job_queue('group_send_rvm'),
                user_id:             self.id,
                contact_id:          contact.id,
                triggeraction_id:    0,
                contact_campaign_id: 0,
                data:,
                group_process:       1,
                process:             'group_send_rvm'
              ).send_rvm(data)

              run_at += self.client.text_delay.seconds
            end
          end
        end
      end
    end
  end

  # DEPRECATED (delete after 2030-10-21)
  # replaced by MyContacts::GroupActionBlockJob
  # break down a group action into smaller blocks
  # @user.group_action_block(action: String, contacts: Array)
  # (req) action:                   (String)
  # (req) contacts:                 (Array)
  # (opt) from_phones:              (Array)
  # (opt) user_action_quantity:     (Integer)
  # (opt) user_action_quantity_all: (Boolean)
  def group_action_block(args)
    JsonLog.info 'User.group_action_block', { args: }
    user_action_quantity     = args.dig(:user_action_quantity).to_i
    user_action_quantity_all = (args.dig(:user_action_quantity_all).nil? ? true : args[:user_action_quantity_all]).to_bool
    group_size               = user_action_quantity_all || user_action_quantity.zero? ? args[:contacts].length : user_action_quantity
    args[:file_attachments]  = args[:file_attachments] ? args[:file_attachments].collect(&:symbolize_keys) : []

    return if group_size.zero?

    max_block_qty    = 50
    text_delay       = self.client.text_delay.to_i
    block_start_time = Time.current

    args[:contacts].in_groups_of(group_size, false).each do |contacts_block|
      acceptable_block_start_time = AcceptableTime.new(group_action_common_args(args)).new_time(block_start_time)
      JsonLog.info 'User.group_action_block', { acceptable_block_start_time: }

      if acceptable_block_start_time.present?
        block_start_time = acceptable_block_start_time
        run_at           = block_start_time

        contacts_block.in_groups_of(max_block_qty, false) do |contacts|
          data = args.merge({ contacts: })

          self.delay(
            run_at:,
            priority:            DelayedJob.job_priority("group_#{args[:action]}"),
            queue:               DelayedJob.job_queue("group_#{args[:action]}"),
            user_id:             self.id,
            triggeraction_id:    0,
            contact_campaign_id: 0,
            group_process:       1,
            process:             "group_#{args[:action]}",
            data:
          ).group_action(data)

          run_at += case args[:action]
                    when 'send_rvm', 'start_campaign'
                      (text_delay * [max_block_qty, contacts.length].min).seconds
                    when 'send_text'
                      ((text_delay * [max_block_qty, contacts.length].min) / [args[:from_phones].length, 1].max).seconds
                    else
                      30.seconds
                    end
        end
      end

      block_start_time += args.dig(:user_action_quantity_interval).to_i.send((args.dig(:user_action_quantity_period) || 'days').to_s)
    end

    # if User is an Admin & the Client that the first Contact belongs to is active
    # the Client may not be active after the Client is deactivated by a SuperAdmin
    return unless self.admin? && Contact.find_by(id: args[:contacts].first)&.client&.active?

    # add new message to div
    group_actions_count = DelayedJob.scheduled_actions(self.id, Time.current.beginning_of_month, Time.current.end_of_month + 12.months).count
    UserCable.new.broadcast self.client, self, { id: "mycontacts_group_action_count_#{self.id}", append: 'false', scrollup: 'false', html: group_actions_count.to_s }
  end

  # DEPRECATED (delete after 2030-10-21)
  # replaced by MyContacts::GroupActionBlockJob & MyContacts::GroupActionJob
  def group_action_common_args(args = {})
    JsonLog.info 'User.group_action_common_args', { args: }
    {
      time_zone:     self.client.time_zone,
      reverse:       false,
      delay_months:  0,
      delay_days:    0,
      delay_hours:   0,
      delay_minutes: 0,
      safe_start:    args.dig(:user_action_safe_times)&.first || 480,
      safe_end:      args.dig(:user_action_safe_times)&.second || 1200,
      safe_sun:      args.dig(:safe_sun) || true,
      safe_mon:      args.dig(:safe_mon) || true,
      safe_tue:      args.dig(:safe_tue) || true,
      safe_wed:      args.dig(:safe_wed) || true,
      safe_thu:      args.dig(:safe_thu) || true,
      safe_fri:      args.dig(:safe_fri) || true,
      safe_sat:      args.dig(:safe_sat) || true,
      holidays:      if args.dig(:user_action_honor_holidays).to_bool
                       self.client.holidays.to_h { |h| [h.occurs_at, (h.action == 'before' ? 'after' : h.action)] }
                     else
                       {}
                     end,
      ok2skip:       false
    }
  end

  # return User initials
  def initials
    self.firstname[0].to_s + self.lastname[0].to_s
  end

  # return the from_phone number to use for this User
  # user.latest_client_phonenumber
  #   (opt) current_session: (Hash / default: {})
  def latest_client_phonenumber(args = {})
    current_session = (args.dig(:current_session) || {}).to_h
    selected_number = current_session.dig(:selected_number).to_s

    if selected_number.present?
      self.client.twnumbers.find_by(phonenumber: selected_number)
    else
      self.default_from_twnumber
    end
  end

  # define message central settings & collect Contact lists for User
  # ex: user.message_central_settings
  # ex: user.message_central_settings(show_user_ids: Array, include_automated: Boolean, per_page: Integer, page: Integer)
  # no arguments are required
  # each argument sets the respective setting in Users::Setting
  def message_central_settings(args = {})
    user_settings = self.message_central_user_settings(args)

    active_contacts_list_args = {
      group_id:          (user_settings.data.dig(:active_contacts_group_id) || 0).to_i,
      include_automated: user_settings.data.dig(:include_automated).to_bool,
      include_sleeping:  user_settings.data.dig(:include_sleeping).to_bool,
      msg_types:         user_settings.data.dig(:msg_types),
      past_days:         (user_settings.data.dig(:active_contacts_period) || 15).to_i
    }

    result = user_settings.contacts_list_clients_users(controller: 'central')
    active_contacts_list_args[:client_ids] = result[:client_ids]
    active_contacts_list_args[:user_ids]   = result[:user_ids]

    # active_contacts_list = Kaminari.paginate_array(Contact.active_contacts_list(active_contacts_list_args)).page(user_settings.data[:page]).per(user_settings.data[:per_page])
    active_contacts_list = self.active_contacts_list(active_contacts_list_args:, page: user_settings.data[:page], per_page: user_settings.data[:per_page])

    [user_settings, active_contacts_list]
  end

  # define message central settings for User
  # ex: user.message_central_user_settings
  # ex: user.message_central_user_settings(show_user_ids: Array, include_automated: Boolean, per_page: Integer, page: Integer)
  # no arguments are required
  # each argument sets the respective setting in Users::Setting
  def message_central_user_settings(args = {})
    # show_user_ids      = [args.dig(:show_user_ids) || -1].flatten
    include_automated = args.dig(:include_automated)
    per_page          = args.dig(:per_page).to_i
    page              = args.dig(:page).to_i

    user_settings = self.user_settings.find_or_initialize_by(controller_action: 'message_central')
    user_settings.current                  = 1
    user_settings.data                     = {} unless user_settings.data.is_a?(Hash)
    user_settings.data[:include_sleeping]  = false unless user_settings.data.include?(:include_sleeping)
    user_settings.data[:include_automated] = include_automated.nil? ? user_settings.data.dig(:include_automated).to_bool : include_automated.to_bool
    user_settings.data[:per_page]          = per_page.positive? ? per_page : (user_settings.data.dig(:per_page) || 10).to_i
    user_settings.data[:page]              = page.positive? ? page : (user_settings.data.dig(:page) || 1).to_i

    show_user_ids                          = user_settings.contacts_list_clients_users(controller: 'central')
    user_settings.data[:show_user_ids]     = (show_user_ids[:user_ids] << show_user_ids[:client_ids].map { |id| "all_#{id}" }).compact_blank.flatten.uniq
    user_settings.save

    user_settings
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if (data = session['devise.facebook_data']) && session['devise.facebook_data']['extra']['raw_info'] && user.email.blank?
        user.email = data['email']
      end
    end
  end

  # User.notify_all_users()
  #   (req) target:  (Array) ex: ['mobile', 'desktop']
  #   (req) content: (String)
  #   (opt) title:   (String)
  #   (opt) url:     (String)
  def self.notify_all_users(args = {})
    self.notify_all_users_on_toast(args.dig(:content)) if args.dig(:target).include?('toast')
    self.notify_all_users_on_desktop(args) if args.dig(:target).include?('desktop')
    self.notify_all_users_on_mobile(args) if args.dig(:target).include?('mobile')
  end

  # User.notify_all_users_on_desktop()
  #   (req) content: (String)
  #   (opt) title:   (String)
  #   (opt) url:     (String)
  def self.notify_all_users_on_desktop(args = {})
    return if args.dig(:content).blank?

    os_client = Notifications::OneSignal::V1::Base.new('all_users')
    os_client.send_push(args)

    os_client.success?
  end

  # User.notify_all_users_on_mobile()
  #   (req) content: (String)
  #   (opt) title:   (String)
  #   (opt) url:     (String)
  def self.notify_all_users_on_mobile(args = {})
    return if args.dig(:content).blank?

    pm_client = Notifications::PushMobile.new(UserPush.all_mobile_keys)
    pm_client.send_push(args)

    pm_client.success?
  end

  def self.notify_all_users_on_toast(content)
    return if content.blank?

    user_cable = UserCable.new

    self.all_users.find_each do |user|
      user_cable.broadcast user.client, user, { toastr: ['info', content] }
    end
  end

  # Return the OTP code for the User
  def otp_code
    return nil unless self.otp_secret && self.otp_secret_at

    otp = ROTP::TOTP.new(self.otp_secret)
    otp.at(self.otp_secret_at)
  end

  # Determine if the given otp_attempt is a valid OTP code
  # @user.otp_code_valid?(otp_attempt)
  #   (req) otp_attempt: (String)
  def otp_code_valid?(otp_attempt)
    # otp_secret_at is stored as a string integer (because it is encrypted)
    return false unless Time.at(self.otp_secret_at.to_i).utc > 1.hour.ago

    otp = ROTP::TOTP.new(self.otp_secret)
    otp.verify(otp_attempt.to_s, at: self.otp_secret_at.to_i).present?
  end

  # check text for "task" & "done", "finish" or "complete"
  #   Task id must be between "task" and "done", "finish" or "complete"
  #   if received find the Task and mark it completed
  # User.parse_text_to_complete_task( message )
  def self.parse_text_to_complete_task(message)
    return unless message.is_a?(Messages::Message) && message.message.downcase.include?('task') &&
                  (message.message.downcase.include?('done') || message.message.downcase.include?('finish') || message.message.downcase.include?('complete'))

    task_id = message.message.split[1].to_i

    return unless task_id.positive? && (user = message.contact.client.users.find_by(phone: message.from_phone)) && (task = user.tasks.find_by(id: task_id))

    task.update(completed_at: Time.current)
  end

  # send an email to this User
  # @user.send_email(content: String, subject: String)
  #   (req) subject:    (String) email subject
  #   (req) content:    (String) email body
  #   (opt) bcc_email:        (Array or String)
  #            [{ email: '', name: ''}]
  #   (opt) cc_email:         (Array or String)
  #            [{ email: '', name: ''}]
  #   (opt) from_email:       (Hash or String) email to send from / blank for User email
  #            { email: '', name: ''}
  #   (opt) reply_email:      (Hash or String)
  #            { email: '', name: ''}
  #   (opt) triggeraction_id: (Integer) Triggeraction that initiated this message
  #
  def send_email(args = {})
    return unless args.dig(:subject).present? && args.dig(:content).present? && !self.suspended? && self.client.active?

    to_email    = if args.dig(:to_email).is_a?(Array)
                    args[:to_email]
                  else
                    args.dig(:to_email).is_a?(String) && args[:to_email].present? ? args[:to_email].split(',').map { |email| { email: email.strip, name: '' } } : [{ email: self.email, name: self.fullname }]
                  end
    from_email  = if args.dig(:from_email).is_a?(Hash)
                    args[:from_email]
                  elsif args.dig(:from_email).is_a?(String) && args[:from_email].present?
                    { email: args[:from_email], name: '' }
                  else
                    { email: "support@#{I18n.t('tenant.domain')}", name: "#{I18n.t('tenant.name')} Support" }
                  end
    cc_email    = if args.dig(:cc_email).is_a?(Array)
                    args[:cc_email]
                  else
                    args.dig(:cc_email).is_a?(String) && args[:cc_email].present? ? args[:cc_email].split(',').map { |email| { email: email.strip, name: '' } } : []
                  end
    bcc_email   = if args.dig(:bcc_email).is_a?(Array)
                    args[:bcc_email]
                  else
                    args.dig(:bcc_email).is_a?(String) && args[:bcc_email].present? ? args[:bcc_email].split(',').map { |email| { email: email.strip, name: '' } } : []
                  end
    reply_email = if args.dig(:reply_email).is_a?(Hash)
                    args[:reply_email]
                  else
                    args.dig(:reply_email).is_a?(String) && args[:reply_email].present? ? { email: args[:reply_email], name: '' } : from_email
                  end

    return unless from_email.present? && to_email.present?

    # convert links tagged as attachments to email attachments
    parsed_content = Nokogiri::HTML.parse(args[:content])
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

    content = parsed_content.to_html

    e_client = Email::Base.new
    e_client.send(
      client:      self.client,
      from_email:,
      to_email:,
      cc_email:,
      bcc_email:,
      reply_email:,
      subject:     args[:subject].to_s,
      content:,
      attachments:
    )
  end

  # send an invitation to User to create/change password
  # user.send_invitation
  def send_invitation
    return if self.suspended? || !self.client.active?

    self.invite!

    app_host = I18n.with_locale(self.client.tenant) { I18n.t("tenant.#{Rails.env}.app_host") }

    self.delay(
      data:                {},
      contact_campaign_id: 0,
      contact_id:          0,
      priority:            DelayedJob.job_priority('send_text_to_user'),
      process:             'send_text_to_user',
      queue:               DelayedJob.job_queue('send_text_to_user'),
      run_at:              Time.current,
      triggeraction_id:    0,
      user_id:             self.id
    ).send_text(
      content:  "#{I18n.t('devise.text.invitation_instructions.hello').gsub('%{firstname}', self.firstname)} - #{I18n.t('devise.text.invitation_instructions.someone_invited_you')} #{I18n.t('devise.text.invitation_instructions.accept')} #{Rails.application.routes.url_helpers.accept_user_invitation_url(invitation_token: self.raw_invitation_token, host: app_host)}",
      msg_type: 'textoutuser'
    )
  end

  # send a message to User using Slack
  # User.send_slack()
  #   (req) title:   (String)
  #     ~ or ~
  #   (req) content: (String)
  #   (opt) url:     (String)
  def send_slack(args = {})
    return false unless (args.dig(:content).to_s + args.dig(:title).to_s).present? && !self.suspended? && self.client.active? &&
                        (user_api_integration = self.user_api_integrations.find_by(target: 'slack', name: '')) && user_api_integration.notifications_channel.present?

    Integrations::Slack::PostMessageJob.perform_later(
      channel: user_api_integration.notifications_channel,
      content: [args.dig(:title).to_s.present? ? "#{args[:title]}:" : '', args.dig(:content).to_s, args.dig(:url).to_s].compact_blank.join(' '),
      token:   user_api_integration.token
    )
  end

  # send a text message to this User
  # @user.send_text()
  #   (opt) automated:               (Boolean / default: false)
  #   (opt) contact_campaign_id:     (Integer / default: nil)
  #   (opt) contact_estimate_id:     (Integer / default: nil)
  #   (opt) contact_id:              (Integer / default: nil)
  #   (opt) contact_invoice_id:      (Integer / default: nil)
  #   (opt) contact_job_id:          (Integer / default: nil)
  #   (opt) contact_subscription_id: (Integer / default: nil)
  #   (opt) contact_visit_id:        (Integer / default: nil)
  #   (opt) content:                 (String / default: '')
  #   (opt) from_phone:              (String / default: self.latest_client_phonenumber)
  #   (opt) image_id_array:          (Array / default: [])
  #   (opt) msg_type:                (String / default: 'textoutuser')
  #   (opt) ok2text:                 (Boolean / default: false)
  #   (opt) send_to:                 (String / default: '')
  #   (opt) to_phone:                (String / default: '')
  #   (opt) triggeraction_id:        (Integer / default: nil)
  #   (opt) sending_user:            (User / default: self)
  def send_text(args = {})
    return false unless (args.dig(:ok2text).nil? || args.dig(:ok2text).to_bool) && !self.suspended? && self.client.active?

    contact                 = args.include?(:contact_id) ? Contact.find_by(id: args[:contact_id].to_i) : nil
    from_phone              = args.dig(:from_phone).to_s.strip.downcase
    from_phone              = self.default_from_twnumber&.phonenumber.to_s if from_phone == 'user_number'
    from_phone              = contact.latest_client_phonenumber(default_ok: true, phone_numbers_only: true)&.phonenumber.to_s if (from_phone == 'last_number' || from_phone.blank?) && contact
    from_phone              = self.latest_client_phonenumber(default_ok: true, phone_numbers_only: true)&.phonenumber.to_s if from_phone.blank?
    to_phone                = if args.dig(:to_phone).to_s.strip.present?
                                [args[:to_phone].to_s]
                              elsif args[:send_to].to_s.empty?
                                [(contact ? contact.user.phone : self.phone).to_s.strip]
                              else
                                []
                              end
    response                = true

    # send_to supersedes to_phone when Contact is provided
    # ex: "user", "user_1234", "orgposition_1234"
    to_phone += contact.org_users(users_orgs: args[:send_to].to_s, purpose: 'text', default_to_all_users_in_org_position: false).pluck(0) if contact && args.dig(:send_to).to_s.present?

    to_phone.each do |phone|
      result = text_send(
        automated:               args.dig(:automated).to_bool,
        client:                  self.client,
        contact:,
        contact_estimate_id:     args.dig(:contact_estimate_id),
        contact_invoice_id:      args.dig(:contact_invoice_id),
        contact_job_id:          args.dig(:contact_job_id),
        contact_subscription_id: args.dig(:contact_subscription_id),
        contact_visit_id:        args.dig(:contact_visit_id),
        content:                 args.dig(:content).to_s.strip,
        from_phone:,
        image_id_array:          args.dig(:image_id_array).is_a?(Array) ? args[:image_id_array] : [],
        msg_type:                args.dig(:msg_type).present? && Messages::Message::MSG_TYPES_TEXTOUT.include?(args[:msg_type].to_s.downcase) ? args[:msg_type].to_s.downcase : 'textoutuser',
        sending_user:            args.dig(:sending_user) || self,
        to_phone:                phone,
        triggeraction_id:        args.dig(:triggeraction_id)
      )

      # only set to false if any text fails
      response = false unless result[:success]
    end

    Contacts::Campaigns::Triggeraction.completed(args.dig(:contact_campaign_id), args.dig(:triggeraction_id))

    response
  end

  def super_admin?
    self.super_admin || self.email == I18n.with_locale(self.client.tenant) { I18n.t("tenant.#{Rails.env}.key_user") }
  end

  def suspended?
    self.suspended_at.present? && self.suspended_at <= Time.current
  end

  def team_member?
    team_member || super_admin?
  end

  def user?
    true
  end

  # protected

  def password_required?
    return false if skip_password_validation

    super
  end

  private

  def after_create_commit_actions
    super

    self.notifications[:text] = {
      arrive:     self.notifications.dig('text', 'arrive').present? ? self.notifications['text']['arrive'] : [self.id],
      on_contact: self.notifications.dig('text', 'on_contact').nil? ? false : self.notifications['text']['on_contact'].to_bool
    }
    self.save
    Integration::Vitally::V2024::Base.new.user_push(self.id) if self.client.ok_to_push_to_vitally?
  end

  def after_destroy_commit_actions
    super

    Triggeraction.for_client_and_action_type(self.client_id, [615, 700]).find_each do |triggeraction|
      triggeraction.campaign.update(analyzed: triggeraction.campaign.analyze!.empty?) if triggeraction.user_id.to_i == self.id
    end

    Clients::Widget.where(client_id: self.client_id).includes(:client).find_each do |client_widget|
      client_widget.w_user_id     = client_widget.client.def_user_id if client_widget.w_user_id.to_i.positive? && client_widget.w_user_id.to_i == self.id
      client_widget.bb_user_id    = client_widget.client.def_user_id if client_widget.bb_user_id.to_i.positive? && client_widget.bb_user_id.to_i == self.id
      client_widget.image_user_id = client_widget.client.def_user_id if client_widget.image_user_id.to_i.positive? && client_widget.image_user_id.to_i == self.id

      client_widget.w_dd_actions&.each_value do |values|
        values['user_id'] = client_widget.client.def_user_id if values.dig('user_id').to_i.positive? && values['user_id'].to_i == self.id
      end

      client_widget.save
    end
  end

  def after_update_commit_actions
    super

    Integration::Vitally::V2024::Base.new.user_push(self.id) if self.client.ok_to_push_to_vitally?
  end

  def apply_defaults
    self.agency_user_tokens ||= []
    self.agent                                ||= false
    self.default_stage_parent_id              ||= 0
    self.incoming_call_popup                    = self.incoming_call_popup.nil? ? true : self.incoming_call_popup
    self.my_agent_token                       ||= ''
    self.phone_in                               = (self.phone_in.presence || self.phone)
    self.phone_in_with_action                   = self.phone_in_with_action.nil? ? true : self.phone_in_with_action
    self.phone_out                              = (self.phone_out.presence || self.phone)
    self.ring_duration                        ||= 20
    self.submit_text_on_enter                   = false
    self.super_admin                          ||= false
    self.team_member                          ||= false
    self.notifications                        ||= { review: {}, task: {}, text: {} }
    self.notifications[:review]               ||= {}
    self.notifications[:review][:by_push]       = self.notifications.dig('review', 'by_push').nil? ? true : self.notifications['review']['by_push'].to_bool
    self.notifications[:review][:by_text]       = self.notifications.dig('review', 'by_text').nil? ? true : self.notifications['review']['by_text'].to_bool
    self.notifications[:review][:matched]       = self.notifications.dig('review', 'matched').nil? ? true : self.notifications['review']['matched'].to_bool
    self.notifications[:review][:unmatched]     = self.notifications.dig('review', 'unmatched').nil? ? true : self.notifications['review']['unmatched'].to_bool
    self.notifications[:task]                 ||= {}
    self.notifications[:task][:by_push]         = self.notifications.dig('task', 'by_push').nil? ? true : self.notifications['task']['by_push'].to_bool
    self.notifications[:task][:by_text]         = self.notifications.dig('task', 'by_text').nil? ? true : self.notifications['task']['by_text'].to_bool
    self.notifications[:task][:created]         = self.notifications.dig('task', 'created').nil? ? true : self.notifications['task']['created'].to_bool
    self.notifications[:task][:updated]         = self.notifications.dig('task', 'updated').nil? ? true : self.notifications['task']['updated'].to_bool
    self.notifications[:task][:due]             = self.notifications.dig('task', 'due').nil? ? true : self.notifications['task']['due'].to_bool
    self.notifications[:task][:deadline]        = self.notifications.dig('task', 'deadline').nil? ? true : self.notifications['task']['deadline'].to_bool
    self.notifications[:task][:completed]       = self.notifications.dig('task', 'completed').nil? ? true : self.notifications['task']['completed'].to_bool
    self.notifications[:text]                 ||= {}
    self.notifications[:text][:arrive]          = if self.notifications.dig('text', 'arrive').present?
                                                    self.notifications['text']['arrive']
                                                  else
                                                    self.new_record? ? [] : [self.id]
                                                  end
    self.notifications[:text][:on_contact]      = self.notifications.dig('text', 'on_contact').nil? ? false : self.notifications['text']['on_contact'].to_bool
    self.trainings_editable                   ||= []
    self.version_notification                   = self.version_notification.nil? ? true : self.version_notification

    # Permissions
    self.campaigns_controller                 ||= []
    self.central_controller                   ||= []
    self.clients_controller                   ||= []
    self.companies_controller                 ||= []
    self.dashboard_controller                 ||= []
    self.email_templates_controller           ||= []
    self.import_contacts_controller           ||= []
    self.integrations_controller              ||= []
    self.integrations_servicetitan_controller ||= []
    self.my_contacts_controller               ||= []
    self.stages_controller                    ||= []
    self.surveys_controller                   ||= []
    self.trackable_links_controller           ||= []
    self.trainings_controller                 ||= []
    self.user_contact_forms_controller        ||= []
    self.users_controller                     ||= []
    self.widgets_controller                   ||= []

    return unless self.new_record?

    user_setting = self.user_settings.new(
      controller_action: 'dashboard_buttons',
      name:              'My Dashboard',
      current:           1,
      data:              {
        dynamic: 'l30',
        from:    '',
        to:      ''
      }
    )
    user_setting.data[:dashboard_buttons] = user_setting.dashboard_buttons_default
  end

  def before_create_actions
    self.permissions = {
      aiagents_controller:                  [],
      users_controller:                     %w[allowed profile tasks phone_processing notifications],
      stages_controller:                    [],
      central_controller:                   [],
      clients_controller:                   [],
      surveys_controller:                   [],
      widgets_controller:                   [],
      campaigns_controller:                 [],
      companies_controller:                 [],
      dashboard_controller:                 %w[allowed calendar tasks],
      trainings_controller:                 [],
      my_contacts_controller:               [],
      integrations_controller:              [],
      email_templates_controller:           [],
      import_contacts_controller:           [],
      trackable_links_controller:           [],
      user_contact_forms_controller:        [],
      integrations_servicetitan_controller: []
    }
    self.permissions['central_controller'] << 'allowed' if self.client.message_central_allowed
    self.permissions['my_contacts_controller'] << 'allowed' if self.client.my_contacts_allowed
    self.permissions['trainings_controller'] << 'allowed' if self.client.training.present?

    return if self.client.users.where.not(id: [nil, self.id]).present?

    self.permissions['aiagents_controller']           << 'allowed' unless self.client.aiagent_included_count.zero?
    self.permissions['campaigns_controller']          << 'allowed' if self.client.campaigns_count.positive?
    self.permissions['central_controller']            << 'all_contacts' if self.client.message_central_allowed
    self.permissions['clients_controller']             = %w[allowed billing org_chart lead_sources phone_numbers profile users statements tags terms]
    self.permissions['clients_controller']            << 'custom_fields' if self.client.custom_fields_count.positive?
    self.permissions['clients_controller']            << 'dlc10'
    self.permissions['clients_controller']            << 'groups' if self.client.groups_count.positive?
    self.permissions['clients_controller']            << 'holidays'
    self.permissions['clients_controller']            << 'kpis' if self.client.max_kpis_count.positive?
    self.permissions['clients_controller']            << 'folder_assignments' if self.client.folders_count.positive?
    self.permissions['clients_controller']            << 'stages' if self.client.stages_count.positive?
    self.permissions['clients_controller']            << 'task_actions' if self.client.tasks_allowed
    self.permissions['clients_controller']            << 'voice_recordings' if self.client.max_voice_recordings.positive?
    self.permissions['dashboard_controller']          << 'company_tiles'
    self.permissions['dashboard_controller']          << 'all_contacts'
    self.permissions['email_templates_controller']    << 'allowed' if self.client.max_email_templates.positive?
    self.permissions['import_contacts_controller']    << 'allowed' if self.client.import_contacts_count.positive?
    self.permissions['integrations_controller']       << 'client' if self.client.integrations_allowed.present?
    self.permissions['integrations_controller']       << 'user' if self.client.integrations_allowed.present?
    self.permissions['integrations_controller']       << 'google_reviews' if self.client.integrations_allowed.include?('google')
    self.permissions['integrations_controller']       << 'google_review_replies' if self.client.integrations_allowed.include?('google')
    self.permissions['my_contacts_controller']        << 'allowed' if self.client.my_contacts_allowed
    self.permissions['stages_controller']             << 'allowed' if self.client.stages_count.positive?
    self.permissions['surveys_controller']            << 'allowed' if self.client.surveys_count.positive?
    self.permissions['trackable_links_controller']    << 'allowed' if self.client.trackable_links_count.positive?
    self.permissions['user_contact_forms_controller'] << 'allowed' if self.client.quick_leads_count.positive?
    self.permissions['users_controller']              << 'admin_settings'
    self.permissions['users_controller']              << 'permissions'
    self.permissions['widgets_controller']            << 'allowed' if self.client.widgets_count.positive?
  end

  def before_destroy_actions
    # if the User is the default User for the Client find a different User to set as default
    self.client.update_def_user_id [self.id] if self.client&.def_user_id == self.id

    # update all Contacts to the default User
    # rubocop:disable Rails/SkipsModelValidations
    Contact.where(user_id: self.id).update_all(user_id: self.client.def_user_id) if self.client&.def_user_id
    # rubocop:enable Rails/SkipsModelValidations

    # Find any Google integrations for this User and change them to the default User
    google_cai = ClientApiIntegration.find_by(client_id: self.client_id, target: 'google', name: '')
    google_cai&.update(user_id: self.client.reload.def_user_id)
  end

  def after_validation_actions
    self.email                 = EmailAddress.valid?(self.email) ? EmailAddress.normal(self.email) : ''
    self.phone                 = self.phone.present? ? self.phone.to_s.clean_phone(self.client.primary_area_code) : ''
    self.phone_in              = self.phone_in.present? ? self.phone_in.to_s.clean_phone(self.client.primary_area_code) : self.phone
    self.phone_out             = self.phone_out.present? ? self.phone_out.to_s.clean_phone(self.client.primary_area_code) : self.phone
  end

  def count_is_approved
    errors.add(:base, "Maximum Users for #{self.client&.name} has been met.") if self.client&.users&.count.to_i >= self.client&.max_users_count.to_i
  end
end
