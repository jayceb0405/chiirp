# frozen_string_literal: true

# app/controllers/triggeractions_controller.rb
class TriggeractionsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user!
  before_action :trigger
  before_action :triggeraction, only: %i[destroy edit edit_client_custom_fields index_801 update]
  before_action :campaign

  # (POST) create a Triggeraction
  # /triggers/:trigger_id/triggeractions
  # trigger_triggeractions_path(:trigger_id)
  # trigger_triggeractions_url(:trigger_id)
  def create
    sanitized_params = params.permit(:action_type, :triggeraction_id)

    if sanitized_params.dig(:action_type).to_i.positive?

      if sanitized_params.dig(:triggeraction_id).to_i.zero?
        # create a new Triggeraction
        @triggeraction = @trigger.triggeractions.create(action_type: sanitized_params[:action_type].to_i)
        @trigger.reload

        cards = %w[convert_triggeraction_ids triggeraction]
      elsif (@triggeraction = @trigger.triggeractions.find_by(id: sanitized_params[:triggeraction_id]))
        # change a Triggeraction type

        @triggeraction.update(action_type: sanitized_params[:action_type].to_i, data: {})
        @triggeraction.reload
        @trigger.reload
        cards = %w[triggeraction]
      else
        cards = %w[triggeractions]
      end
    else
      cards = %w[triggeractions]
    end

    @campaign.update(analyzed: @campaign.analyze!.empty?)

    render partial: 'triggeractions/js/show', locals: { cards: }
  end

  # (DELETE) delete a Triggeraction
  # /triggers/:trigger_id/triggeractions/:id
  # trigger_triggeraction_path(:trigger_id, :id)
  # trigger_triggeraction_url(:trigger_id, :id)
  def destroy
    @triggeraction.destroy
    @campaign.update(analyzed: @campaign.analyze!.empty?)

    render partial: 'triggeractions/js/show', locals: { cards: %w[triggeractions] }
  end

  # (GET) edit a Triggeraction
  # /triggers/:trigger_id/triggeractions/:id/edit
  # edit_trigger_triggeraction_path(:trigger_id, :id)
  # edit_trigger_triggeraction_url(:trigger_id, :id)
  def edit
    render partial: 'triggeractions/js/show', locals: { cards: %w[triggeraction_edit] }
  end

  # (GET) edit a Triggeraction
  # /triggers/:trigger_id/triggeractions/:id/client_custom_fields
  # edit_client_custom_fields_trigger_triggeraction_path(:trigger_id, :id)
  # edit_client_custom_fields_trigger_triggeraction_url(:trigger_id, :id)
  def edit_client_custom_fields
    orig_triggeraction_id  = params.permit(:orig_triggeraction_id).dig(:orig_triggeraction_id).to_i
    client_custom_field_id = params.permit(:client_custom_field_id).dig(:client_custom_field_id).to_i

    @triggeraction = @trigger.triggeractions.new(action_type: 605, client_custom_field_id:) if client_custom_field_id != @triggeraction.client_custom_field_id

    render partial: 'triggeractions/js/show', locals: { cards: %w[client_custom_field], orig_triggeraction_id: }
  end

  # (GET) list Client options associated with a Triggeraction of type 801
  # /triggers/:trigger_id/triggeractions/:id/801index
  # index_801_trigger_triggeraction_path(:trigger_id, :id)
  # index_801_trigger_triggeraction_url(:trigger_id, :id)
  # clients: [{ client_id: integer, client_campaign_id: integer, agency_campaign_id: integer, max_monthly_leads: integer, leads_this_month: integer, period_start_date: DateTime.iso8601 }]
  def index_801
    sanitized_params = params.permit(clients: [])
    new_clients = []

    sanitized_params.dig(:clients).each do |client_id|
      if (client = Client.by_agency(@triggeraction.campaign.client_id).find_by(id: client_id))
        new_clients << if (existing_client_ta_hash = @triggeraction.clients.find { |ta_client| ta_client['client_id'] == client_id.to_i })
                         { 'client_id' => client.id, 'client_campaign_id' => existing_client_ta_hash['client_campaign_id'], 'agency_campaign_id' => existing_client_ta_hash['agency_campaign_id'], 'max_monthly_leads' => existing_client_ta_hash['max_monthly_leads'], 'leads_this_month' => existing_client_ta_hash['leads_this_month'], 'period_end_date' => client.next_pmt_date.to_time.in_time_zone(client.time_zone).utc.iso8601 }
                       else
                         { 'client_id' => client.id, 'client_campaign_id' => 0, 'agency_campaign_id' => 0, 'max_monthly_leads' => 0, 'leads_this_month' => 0, 'period_end_date' => client.next_pmt_date.to_time.in_time_zone(client.time_zone).utc.iso8601 }
                       end
      end
    end

    @triggeraction.update(clients: new_clients)

    render partial: 'triggeractions/js/show', locals: { cards: %w[index_801] }
  end

  # (GET) set up a new Triggeraction
  # /triggers/:trigger_id/triggeractions/new
  # new_trigger_triggeraction_path(:trigger_id)
  # new_trigger_triggeraction_url(:trigger_id)
  def new
    cards = if params.dig(:no_load).to_bool
              %w[triggeractions_new show_triggeraction_form]
            else
              %w[triggeractions_renew]
            end

    render partial: 'triggeractions/js/show', locals: { cards: }
  end

  # (PUT/PATCH) update a Triggeraction
  # /triggers/:trigger_id/triggeractions/:id
  # trigger_triggeraction_path(:trigger_id, :id)
  # trigger_triggeraction_url(:trigger_id, :id)
  def update
    @triggeraction.update(params_triggeraction)
    @trigger.reload
    @triggeraction.reload
    @campaign.update(analyzed: @campaign.analyze!.empty?)

    render partial: 'triggeractions/js/show', locals: { cards: %w[triggeraction hide_triggeraction_form] }
  end

  private

  def authorize_user!
    super
    return if current_user.access_controller?('campaigns', 'allowed', session)

    raise ExceptionHandlers::UserNotAuthorized.new('Campaign Builder', root_path)
  end

  def params_triggeraction
    response = {}

    if params.include?(:triggeraction_scheduler)
      sanitized_params = params.require(:triggeraction_scheduler).permit(
        :delay_months, :delay_days, :delay_hours, :delay_minutes, :safe_times, :ok2skip,
        :safe_sun, :safe_mon, :safe_tue, :safe_wed, :safe_thu, :safe_fri, :safe_sat
      )

      safe_times = sanitized_params.dig(:safe_times).to_s.split(';')

      response[:delay_months]  = sanitized_params.dig(:delay_months).to_i
      response[:delay_days]    = sanitized_params.dig(:delay_days).to_i
      response[:delay_hours]   = sanitized_params.dig(:delay_hours).to_i
      response[:delay_minutes] = sanitized_params.dig(:delay_minutes).to_i
      response[:safe_start]    = (safe_times[0] || 480).to_i
      response[:safe_end]      = (safe_times[1] || 1200).to_i
      response[:safe_sun]      = (sanitized_params.dig(:safe_sun) || false).to_bool
      response[:safe_mon]      = (sanitized_params.dig(:safe_mon) || false).to_bool
      response[:safe_tue]      = (sanitized_params.dig(:safe_tue) || false).to_bool
      response[:safe_wed]      = (sanitized_params.dig(:safe_wed) || false).to_bool
      response[:safe_thu]      = (sanitized_params.dig(:safe_thu) || false).to_bool
      response[:safe_fri]      = (sanitized_params.dig(:safe_fri) || false).to_bool
      response[:safe_sat]      = (sanitized_params.dig(:safe_sat) || false).to_bool
      response[:ok2skip]       = sanitized_params.dig(:ok2skip).to_bool
    end

    if params.include?(:triggeraction)

      case @triggeraction.action_type
      when 100
        # 100 send text message
        sanitized_params = params.require(:triggeraction).permit(:send_to, from_phone: [])
        response[:from_phone]           = [sanitized_params.dig(:from_phone)].flatten.compact_blank
        response[:send_to]              = sanitized_params.dig(:send_to).to_s
        response[:last_used_from_phone] = ''

        sanitized_params = params.require(:message).permit(:message, :file_attachments)
        response[:text_message] = sanitized_params.dig(:message).to_s
        response[:attachments]  = JSON.parse(sanitized_params.dig(:file_attachments)).map { |f| f.dig('id').to_i }
      when 150
        # 150 send an RVM
        sanitized_params = params.require(:triggeraction).permit(:voice_recording_id, :from_phone)

        response[:voice_recording_id] = sanitized_params.dig(:voice_recording_id).to_i.positive? ? sanitized_params.dig(:voice_recording_id).to_i : nil
        response[:from_phone]         = sanitized_params.dig(:from_phone).to_s
      when 170
        # 170 send an email
        sanitized_params = params.require(:triggeraction).permit(:bcc_email, :bcc_name, :cc_email, :cc_name, :email_template_id, :email_template_subject, :email_template_yield, :from_email, :from_name, :reply_email, :reply_name, :to_email)

        response[:bcc_email]              = sanitized_params.dig(:bcc_email).to_s
        response[:bcc_name]               = sanitized_params.dig(:bcc_name).to_s
        response[:cc_email]               = sanitized_params.dig(:cc_email).to_s
        response[:cc_name]                = sanitized_params.dig(:cc_name).to_s
        response[:email_template_id]      = sanitized_params.dig(:email_template_id).to_i
        response[:email_template_subject] = sanitized_params.dig(:email_template_subject).to_s.strip.presence
        response[:email_template_yield]   = sanitized_params.dig(:email_template_yield).to_s.strip.presence
        response[:from_name]              = sanitized_params.dig(:from_name).to_s
        response[:from_email]             = sanitized_params.dig(:from_email).to_s
        response[:reply_email]            = sanitized_params.dig(:reply_email).to_s
        response[:reply_name]             = sanitized_params.dig(:reply_name).to_s
        response[:to_email]               = sanitized_params.dig(:to_email).to_s
      when 171
        # 171 send an email to user via Chiirp
        sanitized_params = params.require(:triggeraction).permit(:send_to, :subject, :body)

        response[:send_to] = sanitized_params.dig(:send_to).to_s
        response[:subject] = sanitized_params.dig(:subject).to_s
        response[:body]    = sanitized_params.dig(:body).to_s
      when 180
        # 180 send Slack message
        sanitized_params = params.require(:triggeraction).permit(:slack_channel, :slack_channel_new)
        response[:slack_channel] = sanitized_params.dig(:slack_channel_new).to_s.present? ? sanitized_params.dig(:slack_channel_new).to_s.tr(' ', '_').underscore : sanitized_params.dig(:slack_channel).to_s

        sanitized_params = params.require(:message).permit(:message, :file_attachments)
        response[:text_message] = sanitized_params.dig(:message).to_s
        response[:attachments]  = JSON.parse(sanitized_params.dig(:file_attachments)).map { |f| f.dig('id').to_i }
      when 181
        # 181 create Slack channel
        sanitized_params = params.require(:triggeraction).permit(:slack_channel, :text_message, users: [])

        response[:slack_channel] = sanitized_params.dig(:slack_channel).to_s.tr(' ', '_').underscore
        response[:text_message]  = sanitized_params.dig(:text_message).to_s
        response[:users]         = sanitized_params.dig(:users).to_a.compact_blank
      when 182
        # 182 add Users to Slack channel
        sanitized_params = params.require(:triggeraction).permit(:slack_channel, :slack_channel_new, users: [])

        response[:slack_channel] = sanitized_params.dig(:slack_channel_new).to_s.present? ? sanitized_params.dig(:slack_channel_new).to_s.tr(' ', '_').underscore : sanitized_params.dig(:slack_channel).to_s
        response[:users]         = sanitized_params.dig(:users).to_a.compact_blank
      when 200
        # 200 start a Campaign
        sanitized_params = params.require(:triggeraction).permit(:campaign_id)

        response[:campaign_id] = sanitized_params.dig(:campaign_id).to_i
      when 250, 450
        # 250 start an AI Agent Conversation
        sanitized_params = params.require(:triggeraction).permit(:aiagent_id, :send_to, from_phone: [])

        response[:from_phone] = [sanitized_params.dig(:from_phone)].flatten.compact_blank
        response[:send_to]    = sanitized_params.dig(:send_to).to_s
        response[:aiagent_id] = sanitized_params.dig(:aiagent_id)
      when 300, 305
        # 300 & 305 apply/remove a Tag
        sanitized_params = params.require(:triggeraction).permit(:tag_id)

        response[:tag_id] = sanitized_params.dig(:tag_id).to_i
      when 340, 345
        # 340 & 345 assign to/remove from a Stage
        sanitized_params = params.require(:triggeraction).permit(:stage_id)

        response[:stage_id] = sanitized_params.dig(:stage_id).to_i
      when 350, 355
        # 350 & 355 assign to/remove from a Group
        sanitized_params = params.require(:triggeraction).permit(:group_id)

        response[:group_id] = sanitized_params.dig(:group_id).to_i
      when 360
        # 360 assign a Lead Source
        sanitized_params = params.require(:triggeraction).permit(:lead_source_id)

        response[:lead_source_id] = sanitized_params.dig(:lead_source_id).blank? ? nil : sanitized_params.dig(:lead_source_id).to_i
      when 400
        # 400 stop Campaign(s)
        sanitized_params = params.require(:triggeraction).permit(:campaign_id, :description, :job_estimate_id, :not_this_campaign)

        response[:campaign_id]       = sanitized_params.dig(:campaign_id).to_s
        response[:description]       = sanitized_params.dig(:description).to_s
        response[:job_estimate_id]   = sanitized_params.dig(:job_estimate_id).to_bool
        response[:not_this_campaign] = sanitized_params.dig(:not_this_campaign).to_bool
      when 510
        # 510 assign Contact to User
        sanitized_params = params.require(:triggeraction).permit(assign_to: [], percentages: [], all_users: []).to_h.symbolize_keys

        response[:assign_to] = {}

        if sanitized_params.dig(:assign_to) && sanitized_params.dig(:percentages) && sanitized_params.dig(:all_users)

          sanitized_params[:assign_to].reject(&:empty?).each do |user|
            response[:assign_to][user] = sanitized_params[:percentages][sanitized_params[:all_users].index(user)].to_i if sanitized_params[:percentages][sanitized_params[:all_users].index(user)].to_i.positive?
          end

          response[:assign_to].each do |user, percentage|
            break if response[:assign_to].values.sum == 100

            response[:assign_to][user] = percentage - 1 if response[:assign_to].values.sum > 100
            response[:assign_to][user] = percentage + 1 if response[:assign_to].values.sum < 100
          end
        end

        # format distribution hash
        response[:distribution] = {}

        (sanitized_params.dig(:assign_to).reject(&:empty?) || []).each do |user_id|
          response[:distribution][user_id] = 0
        end
      when 600
        # 600 parse text message response
        sanitized_params = params.require(:triggeraction).permit(:client_custom_field_id, :parse_text_respond, :parse_text_notify, :parse_text_text, :clear_field_on_invalid_response)
        response[:client_custom_field_id]          = sanitized_params.dig(:client_custom_field_id).to_s
        response[:parse_text_respond]              = sanitized_params.dig(:parse_text_respond).to_bool
        response[:parse_text_notify]               = sanitized_params.dig(:parse_text_notify).to_bool
        response[:parse_text_text]                 = sanitized_params.dig(:parse_text_text).to_bool
        response[:clear_field_on_invalid_response] = sanitized_params.dig(:clear_field_on_invalid_response).to_bool

        sanitized_params = params.require(:message).permit(:message, :file_attachments)
        response[:text_message] = sanitized_params.dig(:message).to_s
        response[:attachments]  = JSON.parse(sanitized_params.dig(:file_attachments)).map { |f| f.dig('id').to_i }
      when 605
        # 605 process/act on a Contact custom field
        # TODO: `response_range` needs to set what fields it expects to receieve. Otherwise we are saving anything the client sends us.
        sanitized_params = params.require(:triggeraction).permit(:client_custom_field_id, response_range: {})

        response[:client_custom_field_id] = sanitized_params.dig(:client_custom_field_id).to_i
        response[:response_range]         = sanitized_params.dig(:response_range).to_h

        response[:response_range].each do |key, values|
          if (values.dig('campaign_id').to_i + values.dig('group_id').to_i + values.dig('stage_id').to_i + values.dig('tag_id').to_i).zero? && values.dig('stop_campaign_ids')&.compact_blank.blank?
            response[:response_range].delete(key)
          elsif values.dig('range_type').to_s == 'range' && values.dig('min_max')
            values['minimum']           = values['min_max'].split(';')[0].to_i
            values['maximum']           = values['min_max'].split(';')[1].to_i
            values['campaign_id']       = values['campaign_id'].to_i
            values['group_id']          = values['group_id'].to_i
            values['stage_id']          = values['stage_id'].to_i
            values['tag_id']            = values['tag_id'].to_i
            values['stop_campaign_ids'] = values['stop_campaign_ids']&.compact_blank
            values['stop_campaign_ids'] = [0] if values['stop_campaign_ids']&.include?('0')
            values.delete('min_max')
          else
            values['campaign_id']       = values['campaign_id'].to_i
            values['group_id']          = values['group_id'].to_i
            values['stage_id']          = values['stage_id'].to_i
            values['tag_id']            = values['tag_id'].to_i
            values['stop_campaign_ids'] = values['stop_campaign_ids']&.compact_blank
            values['stop_campaign_ids'] = [0] if values['stop_campaign_ids']&.include?('0')
          end
        end
      when 610
        # 610 save data to a Contact or ContactCustomField
        sanitized_params = params.require(:triggeraction).permit(:client_custom_field_id, :description)

        response[:client_custom_field_id] = sanitized_params.dig(:client_custom_field_id).to_s
        response[:description]            = sanitized_params.dig(:description).to_s
      when 615
        # (615) save Contacts::Note to a Contact
        sanitized_params = params.require(:triggeraction).permit(:note, :user_id)

        response[:note]    = sanitized_params.dig(:note).to_s
        response[:user_id] = sanitized_params.dig(:user_id).to_i
      when 700
        # 700 create a Task
        sanitized_params = params.require(:triggeraction).permit(:name, :assign_to, :from_phone, :description, :campaign_id, :due_delay_days, :due_delay_hours, :due_delay_minutes, :dead_delay_days, :dead_delay_hours, :dead_delay_minutes, :cancel_after)

        response[:name]               = sanitized_params.dig(:name).to_s
        response[:assign_to]          = sanitized_params.dig(:assign_to).to_s
        response[:from_phone]         = sanitized_params.dig(:from_phone).to_s
        response[:description]        = sanitized_params.dig(:description).to_s
        response[:campaign_id]        = sanitized_params.dig(:campaign_id).to_i
        response[:due_delay_days]     = sanitized_params.dig(:due_delay_days).to_i
        response[:due_delay_hours]    = sanitized_params.dig(:due_delay_hours).to_i
        response[:due_delay_minutes]  = sanitized_params.dig(:due_delay_minutes).to_i
        response[:dead_delay_days]    = sanitized_params.dig(:dead_delay_days).to_i
        response[:dead_delay_hours]   = sanitized_params.dig(:dead_delay_hours).to_i
        response[:dead_delay_minutes] = sanitized_params.dig(:dead_delay_minutes).to_i
        response[:cancel_after]       = sanitized_params.dig(:cancel_after).to_i
      when 750
        # 750 call Contact
        sanitized_params = params.require(:triggeraction).permit(:user_id, :send_to, :from_phone, :retry_count, :retry_interval, :stop_on_connection)

        response[:user_id]            = sanitized_params.dig(:user_id).to_s
        response[:send_to]            = sanitized_params.dig(:send_to).to_s
        response[:from_phone]         = sanitized_params.dig(:from_phone).to_s
        response[:retry_count]        = sanitized_params.dig(:retry_count).to_i
        response[:retry_interval]     = sanitized_params.dig(:retry_interval).to_i
        response[:stop_on_connection] = sanitized_params.dig(:stop_on_connection).to_bool
      when 800
        # 800 create a Client
        sanitized_params = params.require(:triggeraction).permit(:client_name_custom_field_id, :client_package_id)

        response[:client_name_custom_field_id] = sanitized_params.dig(:client_name_custom_field_id).to_i
        response[:client_package_id]           = sanitized_params.dig(:client_package_id).to_i
      when 801
        # 801 Push Contact to Client
        sanitized_params = params.require(:triggeraction).permit(clients: {})

        response[:clients] = []

        sanitized_params.dig(:clients).each do |client_id, values|
          this_client = { 'client_id' => client_id.to_i, 'client_campaign_id' => values['client_campaign_id'].to_i, 'agency_campaign_id' => values['agency_campaign_id'].to_i, 'max_monthly_leads' => values['max_monthly_leads'].to_i, 'leads_this_month' => 0, 'period_end_date' => @triggeraction.campaign.client.next_pmt_date.to_time.in_time_zone(@triggeraction.campaign.client.time_zone).utc.iso8601 }

          if (existing_client = @triggeraction.clients.find { |client| client['client_id'] == client_id.to_i })
            this_client['leads_this_month'] = existing_client['leads_this_month']
            this_client['period_end_date']  = existing_client['period_end_date']
          end

          response[:clients] << this_client
        end
      when 901
        # 901 Push data to PC Richard
        sanitized_params = params.require(:triggeraction).permit(:install_method, completed: %i[date notes serial_number], scheduled: %i[date notes])

        response[:install_method] = sanitized_params.dig(:install_method).to_s
        response[:completed] = { date: sanitized_params.dig(:completed, :date).to_i }
        response[:completed][:notes] = sanitized_params.dig(:completed, :notes).to_i
        response[:completed][:serial_number] = sanitized_params.dig(:completed, :serial_number).to_i
        response[:scheduled] = { date: sanitized_params.dig(:scheduled, :date).to_i }
        response[:scheduled][:notes] = sanitized_params.dig(:scheduled, :notes).to_i
      end
    end

    response
  end

  def campaign
    @campaign = @trigger.campaign
  end

  def trigger
    trigger_id = params.permit(:trigger_id).dig(:trigger_id).to_i

    return if trigger_id.positive? && (@trigger = Trigger.find_by(id: trigger_id))

    sweetalert_error('Trigger NOT found!', 'We were not able to access the Trigger you requested.', '', { persistent: 'OK' })

    respond_to do |format|
      format.js { render js: "window.location = '#{root_path}'" and return false }
      format.html { redirect_to root_path and return false }
    end
  end

  def triggeraction
    triggeraction_id = params.permit(:id).dig(:id).to_i

    return if triggeraction_id.positive? && (@triggeraction = Triggeraction.find_by(id: triggeraction_id))

    sweetalert_error('Trigger action NOT found!', 'We were not able to access the Trigger action you requested.', '', { persistent: 'OK' })

    respond_to do |format|
      format.js { render js: "window.location = '#{root_path}'" and return false }
      format.html { redirect_to root_path and return false }
    end
  end
end
