# frozen_string_literal: true

# app/controllers/my_contacts_controller.rb
class MyContactsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user!
  before_action :user_setting
  before_action :update_user_settings, only: %w[create export]
  before_action :broadcast, only: %i[broadcast_action contacts create]
  before_action :page_number, only: %i[broadcast_action contacts]

  # (GET) show action for Message Broadcast
  # /my_contacts/broadcast_action
  # my_contacts_broadcast_action_path
  # my_contacts_broadcast_action_url
  def broadcast_action
    @cards = [params.dig(:broadcast_action).to_s]
  end

  # (GET) show Contacts list
  # /my_contacts/contacts
  # my_contacts_contacts_path
  # my_contacts_contacts_url
  def contacts
    @user_setting.data = Contacts::Search.new.sanitize_params(params:, user: current_user, user_settings: @user_setting)
    @user_setting.save
  end

  # (POST) start group actions on selected Contacts
  # /my_contacts
  # my_contacts_path
  # my_contacts_url
  def create
    start_actions(contact_ids_for_action(@user_setting))
  end

  # (GET) export Contacts as CSV
  # /my_contacts/export
  # my_contacts_export_path
  # my_contacts_export_url
  def export
    contacts = if current_user.team_member? || current_user.agency_user_logged_in_as(session)&.team_member?
                 Contact.where(id: contact_ids_for_action(@user_setting)).includes(:contact_phones)
               else
                 Contact.where(id: contact_ids_for_action(@user_setting)).limit(1000).includes(:contact_phones)
               end

    send_data contacts.as_csv
  end

  # (GET) show My Contacts page
  # /my_contacts
  # my_contacts_path
  # my_contacts_url
  def index
    respond_to do |format|
      format.js { render partial: 'my_contacts/js/show', locals: { cards: %w[index_contacts index_search], broadcast: true } }
      format.html { render 'my_contacts/index', locals: { broadcast: current_user.access_controller?('my_contacts', 'schedule_actions', session) } }
    end
  end

  # (GET/POST) list Group actions
  # /my_contacts/groupactions
  # my_contacts_groupactions_path
  # my_contacts_groupactions_url
  def index_group_actions
    if params.dig(:delete).to_i == 1 && (
      (params.dig(:action_type).to_s == 'action' && params.dig(:action_id).to_s.present?) ||
      (params.dig(:action_type).to_s == 'destroy' && params.dig(:action_ids).to_s.present?)
    )

      case params[:action_type]
      when 'action'
        dj = current_user.delayed_jobs.where(group_process: 1, group_uuid: params[:action_id])
        dj&.destroy_all
      when 'destroy'
        dj = current_user.delayed_jobs.where(group_process: 1, group_uuid: params[:action_ids]&.compact_blank)
        dj&.destroy_all
      end
    end

    if params[:commit] == 'Postpone' && params[:action_ids]&.compact_blank.present?
      postpone = params.require(:postpone).permit(:interval, :period)
      advance = case postpone[:period]
                when 'weeks'
                  postpone[:interval].to_i.weeks
                when 'days'
                  postpone[:interval].to_i.days
                when 'hours'
                  postpone[:interval].to_i.hours
                end

      params[:action_ids].in_groups_of(25, false).each do |uuid_block|
        uuid_block.each do |uuid|
          MyContacts::PostponeJob.perform_later(
            user_id:    current_user.id,
            group_uuid: uuid,
            advance:,
            process:    'reschedule_job'
          )
        end
      end
    end

    @broadcast = true
    @page_number = params.dig(:page).to_i

    respond_to do |format|
      format.turbo_stream
    end
  end

  def index_group_actions_detail
    @action = current_user.delayed_jobs.find_by(id: params[:action_id])
  end

  # (POST)
  # /my_contacts/search
  # my_contacts_search_path
  # my_contacts_search_url
  def search
    render partial: 'my_contacts/js/show', locals: { cards: %w[index_contacts index_search], broadcast: params.dig(:broadcast).to_bool, page_number: params.dig(:page) }
  end

  private

  def all_contacts_allowed?
    current_user.access_controller?('my_contacts', 'all_contacts', session)
  end

  def authorize_user!
    super

    if params.dig(:broadcast).to_bool
      return if current_user.access_controller?('my_contacts', 'schedule_actions', session)
    elsif current_user.access_controller?('my_contacts', 'allowed', session)
      return
    end

    raise ExceptionHandlers::UserNotAuthorized.new('My Contacts', root_path)
  end

  def broadcast
    @broadcast = current_user.access_controller?('my_contacts', 'schedule_actions', session)
  end

  def contact_ids_for_action(user_setting)
    if params.dig(:select_all_switch).to_bool
      # perform group action on all Contacts in search
      Contact.custom_search_query(
        user:                 current_user,
        my_contacts_settings: user_setting,
        broadcast:            true,
        all_pages:            true,
        order:                false
      ).pluck(:id)
    elsif params.dig(:user_action, :contacts).present?
      # perform action on selected Contacts
      params.dig(:user_action, :contacts).to_unsafe_hash.filter_map { |contact_id, selected| contact_id.to_i if selected.to_i.positive? }
    else
      []
    end
  end

  def page_number
    @page_number = params.dig(:page).to_i
  end

  def params_common_args
    sanitized_params = params.require(:common_args).permit(:honor_holidays, :quantity, :quantity_all, :quantity_interval, :quantity_period, :safe_times, :safe_sun, :safe_mon, :safe_tue, :safe_wed, :safe_thu, :safe_fri, :safe_sat)

    response = {}
    response[:common_args] = {
      honor_holidays:    sanitized_params.dig(:honor_holidays).to_bool,
      quantity:          sanitized_params.dig(:quantity).to_i,
      quantity_all:      sanitized_params.dig(:quantity_all).to_bool,
      quantity_interval: sanitized_params.dig(:quantity_interval).to_i,
      quantity_period:   sanitized_params.dig(:quantity_period).to_s,
      safe_start:        sanitized_params.dig(:safe_times).to_s&.split(';')&.map(&:to_i)&.first || 4800,
      safe_end:          sanitized_params.dig(:safe_times).to_s&.split(';')&.map(&:to_i)&.second || 1200,
      safe_sun:          sanitized_params.dig(:safe_sun).to_bool,
      safe_mon:          sanitized_params.dig(:safe_mon).to_bool,
      safe_tue:          sanitized_params.dig(:safe_tue).to_bool,
      safe_wed:          sanitized_params.dig(:safe_wed).to_bool,
      safe_thu:          sanitized_params.dig(:safe_thu).to_bool,
      safe_fri:          sanitized_params.dig(:safe_fri).to_bool,
      safe_sat:          sanitized_params.dig(:safe_sat).to_bool
    }

    response
  end

  def start_actions(contacts)
    if contacts.empty?
      sweetalert_error('Message Broadcast', 'At least 1 Contact must be selected.', '', { persistent: 'Ok' })
      return
    end

    case params.dig(:user_action, :action).to_s
    when 'start_campaign'
      start_actions_start_campaign(contacts)
    when 'stop_campaign'
      start_actions_stop_campaign(contacts)
    when 'contact_awake'
      start_actions_awake(contacts)
    when 'contact_delete'
      start_actions_delete(contacts)
    when 'contact_sleep'
      start_actions_sleep(contacts)
    when 'send_email'
      start_actions_send_email(contacts)
    when 'add_group'
      start_actions_group_add(contacts)
    when 'remove_group'
      start_actions_group_remove(contacts)
    when 'assign_lead_source'
      start_actions_assign_lead_source(contacts)
    when 'ok2text_off'
      start_actions_ok2text_off(contacts)
    when 'ok2text_on'
      start_actions_ok2text_on(contacts)
    when 'send_rvm'
      start_actions_send_rvm(contacts)
    when 'add_stage'
      start_actions_stage_add(contacts)
    when 'remove_stage'
      start_actions_stage_remove(contacts)
    when 'add_tag'
      start_actions_add_tag(contacts)
    when 'remove_tag'
      start_actions_remove_tag(contacts)
    when 'send_text'
      start_actions_send_text(contacts)
    when 'assign_user'
      start_actions_assign_user(contacts)
    when 'export_csv'
      start_actions_export_csv(contacts, fields: params.dig(:export, :fields)&.compact_blank)
    end
  end

  def start_actions_add_tag(contacts)
    sanitized_params = params.require(:user_action).permit(:action, :add_tag_id).merge(params.permit(:user_action_when))
    sanitized_params[:add_tag_id]       = sanitized_params.dig(:add_tag_id).to_i
    sanitized_params[:user_action_when] = sanitized_params.dig(:user_action_when).to_s

    if sanitized_params[:add_tag_id].zero?
      sweetalert_error('Message Broadcast', 'A Tag must be selected.', '', { persistent: 'Ok' })
      return
    end

    sanitized_params = sanitized_params.to_hash.symbolize_keys.merge({ contacts: })

    MyContacts::GroupActionBlockJob.perform_later(
      user_id:       current_user.id,
      process:       'group_add_tag',
      group_process: 1,
      group_uuid:    SecureRandom.uuid,
      data:          sanitized_params,
      run_at:        Time.use_zone(current_user.client.time_zone) { Chronic.parse(sanitized_params[:user_action_when]) }
    )
  end

  def start_actions_assign_lead_source(contacts)
    sanitized_params = params.require(:user_action).permit(:action, :lead_source_id).merge(params.permit(:user_action_when))
    Rails.logger.info "MyContactsController#start_actions_assign_lead_source: #{sanitized_params.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
    sanitized_params[:user_action_when] = sanitized_params.dig(:user_action_when).to_s

    if sanitized_params[:lead_source_id].blank?
      sweetalert_error('Message Broadcast', 'A Lead Source or \"No Lead Source\" must be selected.', '', { persistent: 'Ok' })
      return
    end

    sanitized_params = sanitized_params.to_hash.symbolize_keys.merge({ contacts: })

    MyContacts::GroupActionBlockJob.perform_later(
      user_id:       current_user.id,
      process:       'group_assign_lead_source',
      group_process: 1,
      group_uuid:    SecureRandom.uuid,
      data:          sanitized_params,
      run_at:        Time.use_zone(current_user.client.time_zone) { Chronic.parse(sanitized_params[:user_action_when]) }
    )
  end

  def start_actions_assign_user(contacts)
    sanitized_params = params.require(:user_action).permit(:action, :user_id).merge(params.permit(:user_action_when))
    sanitized_params[:user_id]          = sanitized_params.dig(:user_id).to_i
    sanitized_params[:user_action_when] = sanitized_params.dig(:user_action_when).to_s

    if sanitized_params[:user_id].zero?
      sweetalert_error('Message Broadcast', 'A User must be selected.', '', { persistent: 'Ok' })
      return
    end

    sanitized_params = sanitized_params.to_hash.symbolize_keys.merge({ contacts: })

    MyContacts::GroupActionBlockJob.perform_later(
      user_id:       current_user.id,
      process:       'group_assign_user',
      group_process: 1,
      group_uuid:    SecureRandom.uuid,
      data:          sanitized_params,
      run_at:        Time.use_zone(current_user.client.time_zone) { Chronic.parse(sanitized_params[:user_action_when]) }
    )
  end

  def start_actions_awake(contacts)
    sanitized_params = params.require(:user_action).permit(:action).merge(params.permit(:user_action_when))
    sanitized_params[:user_action_when] = sanitized_params.dig(:user_action_when).to_s

    sanitized_params = sanitized_params.to_hash.symbolize_keys.merge({ contacts: })

    MyContacts::GroupActionBlockJob.perform_later(
      user_id:       current_user.id,
      process:       'group_contact_awake',
      group_process: 1,
      group_uuid:    SecureRandom.uuid,
      data:          sanitized_params,
      run_at:        Time.use_zone(current_user.client.time_zone) { Chronic.parse(sanitized_params[:user_action_when]) }
    )
  end

  def start_actions_delete(contacts)
    sanitized_params = params.require(:user_action).permit(:action).merge(params.permit(:user_action_when))
    sanitized_params[:user_action_when] = sanitized_params.dig(:user_action_when).to_s

    sanitized_params = sanitized_params.to_hash.symbolize_keys.merge({ contacts: })

    MyContacts::GroupActionBlockJob.perform_later(
      user_id:       current_user.id,
      process:       'group_contact_delete',
      group_process: 1,
      group_uuid:    SecureRandom.uuid,
      data:          sanitized_params,
      run_at:        Time.use_zone(current_user.client.time_zone) { Chronic.parse(sanitized_params[:user_action_when]) }
    )
  end

  def start_actions_export_csv(contacts, fields: [])
    if fields.blank?
      sweetalert_error('Message Broadcast', 'At least 1 export field must be selected.', '', { persistent: 'Ok', now: true })
      return
    end

    data = { contacts: }

    Contacts::ExportJob.perform_later(
      user_id:       current_user.id,
      group_process: 1,
      group_uuid:    SecureRandom.uuid,
      data:,
      fields:,
      run_at:        Time.current
    )
  end

  def start_actions_group_add(contacts)
    sanitized_params = params.require(:user_action).permit(:action, :add_group_id).merge(params.permit(:user_action_when))
    sanitized_params[:add_group_id]     = sanitized_params.dig(:add_group_id).to_i
    sanitized_params[:user_action_when] = sanitized_params.dig(:user_action_when).to_s

    if sanitized_params[:add_group_id].zero?
      sweetalert_error('Message Broadcast', 'A Group must be selected.', '', { persistent: 'Ok' })
      return
    end

    sanitized_params = sanitized_params.to_hash.symbolize_keys.merge({ contacts: })

    MyContacts::GroupActionBlockJob.perform_later(
      user_id:       current_user.id,
      process:       'group_add_group',
      group_process: 1,
      group_uuid:    SecureRandom.uuid,
      data:          sanitized_params,
      run_at:        Time.use_zone(current_user.client.time_zone) { Chronic.parse(sanitized_params[:user_action_when]) }
    )
  end

  def start_actions_group_remove(contacts)
    sanitized_params = params.require(:user_action).permit(:action, :remove_group_id).merge(params.permit(:user_action_when))
    sanitized_params[:user_action_when] = sanitized_params.dig(:user_action_when).to_s

    sanitized_params = sanitized_params.to_hash.symbolize_keys.merge({ contacts: })

    MyContacts::GroupActionBlockJob.perform_later(
      user_id:       current_user.id,
      process:       'group_remove_group',
      group_process: 1,
      group_uuid:    SecureRandom.uuid,
      data:          sanitized_params,
      run_at:        Time.use_zone(current_user.client.time_zone) { Chronic.parse(sanitized_params[:user_action_when]) }
    )
  end

  def start_actions_remove_tag(contacts)
    sanitized_params = params.require(:user_action).permit(:action, :remove_tag_id).merge(params.permit(:user_action_when))
    sanitized_params[:remove_tag_id]    = sanitized_params.dig(:remove_tag_id).to_i
    sanitized_params[:user_action_when] = sanitized_params.dig(:user_action_when).to_s

    if sanitized_params[:remove_tag_id].zero?
      sweetalert_error('Message Broadcast', 'A Tag must be selected.', '', { persistent: 'Ok' })
      return
    end

    sanitized_params = sanitized_params.to_hash.symbolize_keys.merge({ contacts: })

    MyContacts::GroupActionBlockJob.perform_later(
      user_id:       current_user.id,
      process:       'group_remove_tag',
      group_process: 1,
      group_uuid:    SecureRandom.uuid,
      data:          sanitized_params,
      run_at:        Time.use_zone(current_user.client.time_zone) { Chronic.parse(sanitized_params[:user_action_when]) }
    )
  end

  def start_actions_send_email(contacts)
    sanitized_params = params.require(:user_action).permit(:action).merge(params.require(:message).permit(:email_template_id, :email_template_subject, :email_template_yield, :payment_request, :file_attachments)).merge(params.permit(:user_action_when)).merge(params_common_args)
    sanitized_params[:file_attachments] = sanitized_params.dig(:file_attachments).present? ? JSON.parse(sanitized_params[:file_attachments]).collect(&:symbolize_keys) : []

    sanitized_params = sanitized_params.to_unsafe_h.symbolize_keys.merge({ contacts: })

    MyContacts::GroupActionBlockJob.perform_later(
      user_id:       current_user.id,
      process:       'group_send_email',
      group_process: 1,
      group_uuid:    SecureRandom.uuid,
      data:          sanitized_params,
      run_at:        Time.use_zone(current_user.client.time_zone) { Chronic.parse(sanitized_params[:user_action_when]) }
    )
  end

  def start_actions_send_rvm(contacts)
    sanitized_params = params.require(:user_action).permit(:action, :voice_recording_id).merge(params.require(:selected_number).permit(:send_rvm, :send_rvm_to)).merge(params.permit(:user_action_when)).merge(params_common_args)
    sanitized_params[:selected_number]               = sanitized_params.dig(:send_rvm).to_s
    sanitized_params[:to_label]                      = sanitized_params.dig(:send_rvm_to).to_s
    sanitized_params[:user]                          = current_user
    sanitized_params[:user_action_when]              = sanitized_params.dig(:user_action_when).to_s
    sanitized_params[:voice_recording_id]            = sanitized_params.dig(:voice_recording_id).to_i.positive? ? sanitized_params.dig(:voice_recording_id).to_i : nil

    if sanitized_params[:voice_recording_id].nil?
      sweetalert_error('Message Broadcast', 'A Voice Recording must be selected.', '', { persistent: 'Ok' })
      return
    end

    sanitized_params = sanitized_params.to_hash.symbolize_keys.merge({ contacts: })

    MyContacts::GroupActionBlockJob.perform_later(
      user_id:       current_user.id,
      process:       'group_send_rvm',
      group_process: 1,
      group_uuid:    SecureRandom.uuid,
      data:          sanitized_params,
      run_at:        Time.use_zone(current_user.client.time_zone) { Chronic.parse(sanitized_params[:user_action_when]) }
    )
  end

  def start_actions_send_text(contacts)
    sanitized_params = params.require(:user_action).permit(:action).merge(params.require(:selected_number).permit(:send_text_to, send_text: [])).merge(params.require(:message).permit(:message, :file_attachments)).merge(params.permit(:user_action_when)).merge(params_common_args)
    sanitized_params[:file_attachments]              = sanitized_params.dig(:file_attachments) ? JSON.parse(sanitized_params[:file_attachments]).collect(&:symbolize_keys) : []
    sanitized_params[:from_phones]                   = [sanitized_params.dig(:send_text) || []].flatten.compact_blank
    sanitized_params[:to_label]                      = sanitized_params.dig(:send_text_to).to_s
    sanitized_params[:user_action_when]              = sanitized_params.dig(:user_action_when).to_s

    if sanitized_params.dig(:message).blank? && sanitized_params[:file_attachments].blank?
      sweetalert_error('Message Broadcast', 'A text message must be entered or attachment selected.', '', { persistent: 'Ok' })
      return
    end

    sanitized_params = sanitized_params.to_unsafe_h.symbolize_keys.merge({ contacts: })

    MyContacts::GroupActionBlockJob.perform_later(
      user_id:       current_user.id,
      process:       'group_send_text',
      group_process: 1,
      group_uuid:    SecureRandom.uuid,
      data:          sanitized_params,
      run_at:        Time.use_zone(current_user.client.time_zone) { Chronic.parse(sanitized_params[:user_action_when]) }
    )
  end

  def start_actions_ok2text_off(contacts)
    sanitized_params = params.require(:user_action).permit(:action).merge(params.permit(:user_action_when))
    sanitized_params[:user_action_when] = sanitized_params.dig(:user_action_when).to_s

    sanitized_params = sanitized_params.to_hash.symbolize_keys.merge({ contacts: })

    MyContacts::GroupActionBlockJob.perform_later(
      user_id:       current_user.id,
      process:       'group_ok2text_off',
      group_process: 1,
      group_uuid:    SecureRandom.uuid,
      data:          sanitized_params,
      run_at:        Time.use_zone(current_user.client.time_zone) { Chronic.parse(sanitized_params[:user_action_when]) }
    )
  end

  def start_actions_ok2text_on(contacts)
    sanitized_params = params.require(:user_action).permit(:action).merge(params.permit(:user_action_when))
    sanitized_params[:user_action_when] = sanitized_params.dig(:user_action_when).to_s

    sanitized_params = sanitized_params.to_hash.symbolize_keys.merge({ contacts: })

    MyContacts::GroupActionBlockJob.perform_later(
      user_id:       current_user.id,
      process:       'group_ok2text_on',
      group_process: 1,
      group_uuid:    SecureRandom.uuid,
      data:          sanitized_params,
      run_at:        Time.use_zone(current_user.client.time_zone) { Chronic.parse(sanitized_params[:user_action_when]) }
    )
  end

  def start_actions_sleep(contacts)
    sanitized_params = params.require(:user_action).permit(:action).merge(params.permit(:user_action_when))
    sanitized_params[:user_action_when] = sanitized_params.dig(:user_action_when).to_s

    sanitized_params = sanitized_params.to_hash.symbolize_keys.merge({ contacts: })

    MyContacts::GroupActionBlockJob.perform_later(
      user_id:       current_user.id,
      process:       'group_contact_sleep',
      group_process: 1,
      group_uuid:    SecureRandom.uuid,
      data:          sanitized_params,
      run_at:        Time.use_zone(current_user.client.time_zone) { Chronic.parse(sanitized_params[:user_action_when]) }
    )
  end

  def start_actions_stage_add(contacts)
    sanitized_params = params.require(:user_action).permit(:action, :add_stage_id).merge(params.permit(:user_action_when))
    sanitized_params[:add_stage_id]     = sanitized_params.dig(:add_stage_id).to_i
    sanitized_params[:user_action_when] = sanitized_params.dig(:user_action_when).to_s

    if sanitized_params[:add_stage_id].zero?
      sweetalert_error('Message Broadcast', 'A Stage must be selected.', '', { persistent: 'Ok' })
      return
    end

    sanitized_params = sanitized_params.to_hash.symbolize_keys.merge({ contacts: })

    MyContacts::GroupActionBlockJob.perform_later(
      user_id:       current_user.id,
      process:       'group_add_stage',
      group_process: 1,
      group_uuid:    SecureRandom.uuid,
      data:          sanitized_params,
      run_at:        Time.use_zone(current_user.client.time_zone) { Chronic.parse(sanitized_params[:user_action_when]) }
    )
  end

  def start_actions_stage_remove(contacts)
    sanitized_params = params.require(:user_action).permit(:action, :remove_stage_id).merge(params.permit(:user_action_when))
    sanitized_params[:remove_stage_id]  = sanitized_params.dig(:remove_stage_id).to_i
    sanitized_params[:user_action_when] = sanitized_params.dig(:user_action_when).to_s

    if sanitized_params[:remove_stage_id].zero?
      sweetalert_error('Message Broadcast', 'A Stage must be selected.', '', { persistent: 'Ok' })
      return
    end

    sanitized_params = sanitized_params.to_hash.symbolize_keys.merge({ contacts: })

    MyContacts::GroupActionBlockJob.perform_later(
      user_id:       current_user.id,
      process:       'group_remove_stage',
      group_process: 1,
      group_uuid:    SecureRandom.uuid,
      data:          sanitized_params,
      run_at:        Time.use_zone(current_user.client.time_zone) { Chronic.parse(sanitized_params[:user_action_when]) }
    )
  end

  def start_actions_start_campaign(contacts)
    sanitized_params = params.require(:user_action).permit(:action, :apply_campaign_id).merge(params.permit(:user_action_when)).merge(params_common_args)
    sanitized_params[:apply_campaign_id]             = sanitized_params.dig(:apply_campaign_id).to_i
    sanitized_params[:user_action_when]              = sanitized_params.dig(:user_action_when).to_s

    if sanitized_params[:apply_campaign_id].zero?
      sweetalert_error('Message Broadcast', 'A Campaign must be selected.', '', { persistent: 'Ok' })
      return
    end

    campaign    = current_user.client.campaigns.find_by(id: sanitized_params[:apply_campaign_id])
    target_time = ''
    run_at      = Time.use_zone(current_user.client.time_zone) { Chronic.parse(sanitized_params[:user_action_when]) }

    if campaign && (trigger = campaign.triggers.order(:step_numb).first) && trigger.trigger_type == 125
      target_time = Time.use_zone(current_user.client.time_zone) { Chronic.parse(sanitized_params[:user_action_when]) }
      run_at      = Time.current
    end

    sanitized_params = sanitized_params.to_hash.symbolize_keys.merge({ target_time:, contacts: })

    MyContacts::GroupActionBlockJob.perform_later(
      user_id:       current_user.id,
      process:       'group_start_campaign',
      group_process: 1,
      group_uuid:    SecureRandom.uuid,
      data:          sanitized_params,
      run_at:
    )
  end

  def start_actions_stop_campaign(contacts)
    sanitized_params = params.require(:user_action).permit(:action, :stop_campaign_id).merge(params.permit(:user_action_when))

    if sanitized_params.dig(:stop_campaign_id).to_i.zero? && !sanitized_params.dig(:stop_campaign_id).to_s.casecmp?('all') && !sanitized_params.dig(:stop_campaign_id).to_s.start_with?('group_')
      sweetalert_error('Message Broadcast', 'A Campaign must be selected.', '', { persistent: 'Ok' })
      return
    end

    sanitized_params = sanitized_params.to_hash.symbolize_keys.merge({ contacts: })

    MyContacts::GroupActionBlockJob.perform_later(
      user_id:       current_user.id,
      process:       'group_stop_campaign',
      group_process: 1,
      group_uuid:    SecureRandom.uuid,
      data:          sanitized_params,
      run_at:        Time.use_zone(current_user.client.time_zone) { Chronic.parse(sanitized_params[:user_action_when]) }
    )
  end

  def update_user_settings
    # save Users::Setting id in Session
    session[:contacts_search] = @user_setting.id unless @user_setting.new_record?

    # per_page setting (maximum = 200)
    if params.include?(:per_page)
      @user_setting.data[:per_page] = [params[:per_page].to_i, 200].min
    elsif Array(0..200).exclude?(@user_setting.data[:per_page].to_i)
      @user_setting.data[:per_page] = 25
    end

    @user_setting.save
  end

  def user_setting
    if %w[client user].include?(params.dig(:leads).to_s.downcase)
      # User clicked a Dashboard button
      @user_setting      = current_user.user_settings.find_or_initialize_by(controller_action: 'contacts_search', name: 'Last Used')
      @user_setting.data = Contacts::Search.new.configure_user_settings_data_from_dashboard_button(params:, user: current_user, user_settings_dashboard_button_id: params.permit(:user_setting_id)&.dig(:user_setting_id).to_i)
    elsif params.dig(:saved_search).to_i.positive? && (@user_setting = current_user.user_settings.find_by(id: params[:saved_search].to_i, controller_action: 'contacts_search'))
      # User selected a saved search

    elsif params.dig(:commit).to_s.casecmp?('search')
      # User clicked Search button
      @user_setting      = current_user.user_settings.find_or_initialize_by(controller_action: 'contacts_search', name: 'Last Used')
      @user_setting.data = Contacts::Search.new.sanitize_params(params:, user: current_user, user_settings: @user_setting)
    elsif params.dig(:commit).to_s.casecmp?('save & search')
      # User clicked Save & Search button
      new_name           = (params.permit(:search_name).dig(:search_name).presence || 'Last Used').to_s
      @user_setting      = current_user.user_settings.find_or_initialize_by(controller_action: 'contacts_search', name: new_name)
      @user_setting.data = Contacts::Search.new.sanitize_params(params:, user: current_user, user_settings: @user_setting)
    elsif params.dig(:commit).to_s.casecmp?('delete saved search') && params.dig(:id).to_i.positive? && (@user_setting = current_user.user_settings.find_by(id: params[:id].to_i, controller_action: 'contacts_search'))
      # User clicked Delete Saved Search button
      @user_setting.destroy

      @user_setting      = current_user.user_settings.find_or_initialize_by(controller_action: 'contacts_search', name: 'Last Used')
      @user_setting.data = current_user.user_settings.new(controller_action: 'contacts_search').data.merge(@user_setting.data)
    elsif params.dig(:commit).to_s.casecmp?('clear all filters')
      # User clicked Clear All Filters button
      @user_setting                      = current_user.user_settings.find_or_initialize_by(controller_action: 'contacts_search', name: 'Last Used')
      show_user_ids                      = @user_setting.data.dig(:show_user_ids)
      @user_setting.data                 = current_user.user_settings.new(controller_action: 'contacts_search').data
      @user_setting.data[:show_user_ids] = show_user_ids
    elsif session.dig(:contacts_search).to_i.positive?
      # session Users::Setting id was found
      @user_setting      = current_user.controller_action_settings('contacts_search', session.dig(:contacts_search).to_i)
      @user_setting.data = current_user.user_settings.new(controller_action: 'contacts_search').data.merge(@user_setting.data)
    else
      # find or create a 'Last Used' Users::Setting
      @user_setting      = current_user.user_settings.find_or_initialize_by(controller_action: 'contacts_search', name: 'Last Used')
      @user_setting.data = current_user.user_settings.new(controller_action: 'contacts_search').data.merge(@user_setting.data)
    end

    # save Users::Setting
    @user_setting.current = 1
    # @user_setting.data[:show_user_ids] = (all_contacts_allowed? ? ["all_#{current_user.client_id}"] : [current_user.id]) if params.dig(:broadcast).to_bool && (all_contacts_allowed? ? !current_user.client.users.pluck(:id).intersect?(@user_setting.data[:show_user_ids]) : @user_setting.data[:show_user_ids].exclude?(current_user.id))
    @user_setting.data[:show_user_ids] = [current_user.id] if @user_setting.data[:show_user_ids].blank?
    @user_setting.save

    # save Users::Setting id in Session
    session[:contacts_search] = @user_setting.id
  end
end
