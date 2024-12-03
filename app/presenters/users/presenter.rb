# frozen_string_literal: true

# app/presenters/users/presenter.rb
module Users
  # variables required for User views
  class Presenter < BasePresenter
    def initialize(args = {})
      super
      # self.user    = args.dig(:user)
      # self.client  = args.dig(:client) || self.user.client

      @user_tasks                      = nil
      @stage_parents                   = nil
      @desktop_push_notification_count = nil
      @mobile_push_notification_count  = nil
    end

    def aiagents_controller_array
      [['Access AI Agents', 'allowed']]
    end

    def campaigns_controller_array
      [['Access Campaign Builder', 'allowed']]
    end

    def central_controller_array
      [['Access Message Central', 'allowed'], ['Access All Contacts', 'all_contacts'], ['Manage Quick Responses', 'manage_quick_responses']]
    end

    def check_boxes_campaign_failures_notifications
      checkboxes = []
      checkboxes << { field: 'user[notifications][campaigns][by_text]', label: 'Notify Me by Text Message', id: 'checkbox_campaigns_notify_by_text', value: self.user.notifications.dig('campaigns', 'by_text').to_bool, values: [true, false] }
      checkboxes << { field: 'user[notifications][campaigns][by_push]', label: 'Notify Me by Push Notification', id: 'checkbox_campaigns_notify_by_push', value: self.user.notifications.dig('campaigns', 'by_push').to_bool, values: [true, false] }
    end

    def check_boxes_review_notification_methods
      checkboxes = []
      checkboxes << { field: 'user[notifications][review][by_text]', label: 'Notify Me by Text Message', id: 'checkbox_review_notify_by_text', value: self.user.notifications.dig('review', 'by_text').to_bool, values: [true, false] }
      checkboxes << { field: 'user[notifications][review][by_push]', label: 'Notify Me by Push Notification', id: 'checkbox_review_notify_by_push', value: self.user.notifications.dig('review', 'by_push').to_bool, values: [true, false] }
    end

    def check_boxes_review_notifications
      checkboxes = []
      checkboxes << { field: 'user[notifications][review][matched]', label: 'Notify Me when a review is received that is matched to a Contact', id: 'checkbox_review_notify_matched', value: self.user.notifications.dig('review', 'matched').to_bool, values: [true, false] }
      checkboxes << { field: 'user[notifications][review][unmatched]', label: 'Notify Me when a review is received that is NOT matched to a Contact', id: 'checkbox_review_notify_unmatched', value: self.user.notifications.dig('review', 'unmatched').to_bool, values: [true, false] }
    end

    def check_boxes_task_notification_methods
      checkboxes = []
      checkboxes << { field: 'user[notifications][task][by_text]', label: 'Notify Me by Text Message', id: 'checkbox_task_notify_by_text', value: self.user.notifications.dig('task', 'by_text').to_bool, values: [true, false] }
      checkboxes << { field: 'user[notifications][task][by_push]', label: 'Notify Me by Push Notification', id: 'checkbox_task_notify_by_push', value: self.user.notifications.dig('task', 'by_push').to_bool, values: [true, false] }
    end

    def check_boxes_task_notifications
      checkboxes = []
      checkboxes << { field: 'user[notifications][task][created]', label: 'Notify Me When New Tasks are Created', id: 'checkbox_task_notify_created', value: self.user.notifications.dig('task', 'created').to_bool, values: [true, false] }
      checkboxes << { field: 'user[notifications][task][updated]', label: 'Notify Me When New Tasks are Updated', id: 'checkbox_task_notify_updated', value: self.user.notifications.dig('task', 'updated').to_bool, values: [true, false] }
      checkboxes << { field: 'user[notifications][task][due]', label: 'Notify Me When Tasks Past Due', id: 'checkbox_task_notify_due', value: self.user.notifications.dig('task', 'due').to_bool, values: [true, false] }
      checkboxes << { field: 'user[notifications][task][deadline]', label: 'Notify Me When Tasks Past Deadline', id: 'checkbox_task_notify_deadline', value: self.user.notifications.dig('task', 'deadline').to_bool, values: [true, false] }
      checkboxes << { field: 'user[notifications][task][completed]', label: 'Notify Me When Tasks Completed', id: 'checkbox_task_notify_completed', value: self.user.notifications.dig('task', 'completed').to_bool, values: [true, false] }
    end

    def client=(client)
      @client = if client.is_a?(Client)
                  client
                elsif client.is_a?(Integer)
                  Client.find_by(id: client)
                elsif self.user.is_a?(User)
                  self.user.client
                else
                  Client.new
                end
    end

    def clients_controller_array
      [['Access My Company Profile', 'allowed'], ['10DLC Brands & Campaigns', 'dlc10'], %w[Billing billing], ['Custom Fields', 'custom_fields'], %w[Groups groups], %w[Holidays holidays], %w[KPIs kpis], ['Lead Sources', 'lead_sources'], ['Message Folders', 'folder_assignments'], ['Org Chart', 'org_chart'], %w[Pipelines pipelines], ['Phone Numbers', 'phone_numbers'], %w[Profile profile], %w[Settings settings], %w[Statements statements], %w[Tags tags], ['Task Actions', 'task_actions'], %w[Terms terms], %w[Users users], ['Voice Recordings', 'voice_recordings']]
    end

    def companies_controller_array
      [['Access Companies', 'allowed']]
    end

    def dashboard_controller_array
      response = [['Access Dashboard', 'allowed'], ['View Calendar', 'calendar'], ['View Company Tiles', 'company_tiles'], ['Access All Contacts', 'all_contacts']]
      response << ['View Tasks', 'tasks'] if self.user.client.tasks_allowed

      response
    end

    def default_stage_parent_array
      [['Show List', 0]] + self.stage_parents.pluck(:name, :id)
    end

    def desktop_push_notification_count
      @desktop_push_notification_count || self.user.user_pushes.where(target: 'desktop').count
    end

    def email_templates_controller_array
      [['Access Email Templates', 'allowed']]
    end

    def import_contacts_controller_array
      [['Access Import Contacts', 'allowed']]
    end

    def integrations_controller_array
      [['Access Client Integrations', 'client'], ['Access User Integrations', 'user'], ['Access Google Messages', 'google_messages'], ['Access Google Reviews', 'google_reviews'], ['Access Google Review Replies', 'google_review_replies']]
      # [['Access Client Integrations', 'client'], ['Access User Integrations', 'user'], ['Access Google Reviews', 'google_reviews'], ['Access Google Review Replies', 'google_review_replies']]
    end

    def integrations_servicetitan_controller_array
      [['Access Contact Balances', 'contact_balances']]
    end

    def mobile_push_notification_count
      @mobile_push_notification_count || self.user.user_pushes.where(target: 'mobile').count
    end

    def my_contacts_controller_array
      [['Access My Contacts', 'allowed'], ['Access All Contacts', 'all_contacts'], ['Schedule Actions', 'schedule_actions']]
    end

    def options_for_agency_clients
      Client.by_agency(@client.id).map { |client| [client.name, client.id] }
    end

    def stage_parents
      @stage_parents || StageParent.for_user(self.user.id).sort_by(&:name)
    end

    def stages_controller_array
      [["Access My #{StageParent.title.pluralize}", 'allowed'], ['Access All Contacts', 'all_contacts']]
    end

    def surveys_controller_array
      [['Access Survey Builder', 'allowed']]
    end

    def trackable_links_controller_array
      [['Access Trackable Links', 'allowed']]
    end

    def trainings_controller_array
      [['Access Training', 'allowed']]
    end

    def user=(user)
      @user = case user
              when User
                user
              when Integer
                User.find_by(id: user)
              else
                User.new
              end

      @desktop_push_notification_count = nil
      @mobile_push_notification_count  = nil
    end

    def user_avatar
      if self.user.avatar.present?
        ActionController::Base.helpers.image_tag(Cloudinary::Utils.cloudinary_url(self.user.avatar.key, { secure_distribution: I18n.t("tenant.#{Rails.env}.cloudinary_cname"), format: 'png' }))
      else
        ActionController::Base.helpers.image_tag("tenant/#{I18n.t('tenant.id')}/logo-600.png")
      end
    end

    def user_contact_forms_controller_array
      [['Access QuickPages', 'allowed']]
    end

    def user_found_in_vitally
      Integration::Vitally::V2024::Base.new.user_found?(self.user.id)
    end

    def user_last_invited
      self.user.invitation_sent_at.nil? ? 'Never' : Friendly.new.date(self.user.invitation_sent_at, self.client.time_zone, true)
    end

    def user_last_logged_in
      self.user.last_sign_in_at.nil? ? 'Never' : Friendly.new.date(self.user.current_sign_in_at, self.client.time_zone, true)
    end

    def user_name
      self.user.fullname
    end

    def user_suspended_at_formatted
      self.user.suspended_at.present? ? self.user.suspended_at.in_time_zone(self.client.time_zone).strftime('%m/%d/%Y %I:%M %p') : ''
    end

    def user_tasks
      @user_tasks || Task.incomplete_by_user(self.user.id)
    end

    def users_controller_array
      [['Access My Profile', 'allowed'], %w[Profile profile], %w[Tasks tasks], ['Phone Processing', 'phone_processing'], %w[Notifications notifications], ['Admin Settings', 'admin_settings'], %w[Permissions permissions]]
    end

    def widgets_controller_array
      [['Access SiteChat', 'allowed']]
    end
  end
end
