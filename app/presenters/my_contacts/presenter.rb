# frozen_string_literal: true

# app/presenters/my_contacts/presenter.rb
module MyContacts
  # variables required by My Contacts views
  class Presenter < BasePresenter
    attr_accessor :broadcast, :contact
    attr_reader :client, :page_number, :user, :user_setting

    def initialize(args = {})
      super
      self.user_setting = args.dig(:user_setting)

      @user          = @user_setting.user || User.new
      @client        = @user&.client || Client.new
      @broadcast     = false
      @contacts      = nil
      @group_actions = nil
      @page_number   = 1
    end

    def action_options
      [
        ['Send a Text Message', 'send_text'],
        @client.send_emails? && @client.email_templates.any? ? ['Send an Email Message', 'send_email'] : '',
        @client.campaigns_count.positive? ? ['Start a Campaign', 'start_campaign'] : '',
        @client.stages_count.positive? ? ['Add to a Stage', 'add_stage'] : '',
        @client.groups_count.positive? ? ['Add To a Group', 'add_group'] : '',
        ['Apply a Tag', 'add_tag'],
        ['Assign a Lead Source', 'assign_lead_source'],
        @client.max_voice_recordings.positive? ? ['Send a Ringless VM', 'send_rvm'] : '',
        ['Assign to a User', 'assign_user'],
        @client.campaigns_count.positive? ? ['Stop a Campaign', 'stop_campaign'] : '',
        @client.stages_count.positive? ? ['Remove from a Stage', 'remove_stage'] : '',
        @client.groups_count.positive? ? ['Remove From a Group', 'remove_group'] : '',
        ['Remove a Tag', 'remove_tag'],
        ['Set OK to Text ON', 'ok2text_on'],
        ['Set OK to Text OFF', 'ok2text_off'],
        ['Set to Sleep', 'contact_sleep'],
        ['Set to Awake', 'contact_awake'],
        %w[Delete contact_delete],
        ['Export Contacts', 'export_csv']
      ].compact_blank
    end

    def all_contacts_allowed
      @user.access_controller?(self.controller_name, 'all_contacts')
    end

    def collapsed
      self.collapsed_contacts && self.collapsed_tags && self.collapsed_campaigns && self.collapsed_groups && self.collapsed_texts && self.collapsed_trackable_links && self.collapsed_custom_fields
    end

    def collapsed_campaigns
      @user_setting.data.dig(:campaign_id).to_i.zero? && @user_setting.data.dig(:campaign_id_created_at_dynamic).to_s.empty? && @user_setting.data.dig(:campaign_id_created_at_from).to_s.empty? && @user_setting.data.dig(:campaign_id_created_at_to).to_s.empty?
    end

    def collapsed_contacts
      @user_setting.data.dig(:sleep).to_s == 'all' && @user_setting.data.dig(:block).to_s == 'all' && @user_setting.data.dig(:ok2text).to_i == 2 && @user_setting.data.dig(:ok2email).to_i == 2 &&
        @user_setting.data.dig(:created_at_from).to_s.empty? && @user_setting.data.dig(:created_at_to).to_s.empty? && @user_setting.data.dig(:created_at_dynamic).to_s.empty? &&
        @user_setting.data.dig(:updated_at_from).to_s.empty? && @user_setting.data.dig(:updated_at_to).to_s.empty? && @user_setting.data.dig(:updated_at_dynamic).to_s.empty? &&
        @user_setting.data.dig(:since_last_contact).to_i.zero? && @user_setting.data.dig(:has_number).to_s.empty? && @user_setting.data.dig(:not_has_number).to_s.empty?
    end

    def collapsed_custom_fields
      (@user_setting.data.dig(:custom_fields) || {}).empty?
    end

    def collapsed_groups
      @user_setting.data.dig(:group_id).to_i.zero? && @user_setting.data.dig(:group_id_updated_from).to_s.empty? && @user_setting.data.dig(:group_id_updated_to).to_s.empty? && @user_setting.data.dig(:group_id_updated_dynamic).to_s.empty?
    end

    def collapsed_lead_sources
      @user_setting.data.dig(:lead_source_id).to_i.zero? && @user_setting.data.dig(:lead_source_id_updated_from).to_s.empty? && @user_setting.data.dig(:lead_source_id_updated_to).to_s.empty? && @user_setting.data.dig(:lead_source_id_updated_dynamic).to_s.empty?
    end

    def collapsed_stages
      @user_setting.data.dig(:stage_id).to_i.zero? && @user_setting.data.dig(:stage_id_updated_from).to_s.empty? && @user_setting.data.dig(:stage_id_updated_to).to_s.empty? && @user_setting.data.dig(:stage_id_updated_dynamic).to_s.empty?
    end

    def collapsed_tags
      (@user_setting.data.dig(:tags_exclude) || []).empty? && (@user_setting.data.dig(:tags_include) || []).empty? && @user_setting.data.dig(:all_tags).to_i == 1 &&
        @user_setting.data.dig(:contacttag_created_at_from).to_s.empty? && @user_setting.data.dig(:contacttag_created_at_to).to_s.empty? && @user_setting.data.dig(:contacttag_created_at_dynamic).to_s.empty?
    end

    def collapsed_texts
      @user_setting.data.dig(:last_msg_string).to_s.empty? && @user_setting.data.dig(:last_msg_from).to_s.empty? && @user_setting.data.dig(:last_msg_to).to_s.empty? && @user_setting.data.dig(:last_msg_dynamic).to_s.empty? && @user_setting.data.dig(:last_msg_direction) == 'both' && @user_setting.data.dig(:last_msg_absolute) == 'last'
    end

    def collapsed_trackable_links
      @user_setting.data.dig(:trackable_link_id).to_i.zero? && !@user_setting.data.dig(:trackable_link_clicked).to_bool && @user_setting.data.dig(:trackable_link_id_created_at_dynamic).to_s.empty? && @user_setting.data.dig(:trackable_link_id_created_at_from).to_s.empty? && @user_setting.data.dig(:trackable_link_id_created_at_to).to_s.empty?
    end

    def controller_name
      'my_contacts'
    end

    def contacts
      @contacts ||= Contact.custom_search_query(
        user:                 @user,
        my_contacts_settings: @user_setting,
        broadcast:            @broadcast.to_bool,
        page_number:          [@page_number.to_i, 1].max,
        order:                true
      ).includes(:client, :corp_client)
    end

    def export_options(client)
      standard = Webhook.internal_key_hash(client, 'contact', %w[personal]).transform_keys { |k| "standard|#{k}" }
      standard['standard|last_contacted'] = 'Last contacted'
      phones = Webhook.internal_key_hash(client, 'contact', %w[phones]).transform_keys { |k| "phones|#{k}" }
      custom = Webhook.internal_key_hash(client, 'contact', %w[custom_fields]).transform_keys { |k| "custom_fields|#{k}" }
      integrations = (client.integrations_allowed & Contacts::ExtReference.targets).to_h { |integration| ["integration|#{integration}", "#{ClientApiIntegration.integrations_array.to_h.invert[integration] || integration.titleize} Reference ID"] }

      standard.merge(phones).merge(custom).merge(integrations)
    end

    def group_actions
      @group_actions ||= DelayedJob.scheduled_actions(@user.id, Time.current.beginning_of_month, Time.current.end_of_month + 12.months)
    end

    def new_sort_dir
      if @user_setting.data.dig(:sort, :dir).to_s == 'asc'
        'desc'
      elsif @user_setting.data.dig(:sort, :dir).to_s == 'desc'
        ''
      else
        'asc'
      end
    end

    def operator_options_numeric
      [['Equal To', '='], ['Less Than', '<'], ['Greater Than', '>'], ['Less Than or Equal', '<='], ['Greater Than or Equal', '>=']]
    end

    def operator_options_string
      self.operator_options_numeric + [%w[Like ILIKE]]
    end

    def page_number=(page_number)
      @page_number = [page_number, 1].max
    end

    def sort_tooltip
      self.new_sort_dir.present? ? "Sort #{self.new_sort_dir.capitalize}" : 'Clear Sort'
    end

    def text_icon_color
      @contact&.ok2text.to_i == 1 ? 'text-success' : 'text-danger'
    end

    def text_tooltip
      @contact&.ok2text.to_i == 1 ? 'OK to Text' : 'NOT OK to Text'
    end

    def user_setting=(user_setting)
      @user_setting = case user_setting
                      when Users::Setting
                        user_setting
                      when Integer
                        Users::Setting.find_by(id: user_setting)
                      else

                        if @user.is_a?(User)
                          @user.user_settings.find_or_initialize_by(controller_action: 'contacts_search', name: 'Last Used')
                        else
                          Users::Setting.new
                        end
                      end
    end

    def user_setting_contacttag_created_at_string
      @user_setting.data.dig(:contacttag_created_at_from).to_s.present? && @user_setting.data.dig(:contacttag_created_at_to).to_s.present? ? "#{@user_setting.data.dig(:contacttag_created_at_from)} to #{@user_setting.data.dig(:contacttag_created_at_to)}" : "#{@user_setting.data.dig(:contacttag_created_at_from)}#{@user_setting.data.dig(:contacttag_created_at_to)}"
    end

    def user_setting_created_at_string
      @user_setting.data.dig(:created_at_from).to_s.present? && @user_setting.data.dig(:created_at_to).to_s.present? ? "#{@user_setting.data.dig(:created_at_from)} to #{@user_setting.data.dig(:created_at_to)}" : "#{@user_setting.data.dig(:created_at_from)}#{@user_setting.data.dig(:created_at_to)}"
    end

    def user_setting_custom_fields_updated_at_string
      @user_setting.data.dig(:custom_fields_updated_at_from).to_s.present? && @user_setting.data.dig(:custom_fields_updated_at_to).to_s.present? ? "#{@user_setting.data.dig(:custom_fields_updated_at_from)} to #{@user_setting.data.dig(:custom_fields_updated_at_to)}" : "#{@user_setting.data.dig(:custom_fields_updated_at_from)}#{@user_setting.data.dig(:custom_fields_updated_at_to)}"
    end

    def user_setting_group_id_updated_string
      @user_setting.data.dig(:group_id_updated_from).to_s.present? && @user_setting.data.dig(:group_id_updated_to).to_s.present? ? "#{@user_setting.data.dig(:group_id_updated_from)} to #{@user_setting.data.dig(:group_id_updated_to)}" : "#{@user_setting.data.dig(:group_id_updated_from)}#{@user_setting.data.dig(:group_id_updated_to)}"
    end

    def user_setting_last_msg_to_from_string
      @user_setting.data.dig(:last_msg_from).to_s.present? && @user_setting.data.dig(:last_msg_to).to_s.present? ? "#{@user_setting.data.dig(:last_msg_from)} to #{@user_setting.data.dig(:last_msg_to)}" : "#{@user_setting.data.dig(:last_msg_from)}#{@user_setting.data.dig(:last_msg_to)}"
    end

    def user_setting_lead_source_id_updated_string
      @user_setting.data.dig(:lead_source_id_updated_from).to_s.present? && @user_setting.data.dig(:lead_source_id_updated_to).to_s.present? ? "#{@user_setting.data.dig(:lead_source_id_updated_from)} to #{@user_setting.data.dig(:lead_source_id_updated_to)}" : "#{@user_setting.data.dig(:lead_source_id_updated_from)}#{@user_setting.data.dig(:lead_source_id_updated_to)}"
    end

    def user_setting_stage_id_updated_string
      @user_setting.data.dig(:stage_id_updated_from).to_s.present? && @user_setting.data.dig(:stage_id_updated_to).to_s.present? ? "#{@user_setting.data.dig(:stage_id_updated_from)} to #{@user_setting.data.dig(:stage_id_updated_to)}" : "#{@user_setting.data.dig(:stage_id_updated_from)}#{@user_setting.data.dig(:stage_id_updated_to)}"
    end

    def user_setting_trackable_link_id_created_at_string
      @user_setting.data.dig(:trackable_link_id_created_at_from).to_s.present? && @user_setting.data.dig(:trackable_link_id_created_at_to).to_s.present? ? "#{@user_setting.data.dig(:trackable_link_id_created_at_from)} to #{@user_setting.data.dig(:trackable_link_id_created_at_to)}" : "#{@user_setting.data.dig(:trackable_link_id_created_at_from)}#{@user_setting.data.dig(:trackable_link_id_created_at_to)}"
    end

    def user_setting_updated_at_string
      @user_setting.data.dig(:updated_at_from).to_s.present? && @user_setting.data.dig(:updated_at_to).to_s.present? ? "#{@user_setting.data.dig(:updated_at_from)} to #{@user_setting.data.dig(:updated_at_to)}" : "#{@user_setting.data.dig(:updated_at_from)}#{@user_setting.data.dig(:updated_at_to)}"
    end
  end
end
