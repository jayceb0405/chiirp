# frozen_string_literal: true

# app/controllers/central_controller.rb
class CentralController < ApplicationController
  before_action :login_mobile, only: %i[index]
  before_action :authenticate_user!
  before_action :authorize_user!
  before_action :contact, only: %i[call_contact contact_options contact_profile conversation index_aiagent_sessions index_campaigns index_tags index_tasks stop_aiagent toggle_ok_2_email toggle_ok_2_text update_message_meta]
  before_action :message, only: %i[mark_as_unread message_dropdown]

  # (POST)
  # /central/call_contact/:contact_id
  # central_call_contact_path(:contact_id)
  # central_call_contact_url(:contact_id)
  def call_contact
    sanitized_params = params.permit(:from_phone, :to_phone, :user_id)
    user             = @contact.client.users.find_by(id: sanitized_params.dig(:user_id) || current_user.id)
    from_phone       = (sanitized_params.dig(:from_phone) || user&.default_from_twnumber&.phonenumber).to_s
    to_phone         = (sanitized_params.dig(:to_phone) || @contact.primary_phone&.phone).to_s

    if from_phone.present?
      # Connect an outbound call to Contact & User
      result = @contact.call(users_orgs: "user_#{current_user.id}", from_phone:, contact_phone: to_phone)

      if result[:success]
        render json: { message: 'Phone call connected.', status: 'ok' }
      else
        render json: { message: "Phone call could NOT be connected. #{result[:error_message]}", status: 'fail' }
      end
    else
      render json: { message: 'Phone call could NOT be connected. Your phone number is empty.', status: 'fail' }
    end
  end

  # (GET) display Contact options menu on Message Central
  # /central/contact_options/:contact_id
  # central_contact_options_path(:contact_id)
  # central_contact_options_url(:contact_id)
  def contact_options
    render partial: 'central/js/show', locals: { cards: %w[contact_options_menu] }
  end

  # (GET)
  # /central/contact_profile/:contact_id
  # central_contact_profile_path(:contact_id)
  # central_contact_profile_url(:contact_id)
  def contact_profile
    render partial: 'central/js/show', locals: { cards: %w[contact_profile] }
  end

  # (GET) show a conversation in Message Central
  # /central/conversation/:contact_id
  # central_conversation_path(:contact_id)
  # central_conversation_url(:contact_id)
  def conversation
    @contact.clear_unread_messages(current_user)

    sanitized_params = params.permit(:active_tab, :page, :per_page, :phone_number, show_user_ids: [])

    user_settings                      = current_user.user_settings.find_or_initialize_by(controller_action: 'message_central')
    user_settings_data                 = user_settings.data.dup
    user_settings.data[:page]          = [(sanitized_params.dig(:page).presence || user_settings.data.dig(:page).presence).to_i, 1].max
    user_settings.data[:per_page]      = (sanitized_params.dig(:per_page).presence || user_settings.data.dig(:per_page).presence || 25).to_i
    user_settings.data[:phone_number]  = (sanitized_params.dig(:phone_number).presence || @contact.latest_client_phonenumber(current_session: @session, default_ok: true, phone_numbers_only: true)&.phonenumber).to_s
    user_settings.data[:show_user_ids] = [sanitized_params.dig(:show_user_ids) || user_settings.data.dig(:show_user_ids) || current_user.id].flatten.compact_blank.uniq
    user_settings.save

    cards  = %w[conversation]
    cards << 'active_contacts' if user_settings.data[:page] != user_settings_data.dig(:page) || user_settings.data[:per_page] != user_settings_data.dig(:per_page)
    cards << 'active_contacts_only' if user_settings.data[:show_user_ids] != user_settings_data.dig(:show_user_ids)

    render partial: 'central/js/show', locals: { cards:, active_tab: sanitized_params.dig(:active_tab).to_s }
  end

  # (GET) show full size image
  # /central/fsimage/:contact_attachment_id
  # central_full_size_image_path(:contact_attachment_id)
  # central_full_size_image_url(:contact_attachment_id)
  def full_size_image
    @contact_attachment = ContactAttachment.find_by(id: params.dig(:contact_attachment_id).to_i)

    respond_to do |format|
      format.html { render 'central/conversation/full_size_image', layout: 'full_size_image' }
      format.js   { render js: "window.location = '#{root_path}'" }
    end
  end

  # (GET) show Message Central
  # /central
  # central_path
  # central_url
  def index
    if params.dig(:contact_id).to_i.positive?
      if (@contact = self.contact_for_client_and_accounts(params.dig(:contact_id), current_user.client_id))
        @contact.clear_unread_messages(current_user)
        user_settings                     = current_user.user_settings.find_or_initialize_by(controller_action: 'message_central')
        user_settings.data[:phone_number] = @contact.latest_client_phonenumber(current_session: @session, default_ok: true, phone_numbers_only: true)&.phonenumber.to_s
        user_settings.save
      else
        @contact = current_user.client.contacts.new
      end
    end

    respond_to do |format|
      format.html { render 'central/index', locals: { active_tab: params.dig(:active_tab).to_s } }
      format.js   { render js: "window.location = '#{root_path}'" }
    end
  end

  # (GET) display Active Contacts list
  # /central/active_contacts
  # central_active_contacts_path
  # central_active_contacts_url
  def index_active_contacts
    user_settings = current_user.user_settings.find_or_initialize_by(controller_action: 'message_central')
    user_settings.data[:active_contacts_group_id] = params[:active_contacts_group_id].to_i if params.include?(:active_contacts_group_id)
    user_settings.data[:active_contacts_paused]   = params[:active_contacts_paused].to_bool if params.include?(:active_contacts_paused)
    user_settings.data[:active_contacts_period]   = params[:active_contacts_period].to_i if params.include?(:active_contacts_period)
    user_settings.data[:include_automated]        = params[:include_automated].to_bool if params.include?(:include_automated)
    user_settings.data[:include_sleeping]         = params[:include_sleeping].to_bool if params.include?(:include_sleeping)
    user_settings.data[:msg_types]              ||= []
    user_settings.data[:msg_types]                = params[:include_email].to_bool ? user_settings.data[:msg_types] | ['email'] : user_settings.data[:msg_types] - ['email'] if params.include?(:include_email)
    user_settings.data[:msg_types]                = params[:include_fb].to_bool ? user_settings.data[:msg_types] | ['fb'] : user_settings.data[:msg_types] - ['fb'] if params.include?(:include_fb)
    user_settings.data[:msg_types]                = params[:include_ggl].to_bool ? user_settings.data[:msg_types] | ['ggl'] : user_settings.data[:msg_types] - ['ggl'] if params.include?(:include_ggl)
    user_settings.data[:msg_types]                = params[:include_rvm].to_bool ? user_settings.data[:msg_types] | ['rvm'] : user_settings.data[:msg_types] - ['rvm'] if params.include?(:include_rvm)
    user_settings.data[:msg_types]                = params[:include_text].to_bool ? user_settings.data[:msg_types] | ['text'] : user_settings.data[:msg_types] - ['text'] if params.include?(:include_text)
    user_settings.data[:msg_types]                = params[:include_video].to_bool ? user_settings.data[:msg_types] | ['video'] : user_settings.data[:msg_types] - ['video'] if params.include?(:include_video)
    user_settings.data[:msg_types]                = params[:include_voice].to_bool ? user_settings.data[:msg_types] | ['voice'] : user_settings.data[:msg_types] - ['voice'] if params.include?(:include_voice)
    user_settings.data[:msg_types]                = params[:include_widget].to_bool ? user_settings.data[:msg_types] | ['widget'] : user_settings.data[:msg_types] - ['widget'] if params.include?(:include_widget)
    user_settings.data[:msg_types]                = %w[text] if user_settings.data[:msg_types].blank?
    user_settings.save

    render partial: 'central/js/show', locals: { cards: %w[active_contacts] }
  end

  # (GET)
  # /central/:contact_id/aiagent_sessions
  # central_aiagent_sessions_path(:contact_id)
  # central_aiagent_sessions_url(:contact_id)
  def index_aiagent_sessions
    render partial: 'central/js/show', locals: { cards: %w[index_aiagent_sessions] }
  end

  # (GET)
  # /central/:contact_id/campaigns
  # central_campaigns_path(:contact_id)
  # central_campaigns_url(:contact_id)
  def index_campaigns
    render partial: 'central/js/show', locals: { cards: %w[index_campaigns] }
  end

  # (GET)
  # /central/:contact_id/tags
  # central_tags_path(:contact_id)
  # central_tags_url(:contact_id)
  def index_tags
    render partial: 'central/js/show', locals: { cards: %w[tags] }
  end

  # (GET)
  # /central/:contact_id/tasks
  # central_tasks_path(:contact_id)
  # central_tasks_url(:contact_id)
  def index_tasks
    render partial: 'central/js/show', locals: { cards: %w[index_tasks], contact: @contact }
  end

  # (POST) mark a message as unread
  # /central/markasunread/:message_id
  # central_mark_as_unread_path(:message_id)
  # central_mark_as_unread_url(:message_id)
  def mark_as_unread
    @message.mark_as_unread

    Messages::UpdateUnreadMessageIndicatorsJob.perform_later(user_id: @message.contact.user_id)

    @contact = @message.contact
    send(:remove_instance_variable, :@message)

    render partial: 'central/js/show', locals: { cards: %w[conversation active_contacts] }
  end

  # (GET) show message dropdown
  # /central/messagedropdown/:message_id
  # central_dropdown_path(:message_id)
  # central_dropdown_url(:message_id)
  def message_dropdown
    @contact = @message.contact

    render partial: 'central/js/show', locals: { cards: %w[message_dropdown] }
  end

  # (DELETE) stop all aiagents running for a contact
  # /central/:contact_id/stop_aiagents
  # central_stop_aiagent_path(:contact_id)
  # central_stop_aiagent_url(:contact_id)
  def stop_aiagent
    @contact&.stop_aiagents

    render partial: 'central/js/show', locals: { cards: %w[remove_stop_aiagent] }
  end

  # app/controllers/contacts_controller.rb
  # /central/:contact_id/toggleok2email
  # central_toggle_ok_2_email_path(:contact_id)
  # central_toggle_ok_2_email_url(:contact_id)
  def toggle_ok_2_email
    @contact.update(ok2email: (@contact.ok2email.to_i.zero? ? 1 : 0))

    render partial: 'central/js/show', locals: { cards: %w[conversation] }
  end

  # app/controllers/contacts_controller.rb
  # /central/:contact_id/toggleok2text
  # central_toggle_ok_2_text_path(:contact_id)
  # central_toggle_ok_2_text_url(:contact_id)
  def toggle_ok_2_text
    @contact.update(ok2text: (@contact.ok2text.to_i.zero? ? 1 : 0))

    render partial: 'central/js/show', locals: { cards: %w[conversation] }
  end

  # (PATCH) update all User's Active Contacts to notify of User typing
  # /central/update_message_meta
  # central_update_message_meta_path
  # central_update_message_meta_url
  def update_message_meta
    focus = params.permit(:focus).dig(:focus).to_s

    Contacts::RedisPool.new(@contact.id).user_id_typing = if focus == 'on'
                                                            current_user.id
                                                          else
                                                            0
                                                          end

    CableBroadcaster.new.active_contacts_typing(@contact, current_user, focus)

    render js: '', layout: false, status: :ok
  end

  private

  def authorize_user!
    super
    return if current_user&.access_controller?('central', 'allowed', session)

    raise ExceptionHandlers::UserNotAuthorized.new('Message Central', root_path)
  end

  def login_mobile
    email      = params.dig(:email).to_s.tr(' ', '+')
    password   = params.dig(:password).to_s
    push_token = params.dig(:push_token).to_s
    user_token = params.dig(:token).to_s
    approved   = true

    if email.present? && user_token.present? && (user = User.find_for_authentication(email:)) && user.valid_password?(Base64.decode64(user_token).gsub(email, ''))
      Rails.logger.info "CentralController#login_mobile: (signed_in_with_email_and_token) - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
      sign_out current_user if current_user&.id != user.id
      sign_in user
    elsif push_token.present? && (user = UserPush.where(target: 'mobile').find_by('data @> ?', { mobile_key: "ExponentPushToken[#{push_token}]" }.to_json)&.user)
      # login User on mobile using push token
      Rails.logger.info "CentralController#login_mobile: (signed_in_with_push_token) - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
      sign_out current_user if current_user&.id != user.id
      sign_in user
    elsif email.present? && password.present? && (user = User.find_for_authentication(email:)) && user.valid_password?(password)
      # legacy method to login User on mobile
      Rails.logger.info "CentralController#login_mobile: (signed_in_with_email_and_password) - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
      sign_out current_user if current_user&.id != user.id
      sign_in user
    elsif email.present? && password.present? && User.find_for_authentication(email:).nil?
      Rails.logger.info "CentralController#login_mobile: (email_not_found) #{{ user_agent: request.user_agent }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
      approved = false
    elsif email.present? && password.present? && (user = User.find_for_authentication(email:)) && !user.valid_password?(password)
      Rails.logger.info "CentralController#login_mobile: (password_not_valid) #{{ user_agent: request.user_agent }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
      approved = false
    elsif current_user
      Rails.logger.info "CentralController#login_mobile: (current_user_is_set) - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
    else
      Rails.logger.info "CentralController#login_mobile: (email_token_or_password_not_received) #{{ user_agent: request.user_agent }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
      approved = false
    end

    return if approved

    # couldn't login User on mobile / save push token to cookies
    cookies[:push_token] = push_token if push_token.present? && browser.device.mobile?

    respond_to do |format|
      format.js   { render js: "window.location = '#{login_path}'" and return false }
      format.html { redirect_to login_path and return false }
    end
  end

  def contact
    return if params.dig(:contact_id).to_i.zero? && (@contact = current_user&.contacts&.new)
    return if (@contact = self.contact_for_client_and_accounts(params.dig(:contact_id), current_user.client_id))

    sweetalert_error('Unathorized Access!', 'Unable to access Contact.', '', { persistent: 'OK' })

    respond_to do |format|
      format.js { render js: "window.location = '#{root_path}'" and return false }
      format.html { redirect_to root_path and return false }
    end
  end

  def contact_for_client_and_accounts(contact_id, client_id)
    Contact.find_by(id: contact_id, client_id: Client.agency_accounts(client_id).pluck(:id) << client_id)
  end

  def message
    message_id = params.dig(:message_id).to_i

    return if message_id.positive? && (@message = Messages::Message.find_by(id: message_id))

    render js: "window.location = '#{root_path}'" and return false
  end
end
