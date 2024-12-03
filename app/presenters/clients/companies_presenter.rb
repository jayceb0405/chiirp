# frozen_string_literal: true

# app/presenters/clients/companies_presenter.rb
module Clients
  class CompaniesPresenter
    attr_reader :client, :list_type, :user

    def initialize(user_settings)
      @user_settings = case user_settings
                       when Users::Setting
                         user_settings
                       when Integer
                         Users::Setting.find_by(id: user_settings)
                       else
                         Users::Setting.new
                       end

      @user                      = @user_settings&.user || User.new
      @client                    = @user&.client || Client.new
      @active_clients            = nil
      @agency_user_messages      = nil
      @agency_user_rvms          = nil
      @agency_user_text_messages = nil
      @list_type                 = 'clients'
      @list_type_list            = nil
      @paid_clients              = nil
      @users_by_client           = nil
    end

    def active_clients
      @active_clients ||= Client.where(tenant: I18n.t('tenant.id')).where('data @> ?', { active: true }.to_json)
    end

    def active_only
      @user_settings.data[:active_only]
    end

    def activity_list
      clients = if @user.team_member?
                  Client.with_users.order(:name)
                elsif @user.agent?
                  Client.by_agency(@client.id).with_users.order(:name)
                else
                  Client.none
                end

      clients_by_report_criteria(clients)
    end

    def agency_client_rvms_sum(client_id)
      self.agency_user_rvms&.map { |k, v| v if k[0] == client_id }&.compact_blank&.sum || 0
    end

    def agency_client_text_messages_sum(client_id)
      self.agency_user_text_messages&.map { |k, v| v if k[0] == client_id }&.compact_blank&.sum || 0
    end

    def agency_client_user_rvms_sum(client_id, user_id)
      self.agency_user_rvms&.map { |k, v| v if k[0] == client_id && k[1] == user_id }&.compact_blank&.sum || 0
    end

    def agency_client_user_text_messages_sum(client_id, user_id)
      self.agency_user_text_messages&.map { |k, v| v if k[0] == client_id && k[1] == user_id }&.compact_blank&.sum || 0
    end

    def agency_clients
      self.active_clients.where('data @> ?', { agency_access: true }.to_json)
    end

    def agency_user_messages
      return @agency_user_messages if @agency_user_messages.present?

      client_ids = if @user.team_member?
                     Client.with_users.pluck(:id)
                   elsif @user.agent?
                     Client.by_agency(@client.id).with_users.pluck(:id) << @client.id
                   else
                     []
                   end

      @agency_user_messages      = Messages::Message.joins(:contact).where(contacts: { client_id: client_ids }).where(messages: { created_at: [self.search_period_start..self.search_period_end] }).select(:user_id, :msg_type, 'contacts.client_id')
      @agency_user_text_messages = nil
      @agency_user_rvms          = nil
    end

    def agency_user_rvms
      @agency_user_rvms ||= self.agency_user_messages&.where(messages: { msg_type: 'rvmout' })&.group(:client_id, :user_id)&.count(:messages) || nil
    end

    def agency_user_text_messages
      @agency_user_text_messages ||= self.agency_user_messages&.where(messages: { msg_type: 'textout' })&.group(:client_id, :user_id)&.count(:messages) || nil
    end

    def agency_users
      self.client.users
    end

    def client_link_classes(client)
      if client.mo_charge_retry_count > 3
        link_class    = ' text-danger'
        icon_class    = ' text-danger animated infinite heartBeat'
        alert_message = '(unpaid monthly charges)'
      elsif client.credits_in_danger?
        link_class    = ' text-danger'
        icon_class    = ' text-danger animated infinite heartBeat'
        alert_message = '(credits in danger)'
      elsif !client.credit_card_on_file? && !client.unlimited
        link_class    = ' text-danger'
        icon_class    = ' text-danger animated infinite heartBeat'
        alert_message = '(no credit card)'
      else
        link_class    = ''
        icon_class    = ' text-dark'
        alert_message = ''
      end

      [link_class, icon_class, alert_message]
    end

    def clients_list
      clients = if @user.team_member?
                  Client.with_users.order(:name)
                elsif @user.agent?
                  Client.by_agency(@client.id).with_users.order(:name)
                else
                  Client.none
                end

      clients = clients.where(created_at: self.search_period_start..self.search_period_end) if self.search_period.present?
      clients_by_report_criteria(clients)
    end

    def company_cell(client, valign = 'middle')
      _link_class, _icon_class, alert_message = client_link_classes(client)

      client_avatar = if client.logo_image.present?
                        ActionController::Base.helpers.image_tag(Cloudinary::Utils.cloudinary_url(client.logo_image.key, { secure_distribution: I18n.t("tenant.#{Rails.env}.cloudinary_cname"), format: 'png' }), class: 'img-responsive', style: 'max-width:36px;')
                      else
                        ActionController::Base.helpers.image_tag("tenant/#{I18n.t('tenant.id')}/logo-600.png", class: 'img-responsive', style: 'max-width:40px;')
                      end

      ActionController::Base.helpers.tag.td(colspan: 3, class: "align-#{valign} text-left", style: 'min-width:240px') do
        ActionController::Base.helpers.tag.div(class: 'container') do
          ActionController::Base.helpers.tag.dig(class: 'row') do
            ActionController::Base.helpers.tag.figure(class: 'col-2 user-avatar user-avatar-md my-auto') do
              client_avatar
            end +
              # rubocop:disable Rails/OutputSafety
              ActionController::Base.helpers.tag.div(class: 'col-10 my-auto') do
                client.name.html_safe +
                  ActionController::Base.helpers.tag.p(class: 'list-group-item-text') { alert_message.to_s unless alert_message.empty? }.html_safe
              end
            # rubocop:enable Rails/OutputSafety
          end
        end
      end
    end

    def clients_by_report_criteria(clients)
      clients = clients.active if self.active_only
      clients = clients.search_by_name(self.search_text) if self.search_text.present?
      clients = clients.in_danger if self.in_danger
      clients = clients.delinquent if self.delinquent_only
      clients = clients.paying if self.paying_only

      clients.page(self.page).per(self.per_page)
    end

    def company_users(client)
      client.users
    end

    def delinquent_clients
      self.paid_clients.where("(clients.data ->> 'mo_charge_retry_count')::numeric > ?", 0)
    end

    def delinquent_only
      @user_settings.data[:delinquent_only]
    end

    def fail_html
      '<i class="text-danger fa fa-times"></i>'.html_safe
    end

    def free_clients
      self.active_clients.where("(clients.data ->> 'mo_charge')::numeric = ?", 0.0).where("(clients.data ->> 'promo_mo_charge')::numeric = ?", 0.0)
    end

    def heading_icon
      case @list_type
      when 'activity'
        'fa fa-person-running'
      when 'clients'
        'fa fa-city'
      when 'statistics'
        'fa fa-clipboard-list'
      when 'contacts'
        'fa fa-users'
      when 'texting'
        'fa fa-comments'
      when 'voice'
        'fa fa-phone'
      when 'automation'
        'fa fa-wrench'
      else
        ''
      end
    end

    def in_danger
      @user_settings.data[:in_danger]
    end

    def list_type=(list_type)
      @list_type_list = nil unless @list_type == list_type
      @list_type      = list_type
    end

    def list_type_list
      @list_type_list ||= case @list_type
                          when 'activity'
                            self.activity_list
                          when 'clients'
                            self.clients_list
                          when 'automation', 'contacts', 'statistics', 'voice'
                            self.statistics_list
                          when 'texting'
                            self.texting_list
                          else
                            []
                          end
    end

    def page
      [@user_settings.data[:page] || 1, 1].max
    end

    def paid_clients
      @paid_clients ||= @active_clients.where("(clients.data ->> 'mo_charge')::numeric > ?", 0.0).or(@active_clients.where("(clients.data ->> 'promo_mo_charge')::numeric > ?", 0.0))
    end

    def paying_only
      @user_settings.data[:paying_only]
    end

    def per_page
      [@user_settings.data[:per_page] || 25, 10].max
    end

    def search_period
      @user_settings.data.dig(:search_period)
    end

    def search_period_end
      Time.use_zone('UTC') { Chronic.parse(self.search_period.split(' to ').last) }&.end_of_day || Time.now.utc.end_of_month
    end

    def search_period_start
      Time.use_zone('UTC') { Chronic.parse(self.search_period.split(' to ').first) }&.beginning_of_day || Time.now.utc.beginning_of_month
    end

    def search_text
      @user_settings.data[:search_text]
    end

    def statistics_list
      clients = if @user.team_member?
                  Client.with_phone_numbers.order(:name)
                elsif self.user.agent?
                  Client.by_agency(@client.id).with_phone_numbers.order(:name)
                else
                  Client.none
                end

      clients = clients.where(created_at: self.search_period_start..self.search_period_end) if self.search_period.present?
      clients_by_report_criteria(clients)
    end

    def success_html
      '<i class="text-success fa fa-check"></i>'.html_safe
    end

    def texting_list
      clients = if @user.team_member?
                  Client.with_messages.order(:name)
                elsif self.user.agent?
                  Client.by_agency(@client.id).with_messages.order(:name)
                else
                  Client.none
                end

      clients = clients.where(created_at: self.search_period_start..self.search_period_end) if self.search_period.present?
      clients_by_report_criteria(clients)
    end

    def unlimited_clients
      self.active_clients.where('data @> ?', { unlimited: true }.to_json)
    end
  end
end
