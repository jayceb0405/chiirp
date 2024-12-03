# frozen_string_literal: true

# app/models/users/setting.rb
module Users
  # Clients::Widget data processing
  class Setting < ApplicationRecord
    self.table_name = 'user_settings'

    belongs_to :user

    serialize :data, coder: YAML, type: Hash

    after_initialize :apply_defaults, if: :new_record?
    before_save      :before_save_actions
    before_destroy   :before_destroy_actions

    # select all Users & Clients needed to generate a list of Contacts for
    # user_setting.contacts_list_clients_users(controller: String)
    #   (req) controller:    (String)
    #   (opt) client:        (Client / default: Users::Setting.user.client)
    #   (opt) user:          (User / default: Users::Setting.user)
    #   (opt) show_user_ids: (Array / default: Users::Setting.data.show_user_ids || [])
    def contacts_list_clients_users(**args)
      user          = args.dig(:user) || self.user
      client        = args.dig(:client) || user.client
      show_user_ids = args.dig(:show_user_ids) || data.dig(:show_user_ids) || []
      response      = { client_ids: [], user_ids: [] }

      return response unless args.dig(:controller).to_s.present? && user.is_a?(User) && client.is_a?(Client)

      if user.access_controller?(args[:controller].to_s, 'all_contacts')
        # User may access all Contacts

        if client.agency_access && user.agent?
          # User belongs to an Agency and is an Agent

          show_user_ids.each do |id|
            if id.to_s[0, 4] == 'all_' && (this_client = Client.find_by(id: id.to_s[4..])) && (this_client.my_agencies.include?(client.id) || this_client.id == client.id)
              # all Users for a specific Client
              response[:client_ids] << this_client.id
            elsif (id.to_i.positive? && (this_user = User.find_by(id:)) && this_user.client.my_agencies.include?(client.id)) ||
                  (id.to_i.positive? && client.users.pluck(:id).include?(id.to_i))
              # a specific User
              response[:user_ids] << id.to_i
            elsif id.to_i.zero?
              # all Users belonging to the User's Client
              response[:client_ids] += (Client.agency_accounts(client.id).pluck(:id) << client.id)
            else
              response[:user_ids] << user.id
            end
          end
        else
          client_user_ids = client.users.pluck(:id)

          show_user_ids.each do |id|
            if id.to_i.positive? && client_user_ids.include?(id.to_i)
              # User does not belong to an Agency or is not an Agent
              response[:user_ids] << id.to_i
            elsif id.to_i.zero?
              response[:client_ids] << client.id
            else
              response[:user_ids] << user.id
            end
          end
        end
      end

      response[:user_ids] = [user.id] if response[:user_ids].blank? && response[:client_ids].blank?

      response
    end

    # provide an array of default buttons displayed on Dashboard
    # user_settings.dashboard_buttons_default
    def dashboard_buttons_default
      response  = !user.new_record? && user.super_admin? ? %w[paying_clients client_value] : []
      response += %w[user_new_contacts user_texts_sent user_texts_received user_campaigns_completed client_campaigns_completed client_new_contacts client_texts_sent client_texts_received]

      response
    end

    # reset the current Users::Setting to default values
    #   (opt) session: (Hash / default: {})
    def reset_data_to_default(session = {})
      apply_defaults(session)
    end

    private

    def apply_defaults(session = {})
      case controller_action
      when 'chiirpapp_message_central'
        data[:include_automated]                      = false
        data[:show_user_id]                           = 0
      when 'clients_index'
        data[:active_only]                            = true
        data[:delinquent_only]                        = false
        data[:in_danger]                              = false
        data[:page]                                   = 1
        data[:paying_only]                            = false
        data[:per_page]                               = 25
        data[:search_period]                          = ''
        data[:search_text]                            = ''
      when 'contacts_import'
        data[:spreadsheet]                            = []
      when 'contacts_newui', 'contacts_search'
        data[:all_tags]                               = 1
        data[:block]                                  = 'all'
        data[:campaign_id]                            = 0
        data[:campaign_id_completed]                  = 'all'
        data[:campaign_id_created_at_dynamic]         = ''
        data[:campaign_id_created_at_from]            = ''
        data[:campaign_id_created_at_to]              = ''
        data[:contacttag_created_at_dynamic]          = ''
        data[:contacttag_created_at_from]             = ''
        data[:contacttag_created_at_to]               = ''
        data[:created_at_dynamic]                     = ''
        data[:created_at_from]                        = ''
        data[:created_at_to]                          = ''
        data[:custom_fields]                          = {}
        data[:custom_fields_updated_at_dynamic]       = ''
        data[:custom_fields_updated_at_from]          = ''
        data[:custom_fields_updated_at_to]            = ''
        data[:group_id]                               = ''
        data[:group_id_updated_dynamic]               = ''
        data[:group_id_updated_from]                  = ''
        data[:group_id_updated_to]                    = ''
        data[:has_number]                             = ''
        data[:last_msg_absolute]                      = 'last'
        data[:last_msg_direction]                     = 'both'
        data[:last_msg_dynamic]                       = ''
        data[:last_msg_from]                          = ''
        data[:last_msg_to]                            = ''
        data[:last_msg_string]                        = ''
        data[:lead_source_id]                         = ''
        data[:lead_source_id_updated_dynamic]         = ''
        data[:lead_source_id_updated_from]            = ''
        data[:lead_source_id_updated_to]              = ''
        data[:not_has_number]                         = ''
        data[:ok2email]                               = 2
        data[:ok2text]                                = 2
        data[:per_page]                               = 25
        data[:search_string]                          = ''
        data[:show_user_ids]                          = user.access_controller?('my_contacts', 'all_contacts', session) ? ["all_#{user.client_id}"] : [user.id]
        data[:since_last_contact]                     = 0
        data[:sleep]                                  = 'all'
        data[:sort]                                   = { col: 'created_at', dir: 'desc' }
        data[:stage_id]                               = ''
        data[:stage_id_updated_dynamic]               = ''
        data[:stage_id_updated_from]                  = ''
        data[:stage_id_updated_to]                    = ''
        data[:tags_include]                           = []
        data[:tags_exclude]                           = []
        data[:trackable_link_clicked]                 = false
        data[:trackable_link_id]                      = 0
        data[:trackable_link_id_created_at_dynamic]   = ''
        data[:trackable_link_id_created_at_from]      = ''
        data[:trackable_link_id_created_at_to]        = ''
        data[:updated_at_dynamic]                     = ''
        data[:updated_at_from]                        = ''
        data[:updated_at_to]                          = ''
      when 'dashboard_buttons'
        data[:from]                                   = data.dig(:from).to_s
        data[:to]                                     = data.dig(:to).to_s
        data[:dynamic]                                = data.dig(:dynamic).to_s
        data[:dynamic]                                = 'l30' if data[:dynamic].empty? && data[:from].empty? && data[:to].empty?
        data[:dashboard_buttons]                      = (data.dig(:dashboard_buttons) || %w[user_new_contacts user_texts_sent user_texts_received])
        data[:buttons_user_id]                        = (data.dig(:buttons_user_id) || user_id).to_i
      when 'dashboard_cal_tasks'
        data[:cal_default_view]                       = (data.dig(:cal_default_view) || 'timeGridDay').to_s
        data[:all_tasks]                              = (data.dig(:all_tasks) || 0).to_i
        data[:my_tasks]                               = (data.dig(:my_tasks) || 0).to_i
        data[:task_list]                              = data.dig(:task_list) || {}
        data[:task_list][:page]                       = (data.dig(:task_list, :page) || 1).to_i
        data[:task_list][:per_page]                   = (data.dig(:task_list, :per_page) || 10).to_i
        data[:task_list][:sort]                       = data.dig(:task_list, :sort) || {}
        data[:task_list][:sort][:col]                 = (data.dig(:task_list, :sort, :col) || 'due_date').to_s
        data[:task_list][:sort][:dir]                 = (data.dig(:task_list, :sort, :dir) || 'desc').to_s
      when 'dashboard_newui'
        data[:timeframe]                              = 30
        data[:user_ids]                               = [user.id]
        data[:automations]                            = { order_column: 'last_started', order_direction: 'asc', page: 1, page_size: 15 }
      when 'message_central'
        data[:active_contacts_group_id] = 0
        data[:active_contacts_paused]                 = false
        data[:active_contacts_period]                 = 90
        data[:include_automated]                      = false
        data[:include_sleeping]                       = false
        data[:msg_types]                              = %w[email fb ggl rvm text video voice widget]
        data[:page]                                   = 1
        data[:per_page]                               = 25
        data[:phone_number]                           = user.default_from_twnumber&.phonenumber.to_s
        data[:show_user_ids]                          = [user.id]
      when 'stages_index'
        data[:user_ids]                               = [user.id]
      when 'tasks_index'
        data[:tasks_filter]                           = { selected: 0, user: user.id }
        data[:tasks_sort]                             = { col: 'name', dir: 'asc' }
        data[:pagination]                             = { page: 1, per_page: 10 }
      end
    end

    def before_destroy_actions
      return unless current == 1 && (user_settings = user.user_settings.where.not(id: id).find_by(controller_action: controller_action))

      user_settings.update(current: 1)
    end

    def before_save_actions
      data[:buttons_user_id] = user_id if controller_action == 'dashboard_buttons' && data.dig(:buttons_user_id).to_i.zero?
      user.user_settings.where(controller_action: controller_action).where.not(id: id).update(current: 0) if current == 1 && changed?
    end
  end
end
