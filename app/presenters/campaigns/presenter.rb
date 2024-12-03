# frozen_string_literal: true

# app/presenters/campaigns/presenter.rb
module Campaigns
  # variables required by KPI views
  class Presenter
    attr_accessor :campaign, :trigger
    attr_reader :client, :user, :triggeraction

    # presenter = Campaigns::Presenter.new(current_user)
    def initialize(user)
      @user = case user
              when User
                user
              when Integer
                User.find_by(id: user)
              else
                User.new
              end

      @callrail_client_api_integration_events               = nil
      @campaigns                                            = nil
      @cardx_client_api_integration_events                  = nil
      @client                                               = @user&.client || Client.new
      @client_custom_fields_hash_date                       = nil
      @client_custom_fields_hash_string                     = nil
      @dropfunnels_client_api_integration_data              = nil
      @housecallpro_client_api_integration_webhooks         = nil
      @jobber_client_api_integration_webhooks               = nil
      @servicemonster_client_api_integration_webhooks       = nil
      @servicetitan_client_api_integration_events           = nil
      @slack_channels                                       = nil
      @slack_token                                          = nil
      @stage_parents                                        = nil
      @stages_starting_campaigns                            = nil
      @tags_starting_campaigns                              = nil
      @triggeraction_assign_to_users                        = nil
      @triggeractions_array                                 = nil
      @triggeraction_options_for_client_custom_field_id_600 = nil
      @triggeraction_options_for_client_custom_field_id_605 = nil
      @triggeraction_options_for_client_custom_field_id_610 = nil
      @triggeraction_options_for_users_182_700_750          = nil
      @triggeraction_options_for_users_615                  = nil
      @triggeractions_starting_campaigns                    = nil
      @webhook_apis_starting_campaigns                      = nil
      @widgets_starting_campaigns                           = nil
    end

    def allow_repeat_icon
      if @campaign.allow_repeat

        if @campaign.allow_repeat_period == 'immediately'
          '<i class="fa fa-recycle text-success"></i>'
        else
          '<i class="fa fa-recycle text-warning"></i>'
        end
      else
        '<i class="fa fa-recycle text-danger"></i>'
      end
    end

    def callrail_client_api_integration_events
      @callrail_client_api_integration_events ||= @client.client_api_integrations.find_by(target: 'callrail', name: '')&.events if @client.integrations_allowed.include?('callrail')
    end

    def callrail_events_starting_this_campaign(campaign_id)
      self.callrail_client_api_integration_events&.select { |e| e.dig('action', 'campaign_id') == campaign_id }
    end

    def campaign_array_grouped
      ApplicationController.helpers.options_for_campaign_array(client: @user.client, grouped: true, first_trigger_types: [100, 110, 115, 120, 125, 130, 132, 133, 134, 135, 136, 137, 138, 139, 140, 142, 143, 144, 145, 146, 147, 148, 149, 150, 152, 155], include_analyzed: true)
    end

    def campaign_disabled?
      @campaign.marketplace?
    end

    def campaigns
      @campaigns ||= @client.campaigns.where.not(id: campaigns_to_be_destroyed).order(:name).includes(:campaign_share_code, :campaign_group)
    end

    def campaigns_starting_this_campaign(campaign_id)
      Campaign.joins(:triggers).where(triggers: { id: self.triggeractions_starting_campaigns.select { |t| t.campaign_id == campaign_id || t.response_range&.find { |_k, v| v.dig('campaign_id') == campaign_id } }.pluck(:trigger_id) })
    end

    def campaigns_to_be_destroyed
      DelayedJob.where(user_id: @client.users, process: 'campaign_destroy').map { |c| c.data.dig('campaign_id') }.compact_blank
    end

    def cardx_client_api_integration_events
      @cardx_client_api_integration_events ||= @client.client_api_integrations.find_by(target: 'cardx', name: '')&.events if @client.integrations_allowed.include?('cardx')
    end

    def cardx_events_starting_this_campaign(campaign_id)
      self.cardx_client_api_integration_events&.select { |e| e.dig('action', 'campaign_id') == campaign_id }
    end

    def client_custom_field
      @client_custom_field ||= @triggeraction.client_custom_field_id.to_i.positive? ? ClientCustomField.find_by(id: @triggeraction.client_custom_field_id) : @client.client_custom_fields.new
    end

    def client_custom_field_action_campaign_id(range)
      range[1].dig('campaign_id').to_i
    end

    def client_custom_field_action_currency_range
      @response_range = @triggeraction.response_range.dup
      @element_count  = @response_range.count
      self.client_custom_field_action_range_new_range(self.client_custom_field&.var_options&.[](:currency_min).to_d, self.client_custom_field&.var_options&.[](:currency_max).to_d)
      self.client_custom_field_action_range_new_image
      self.client_custom_field_action_range_new_empty
      self.client_custom_field_action_range_new_invalid

      @response_range
    end

    def client_custom_field_action_currency_range_min_max_step(range)
      case self.client_custom_field_action_maximum(range).to_d - self.client_custom_field_action_minimum(range).to_d
      when 0..499.99
        0.01
      when 500..999.99
        1
      when 1000..9999.99
        10
      when 10_000..99_999.99
        100
      when 100_000..9_999_999.99
        500
      when 1_000_000..99_999_999.99
        1000
      else
        5000
      end
    end

    def client_custom_field_action_group(range)
      (range[1].dig('group_id').to_i.positive? ? @client.groups.find_by(id: range[1]['group_id'].to_i) : nil) || @client.groups.new
    end

    def client_custom_field_action_legend(range)
      case self.client_custom_field_action_type(range)
      when 'image'
        'Image Range'
      when 'empty'
        'Empty Response Range'
      when 'invalid'
        'Invalid Response Range'
      else
        if (self.client_custom_field_action_campaign_id(range) + range[1].dig('group_id').to_i + range[1].dig('stage_id').to_i + range[1].dig('tag_id').to_i).zero?
          'New Response Range'
        else
          'Response Range'
        end
      end
    end

    def client_custom_field_action_maximum(range)
      range[1].dig('maximum')
    end

    def client_custom_field_action_minimum(range)
      range[1].dig('minimum')
    end

    def client_custom_field_action_numeric_range
      @response_range = @triggeraction.response_range.dup
      @element_count  = @response_range.count
      self.client_custom_field_action_range_new_range(self.client_custom_field&.var_options&.[](:numeric_min).to_i, self.client_custom_field&.var_options&.[](:numeric_max).to_i)
      self.client_custom_field_action_range_new_image
      self.client_custom_field_action_range_new_empty
      self.client_custom_field_action_range_new_invalid

      @response_range
    end

    def client_custom_field_action_numeric_range_min_max_step(range)
      case self.client_custom_field_action_maximum(range).to_i - self.client_custom_field_action_minimum(range).to_i
      when 0..1000
        1
      when 1001..10_000
        10
      when 10_001..100_000
        100
      when 100_001..1_000_000
        500
      when 1_000_001..10_000_000
        1000
      else
        5000
      end
    end

    def client_custom_field_action_range_new_empty
      return if @response_range.find { |_key, value| value['range_type'].to_s == 'empty' }

      @response_range[(@element_count += 1).to_s] = {
        'campaign_id' => 0,
        'group_id'    => 0,
        'stage_id'    => 0,
        'tag_id'      => 0,
        'range_type'  => 'empty'
      }
    end

    def client_custom_field_action_range_new_image
      if self.client_custom_field&.image_is_valid && !@response_range.find { |_key, value| value['range_type'].to_s == 'image' }
        @response_range[(@element_count += 1).to_s] = {
          'campaign_id' => 0,
          'group_id'    => 0,
          'stage_id'    => 0,
          'tag_id'      => 0,
          'range_type'  => 'image'
        }
      elsif !self.client_custom_field&.image_is_valid
        @response_range.delete(@response_range.find { |_key, value| value['range_type'].to_s == 'image' })
      end
    end

    def client_custom_field_action_range_new_invalid
      return if @response_range.find { |_key, value| value['range_type'].to_s == 'invalid' }

      @response_range[(@element_count + 1).to_s] = {
        'campaign_id' => 0,
        'group_id'    => 0,
        'stage_id'    => 0,
        'tag_id'      => 0,
        'range_type'  => 'invalid'
      }
    end

    def client_custom_field_action_range_new_range(minimum, maximum)
      @response_range[(@element_count += 1).to_s] = {
        'minimum'     => minimum,
        'maximum'     => maximum,
        'campaign_id' => 0,
        'group_id'    => 0,
        'stage_id'    => 0,
        'tag_id'      => 0,
        'range_type'  => 'range'
      }
    end

    def client_custom_field_action_slider(range)
      %w[empty image invalid].exclude?(self.client_custom_field_action_type(range))
    end

    def client_custom_field_action_stars_range
      @response_range = @triggeraction.response_range.dup
      @element_count  = @response_range.count
      self.client_custom_field_action_range_new_range(0, self.client_custom_field&.var_options&.[](:stars_max).to_i)
      self.client_custom_field_action_range_new_image
      self.client_custom_field_action_range_new_empty
      self.client_custom_field_action_range_new_invalid

      @response_range
    end

    def client_custom_field_action_stars_range_min_max_step(range)
      case self.client_custom_field_action_maximum(range).to_i - self.client_custom_field_action_minimum(range).to_i
      when 0..1000
        1
      when 1001..10_000
        10
      when 10_001..100_000
        100
      when 100_001..1_000_000
        500
      when 1_000_001..10_000_000
        1000
      else
        5000
      end
    end

    def client_custom_field_action_string_option_group(string_option)
      (@triggeraction.response_range.dig(string_option, 'group_id').to_i.positive? ? @client.groups.find_by(id: @triggeraction.response_range.dig(string_option, 'group_id').to_i) : nil) || @client.groups.new
    end

    def client_custom_field_action_string_option_options_for_stage(string_option)
      ApplicationController.helpers.option_groups_from_collection_for_select(StageParent.where(client: @client.id), :stages, :name, :id, :name, @triggeraction.response_range.dig(string_option, 'stage_id').to_i)
    end

    def client_custom_field_action_string_option_tag(string_option)
      (@triggeraction.response_range.dig(string_option, 'tag_id').to_i.positive? ? @client.tags.find_by(id: @triggeraction.response_range.dig(string_option, 'tag_id').to_i) : nil) || @client.tags.new
    end

    def client_custom_field_action_string_option_stop_campaign_ids(string_option)
      @triggeraction.response_range.dig(string_option, 'stop_campaign_ids')
    end

    def client_custom_field_action_tag(range)
      (range[1].dig('tag_id').to_i.positive? ? @client.tags.find_by(id: range[1]['tag_id'].to_i) : nil) || @client.tags.new
    end

    def client_custom_field_action_type(range)
      (range[1].dig('range_type') || 'range').to_s
    end

    def client_custom_field_action_stop_campaign_ids(range)
      range[1].dig('stop_campaign_ids')
    end

    def client_custom_field_string_options_as_array
      response  = self.client_custom_field.string_options_as_array
      response << 'image' if self.client_custom_field.image_is_valid
      response << 'empty' << 'invalid'
    end

    def client_custom_fields_hash_date
      @client_custom_fields_hash_date ||= @client.client_custom_fields.where(var_type: 'date').order(:var_name).pluck(:var_name, :id)
    end

    def client_custom_fields_hash_string
      @client_custom_fields_hash_string ||= @client.client_custom_fields.where(var_type: 'string').order(:var_name).pluck(:var_name, :id)
    end

    def dropfunnels_client_api_integration_data
      @dropfunnels_client_api_integration_data ||= @client.client_api_integrations.find_by(target: 'dropfunnels', name: '')&.data if @client.integrations_allowed.include?('dropfunnels')
    end

    def dropfunnels_events_starting_this_campaign(campaign_id)
      self.dropfunnels_client_api_integration_data&.map { |k, v| k if v.dig('campaign_id').to_i == campaign_id }&.compact_blank || []
    end

    def housecallpro_client_api_integration_webhooks
      @housecallpro_client_api_integration_webhooks ||= @client.client_api_integrations.find_by(target: 'housecall', name: '')&.webhooks if @client.integrations_allowed.include?('housecall')
    end

    def housecallpro_events_starting_this_campaign(campaign_id)
      self.housecallpro_client_api_integration_webhooks&.select { |_k, v| v.any? { |e| e.dig('actions', 'campaign_id') == campaign_id } }
    end

    def jobber_client_api_integration_webhooks
      @jobber_client_api_integration_webhooks ||= @client.client_api_integrations.find_by(target: 'jobber', name: '')&.webhooks if @client.integrations_allowed.include?('jobber')
    end

    def jobber_events_starting_this_campaign(campaign_id)
      self.jobber_client_api_integration_webhooks&.select { |_k, v| v.any? { |e| e.dig('actions', 'campaign_id') == campaign_id } }
    end

    def jobber_integrations_path
      Rails.application.routes.url_helpers.send("integrations_jobber_v#{@client.client_api_integrations.find_by(target: 'jobber', name: '')&.data&.dig('credentials', 'version').presence || '20231115'}_path")
    end

    def servicemonster_client_api_integration_webhooks
      @servicemonster_client_api_integration_webhooks ||= @client.client_api_integrations.find_by(target: 'servicemonster', name: '')&.webhooks if @client.integrations_allowed.include?('servicemonster')
    end

    def servicemonster_events_starting_this_campaign(campaign_id)
      self.servicemonster_client_api_integration_webhooks&.select { |_k, v| v&.dig('events')&.any? { |e| e.dig('actions', 'campaign_id') == campaign_id } }
    end

    def servicetitan_client_api_integration_events
      @servicetitan_client_api_integration_events ||= @client.client_api_integrations.find_by(target: 'servicetitan', name: '')&.events if @client.integrations_allowed.include?('servicetitan')
    end

    def servicetitan_events_starting_this_campaign(campaign_id)
      self.servicetitan_client_api_integration_events&.select { |_id, v| v.dig('campaign_id') == campaign_id }
    end

    def show_submit_button?
      (Triggeraction::ALL_TYPES - [450, 500, 501]).include?(@triggeraction.action_type)
    end

    def slack_channels
      @slack_channels ||= Integrations::Slacker::Base.new(self.slack_token).channel_names.sort
    end

    def slack_token
      @slack_token ||= @user.user_api_integrations.find_by(target: 'slack', name: '')&.token
    end

    def stage_parents
      @stage_parents ||= StageParent.where(client: @client.id)
    end

    def stages_starting_campaigns
      @stages_starting_campaigns ||= Stage.for_client(@client.id).where('campaign_id > 0')
    end

    def stage_parents_starting_this_campaign(campaign_id)
      StageParent.joins(:stages).where(stages: { id: self.stages_starting_campaigns.select { |t| t.campaign_id == campaign_id } })
    end

    def tags_starting_campaigns
      @tags_starting_campaigns ||= Tag.for_client(@client.id).where('campaign_id > 0')
    end

    def tags_starting_this_campaign(campaign_id)
      self.tags_starting_campaigns.select { |t| t.campaign_id == campaign_id }
    end

    def trigger_card_id
      "trigger-card-#{@trigger.new_record? ? @trigger.campaign_id : @trigger.id}"
    end

    def trigger_client_custom_field_id
      @trigger.data&.dig(:client_custom_field_id).to_s
    end

    def trigger_form_id
      "trigger-form-#{@trigger.new_record? ? @campaign.id : @trigger.id}"
    end

    def trigger_header_id
      "trigger-form-header-#{@trigger.new_record? ? @campaign.id : @trigger.id}"
    end

    def trigger_name
      @trigger.new_record? ? 'New Trigger' : @trigger.data.dig(:name).to_s
    end

    def trigger_options_for_client_custom_field_id(integration, field_types)
      response = []

      if integration == 'housecallpro'
        response << ['Estimate Fields:', [['Scheduled Start Date (E)', 'estimate_scheduled_start_at'], ['Scheduled End Date (E)', 'estimate_scheduled_end_at'], ['Actual Started Date (E)', 'estimate_actual_started_at'], ['Actual Completed Date (E)', 'estimate_actual_completed_at'], ['Actual On My Way Date (E)', 'estimate_actual_on_my_way_at']]] if field_types.include?('estimates')
        response << ['Job Fields:', [['Scheduled Start Date (J)', 'job_scheduled_start_at'], ['Scheduled End Date (J)', 'job_scheduled_end_at'], ['Actual Started Date (J)', 'job_actual_started_at'], ['Actual Completed Date (J)', 'job_actual_completed_at'], ['Actual On My Way Date (J)', 'job_actual_on_my_way_at']]] if field_types.include?('jobs')
      end

      response << ['Estimate Fields:', [['Scheduled Start Date (E)', 'estimate_scheduled_start_at'], ['Scheduled End Date (E)', 'estimate_scheduled_end_at']]] if %w[jobber jobnimbus responsibid servicetitan].include?(integration) && field_types.include?('estimates')

      response << ['Visit Fields:', [['Start Date (V)', 'visit_start_at'], ['End Date (V)', 'visit_end_at']]] if integration == 'jobber' && field_types.include?('visits')

      response << ['Work Order Fields:', [['Scheduled Start Date (WO)', 'job_scheduled_start_at'], ['Scheduled End Date (WO)', 'job_scheduled_end_at']]] if integration == 'jobnimbus' && field_types.include?('workorders')

      if integration == 'servicemonster'
        response << ['Estimate Fields:', [['Scheduled Start Date (E)', 'estimate_scheduled_start_at'], ['Scheduled End Date (E)', 'estimate_scheduled_end_at'], ['Actual Started Date (E)', 'estimate_actual_started_at'], ['Actual Completed Date (E)', 'estimate_actual_completed_at']]] if field_types.include?('estimates')
        response << ['Order Fields:', [['Scheduled Start Date (O)', 'job_scheduled_start_at'], ['Scheduled End Date (O)', 'job_scheduled_end_at'], ['Actual Started Date (O)', 'job_actual_started_at'], ['Actual Completed Date (O)', 'job_actual_completed_at']]] if field_types.include?('orders')
      end

      response << ['Job Fields:', [['Scheduled Start Date (J)', 'job_scheduled_start_at'], ['Scheduled End Date (J)', 'job_scheduled_end_at']]] if %w[jobber servicetitan].include?(integration) && field_types.include?('jobs')

      response
    end

    def trigger_start_campaign_specific_date
      response = @trigger.data&.dig(:start_campaign_specific_date).to_s
      response = Time.use_zone(@client.time_zone) { Chronic.parse(response) }.strftime('%m/%d/%Y %H:%M %p') if response.present?
    end

    def trigger_target_time
      response = @trigger.data&.dig(:target_time).to_s
      response = Time.use_zone(@client.time_zone) { Chronic.parse(response) }.strftime('%m/%d/%Y %H:%M %p') if response.present?
    end

    def triggeraction=(triggeraction)
      @triggeraction = case triggeraction
                       when Triggeraction
                         triggeraction
                       when Integer
                         Triggeraction.find_by(id: triggeraction)
                       else
                         Triggeraction.new
                       end

      @client_custom_field = nil
      @triggeraction_group = nil
      @triggeraction_tag   = nil
    end

    def triggeraction_accordion_id
      @trigger.new_record? ? "triggeraction-accordion-#{@campaign_id}" : "triggeraction-accordion-#{@trigger.id}"
    end

    def triggeraction_assign_to_users
      @triggeraction_assign_to_users ||= @client.org_positions.order(:level).pluck(:id, :title).to_h { |org_position| ["orgposition_#{org_position[0]}", org_position[1]] }.merge(@client.users.where.not(id: nil).order(:lastname, :firstname).pluck(:id, :firstname, :lastname).to_h { |user| ["user_#{user[0]}", Friendly.new.fullname(user[1], user[2])] })
    end

    def triggeraction_class_for_send_to
      response  = 3
      response += 1 if response != 5 && @client.integrations_allowed.include?('housecall')
      response + 1 if response != 5 && @client.integrations_allowed.include?('servicemonster')
    end

    def triggeraction_form_id
      @triggeraction.new_record? ? "triggeraction-form-#{@trigger.id}" : "triggeraction-form-#{@triggeraction.id}"
    end

    def triggeraction_group
      return @triggeraction_group if @triggeraction_group.present?

      @triggeraction_group = if @triggeraction.group_id.positive?
                               @client.groups.find_by(id: @triggeraction.group_id) || @client.groups.new
                             else
                               @client.groups.new
                             end
    end

    def triggeraction_header_id
      @triggeraction.new_record? ? "triggeraction-form-header-#{@trigger.id}" : "triggeraction-form-header-#{@triggeraction.id}"
    end

    def triggeraction_name
      @triggeraction.new_record? ? 'New Action' : @triggeraction.type_name
    end

    def triggeraction_note_for_email_message
      response  = ["This field is hashtag aware. Click '#' to access data fields."]
      response << "'(FR)' fields are only accessible when Campaign is triggered by a FieldRoutes Event." if @client.integrations_allowed.include?('fieldroutes')
      response << "'(HCP)' fields are only accessible when Campaign is triggered by a Housecall Pro Event." if @client.integrations_allowed.include?('housecall')
      response << "'(JB)' fields are only accessible when Campaign is triggered by a Jobber Event." if @client.integrations_allowed.include?('jobber')
      response << "'(JN)' fields are only accessible when Campaign is triggered by a JobNimbus Event." if @client.integrations_allowed.include?('jobnimbus')
      response << "'(RB)' fields are only accessible when Campaign is triggered by a ResponsiBid Event." if @client.integrations_allowed.include?('responsibid')
      response << "'(SM)' fields are only accessible when Campaign is triggered by a ServiceMonster Event." if @client.integrations_allowed.include?('servicemonster')
      response << "'(ST)' fields are only accessible when Campaign is triggered by a ServiceTitan Event." if @client.integrations_allowed.include?('servicetitan')
      response.join('<br />')
    end

    def triggeraction_note_for_send_to
      response  = []
      response << "'Technician (FR)' recipients are only accessible when Campaign is triggered by a FieldRoutes Event." if @client.integrations_allowed.include?('fieldroutes')
      response << "'Technician (HCP)' recipients are only accessible when Campaign is triggered by a Housecall Pro Event." if @client.integrations_allowed.include?('housecall')
      response << "'Technician (JB)' recipients are only accessible when Campaign is triggered by a Jobber Event." if @client.integrations_allowed.include?('jobber')
      response << "'Technician (SM)' recipients are only accessible when Campaign is triggered by a ServiceMonster Event." if @client.integrations_allowed.include?('servicemonster')
      response << "'Technician (ST)' recipients are only accessible when Campaign is triggered by a ServiceTitan Event." if @client.integrations_allowed.include?('servicetitan')
      response.join('<br />')
    end

    def triggeraction_note_for_slack_message
      response  = ["This field is hashtag aware. Click '#' to access data fields."]
      response << "'(FR)' fields are only accessible when Campaign is triggered by a FieldRoutes Event." if @client.integrations_allowed.include?('fieldroutes')
      response << "'(HCP)' fields are only accessible when Campaign is triggered by a Housecall Pro Event." if client.integrations_allowed.include?('housecall')
      response << "'(JB)' fields are only accessible when Campaign is triggered by a Jobber Event." if client.integrations_allowed.include?('jobber')
      response << "'(JN)' fields are only accessible when Campaign is triggered by a JobNimbus Event." if client.integrations_allowed.include?('jobnimbus')
      response << "'(RB)' fields are only accessible when Campaign is triggered by a ResponsiBid Event." if client.integrations_allowed.include?('responsibid')
      response << "'(SM)' fields are only accessible when Campaign is triggered by a ServiceMonster Event." if client.integrations_allowed.include?('servicemonster')
      response << "'(ST)' fields are only accessible when Campaign is triggered by a ServiceTitan Event." if client.integrations_allowed.include?('servicetitan')
      response.join('<br />')
    end

    def triggeraction_options_for_client_custom_field_id_600
      @triggeraction_options_for_client_custom_field_id_600 ||= (::Webhook.internal_key_hash(@client, 'contact', %w[personal ext_references]).invert.to_a + ::Webhook.internal_key_hash(@client, 'contact', %w[phones]).merge(@client.client_custom_fields.pluck(:id, :var_name).to_h).invert.to_a + [%w[Notes brand-notes]]).sort_by { |field| field[0] }
    end

    def triggeraction_options_for_client_custom_field_id_605
      @triggeraction_options_for_client_custom_field_id_605 ||= @client.client_custom_fields.where(var_type: %w[string numeric stars currency]).filter_map { |ccf| (ccf.var_type == 'string' && ccf.var_options.dig(:string_options).to_s.present?) || ccf.var_type != 'string' ? [ccf.var_name, ccf.id] : nil }.to_h.sort
    end

    def triggeraction_options_for_client_custom_field_id_610
      @triggeraction_options_for_client_custom_field_id_610 ||= ::Webhook.internal_key_hash(@client, 'contact', %w[personal ext_references]).invert.to_a + [['OK to Text', 'ok2text'], ['OK to Email', 'ok2email']] + ::Webhook.internal_key_hash(@client, 'contact', %w[phones]).merge(@client.client_custom_fields.pluck(:id, :var_name).to_h).invert.to_a
    end

    def triggeraction_options_for_users_182_700_750
      return @triggeraction_options_for_users_182_700_750 if @triggeraction_options_for_users_182_700_750.present?

      @triggeraction_options_for_users_182_700_750  = [['User to which Contact Belongs', 'user']]
      @triggeraction_options_for_users_182_700_750 += @client.org_positions.order(:level).pluck(:id, :title).map { |org_position| [org_position[1], "orgposition_#{org_position[0]}"] }
      @triggeraction_options_for_users_182_700_750 += @client.users.where.not(id: nil).order(:lastname, :firstname).pluck(:id, :firstname, :lastname).map { |user| [Friendly.new.fullname(user[1], user[2]), "user_#{user[0]}"] }

      @triggeraction_options_for_users_182_700_750
    end

    def triggeraction_options_for_users_615
      return @triggeraction_options_for_users_615 if @triggeraction_options_for_users_615.present?

      @triggeraction_options_for_users_615  = [['User to which Contact Belongs', 'user']]
      @triggeraction_options_for_users_615 += @client.users.where.not(id: nil).order(:lastname, :firstname).pluck(:id, :firstname, :lastname).map { |user| [Friendly.new.fullname(user[1], user[2]), "user_#{user[0]}"] }

      @triggeraction_options_for_users_615
    end

    def triggeraction_options_for_text_send_to(contact_only: false)
      response  = @client.contact_phone_labels.map { |label| ["Contact (#{label.capitalize})", "contact_#{label}"] }
      response += [['Contact (Last Number Used)', 'last_number'], ['Contact (Primary Number)', 'primary'], ['User to which Contact Belongs', 'user']] unless contact_only
      response += @client.org_positions.order(:level).pluck(:id, :title).map { |org_position| ["#{org_position[1]} (Org)", "orgposition_#{org_position[0]}"] } unless contact_only
      response += @client.users.where.not(id: nil).where.not(id: nil).order(:lastname, :firstname).pluck(:id, :firstname, :lastname).map { |user| [Friendly.new.fullname(user[1], user[2]), "user_#{user[0]}"] } unless contact_only
      response += [['Technician (FR)', 'technician_fieldroutes']] if !contact_only && @client.integrations_allowed.include?('fieldroutes')
      response += [['Technician (HCP)', 'technician_housecall']] if !contact_only && @client.integrations_allowed.include?('housecall')
      response += [['Technician (JB)', 'technician_jobber']] if !contact_only && @client.integrations_allowed.include?('jobber')
      response += [['Technician (SM)', 'technician_servicemonster']] if !contact_only && @client.integrations_allowed.include?('servicemonster')
      response += [['Technician (ST)', 'technician_servicetitan']] if !contact_only && @client.integrations_allowed.include?('servicetitan')
      response.sort!
    end

    def triggeraction_options_for_email_user_send_to
      response = [['User to which Contact Belongs', 'user']]
      response += @client.org_positions.order(:level).pluck(:id, :title).map { |org_position| ["#{org_position[1]} (Org)", "orgposition_#{org_position[0]}"] }
      response += @client.users.where.not(id: nil).where.not(id: nil).order(:lastname, :firstname).pluck(:id, :firstname, :lastname).map { |user| [Friendly.new.fullname(user[1], user[2]), "user_#{user[0]}"] }
      response += [['Technician (FR)', 'technician_fieldroutes']] if @client.integrations_allowed.include?('fieldroutes')
      response += [['Technician (HCP)', 'technician_housecall']] if @client.integrations_allowed.include?('housecall')
      response += [['Technician (JB)', 'technician_jobber']] if @client.integrations_allowed.include?('jobber')
      response += [['Technician (SM)', 'technician_servicemonster']] if @client.integrations_allowed.include?('servicemonster')
      response += [['Technician (ST)', 'technician_servicetitan']] if @client.integrations_allowed.include?('servicetitan')
      response.sort!
    end

    def triggeraction_options_for_sent_to_750
      response  = @client.contact_phone_labels.map { |label| ["Contact (#{label.capitalize})", "contact_#{label}"] }
      response += [['User to which Contact Belongs', 'user']]
      response += @client.org_positions.order(:level).pluck(:id, :title).map { |org_position| [org_position[1], "orgposition_#{org_position[0]}"] }
      response += @client.users.where.not(id: nil).order(:lastname, :firstname).pluck(:id, :firstname, :lastname).map { |user| [Friendly.new.fullname(user[1], user[2]), "user_#{user[0]}"] }
      response.sort!
    end

    def triggeraction_schedule_string
      @triggeraction.new_record? ? '' : "<small>#{@triggeraction.schedule_string}</small>"
    end

    def triggeraction_tag
      return @triggeraction_tag if @triggeraction_tag.present?

      @triggeraction_tag = if @triggeraction.tag_id.positive?
                             @client.tags.find_by(id: @triggeraction.tag_id) || @client.tags.new
                           else
                             @client.tags.new
                           end
    end

    def triggeractions_array
      return @triggeractions_array if @triggeractions_array.present?

      response = Triggeraction.type_hash(@client)

      unless (user_api_integration = @user.user_api_integrations.find_by(target: 'slack', name: '')) && user_api_integration.token.present?
        response.delete(180)
        response.delete(181)
        response.delete(182)
      end

      response.delete(801) unless @user.agent?
      response.delete(600) unless [100, 155].include?(@trigger.trigger_type.to_i)

      @triggeractions_array = response.invert.to_a
    end

    def triggeractions_starting_campaigns
      @triggeractions_starting_campaigns ||= Triggeraction.for_client_and_action_type(@client.id, [200, 605, 610, 700])
    end

    def webhook_apis_starting_campaigns
      @webhook_apis_starting_campaigns ||= Webhook.for_client(@client.id).where('campaign_id > 0')
    end

    def webhook_apis_starting_this_campaign(campaign_id)
      self.webhook_apis_starting_campaigns.select { |t| t.campaign_id == campaign_id }
    end

    def widgets_starting_campaigns
      @widgets_starting_campaigns ||= Clients::Widget.for_client(@client.id).where('campaign_id > 0').or(Clients::Widget.for_client(@client.id).where('formatting::TEXT ILIKE ?', '%campaign_id%'))
    end

    def widgets_starting_this_campaign(campaign_id)
      self.widgets_starting_campaigns.select { |w| w.campaign_id == campaign_id || w.formatting&.dig('w_dd_actions')&.find { |_k, v| v.dig('campaign_id') == campaign_id } }
    end
  end
end
