# frozen_string_literal: true

# app/presenters/central_presenter.rb
class CentralPresenter < BasePresenter
  attr_accessor :contacts_array, :file_attachments, :show_msg_delay, :show_ok2text, :show_payment_request, :show_phone_call, :show_submit, :show_voicemail
  attr_reader :message, :session

  def initialize(args = {})
    super
    self.session = args.dig(:session)

    @current_phone_number  = nil
    @message               = nil
    @folder_assignments    = nil
  end

  def active_contacts_group_selected?
    self.user_settings.data.dig(:active_contacts_group_id).to_i.positive?
  end

  def active_contacts_group_string
    @client.groups.find_by(id: (self.user_settings.data.dig(:active_contacts_group_id) || 0).to_i)&.name || 'All Groups'
  end

  def active_contacts_list
    @active_contacts_list || self.message_central_settings
  end

  def active_contacts_paused?
    self.user_settings.data.dig(:active_contacts_paused).to_bool
  end

  def active_contacts_period
    (self.user_settings.data.dig(:active_contacts_period) || 15).to_i
  end

  def active_contacts_period_string
    case self.active_contacts_period
    when 1
      'Today'
    when 2
      'Yesterday & Today'
    when 7
      'Past Week'
    when 15
      'Past 15 Days'
    when 30
      'Past 30 Days'
    end
  end

  def client=(client)
    super

    @client_api_integration_ggl  = nil
    @client_transactions         = nil
    @sunbasedata_api_integration = nil
    @user_api_integration_fb     = nil
    @users_phones                = nil
  end

  def client_api_integration_ggl
    @client_api_integration_ggl ||= @client.client_api_integrations.find_by(target: 'google', name: '')
  end

  def client_transactions
    @client_transactions ||= ClientTransaction.where(client_id: @client.id).where('data @> ?', { contact_id: @contact.id }.to_json).pluck(:data, :setting_value)
  end

  def color_key_text
    'Conversation Color Key' \
      '<div class="pl-3 pr-3 pt-2 pb-2 m-0 mt-2 bg-white text-left text-muted rounded">' \
      '<span class="badge badge-pill color_is_textin">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span> Incoming Texts<br />' \
      '<span class="badge badge-pill color_is_textout">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span> Outbound Texts<br />' \
      '<span class="badge badge-pill color_is_textout_automated">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span> Outbound Texts (Automated)<br />' \
      '<span class="badge badge-pill color_is_textinuser">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span> Incoming Texts From Users<br />' \
      '<span class="badge badge-pill color_is_textoutuser">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span> Outbound Texts To Users<br />' \
      '<span class="badge badge-pill color_is_textoutaiagent">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span> Outbound Texts From AI Agents<br />' \
      '<span class="badge badge-pill color_is_textinother">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span> Incoming Texts (other)<br />' \
      '<span class="badge badge-pill color_is_textoutother">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span> Outbound Texts (other)<br />' \
      '<span class="badge badge-pill color_is_fbin">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span> Incoming FB Messages<br />' \
      '<span class="badge badge-pill color_is_fbout">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span> Outbound FB Messages<br />' \
      '<span class="badge badge-pill color_is_fbout_automated">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span> Outbound FB Messages (Automated)<br />' \
      '<span class="badge badge-pill color_is_gglin">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span> Incoming GGL Messages<br />' \
      '<span class="badge badge-pill color_is_gglout">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span> Outbound GGL Messages<br />' \
      '<span class="badge badge-pill color_is_gglout_automated">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span> Outbound GGL Messages (Automated)<br />' \
      '<span class="badge badge-pill color_is_emailout">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span> Outbound Emails<br />' \
      '<span class="badge badge-pill color_is_emailin">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span> Inbound Emails<br />' \
      '<span class="badge badge-pill color_is_rvmout">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span> Outbound RVMs<br />' \
      '<span class="badge badge-pill color_is_voicein">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span> Incoming Calls<br />' \
      '<span class="badge badge-pill color_is_voiceout">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span> Outbound Calls<br />' \
      '<span class="badge badge-pill color_is_voicemail">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span> Incoming Voicemails<br />' \
      '<span class="badge badge-pill color_is_widgetin">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span> SiteChat Entries<br />' \
      '<span class="badge badge-pill color_is_video">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span> Video Conversations<br />' \
      '<span class="badge badge-pill color_is_unknown">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span> Other' \
      '</div>'
  end

  def contact=(contact)
    super
    @client_transactions                  = nil
    @contact_campaigns_count              = nil
    @contact_servicetitan_ext_reference   = nil
    @contact_lead_source_name             = nil
    @contact_message_thread               = nil
    @contact_notes_count                  = nil
    @contact_scheduled_action_count       = nil
    @contact_tasks_count                  = nil
    @folders                              = nil
    @housecallpro_contact_api_integration = nil
    @maestro_contact_api_integration      = nil
    @pcrichard_contact_api_integration    = nil
    @servicetitan_contact_api_integration = nil
    @user_typing                          = nil
    @xencall_contact_api_integration      = nil
  end

  def contact_address_formatted
    response = []
    response << @contact.address1 if @contact.address1.present?
    response << @contact.address2 if @contact.address2.present?
    response << "#{@contact.city}, #{@contact.state} #{@contact.zipcode}" if @contact.city.present? || @contact.state.present? || @contact.zipcode.present?

    @contact.contact_phones.pluck(:label, :phone).each do |phone|
      response << "#{phone[0].titleize}: #{ActionController::Base.helpers.number_to_phone(phone[1])}"
    end

    ActionController::Base.helpers.sanitize(response.join('<br />'), tags: %w[br])
  end

  def contact_campaigns_count
    @contact_campaigns_count ||= (@contact.contact_campaigns.count + @contact.delayed_jobs.where(process: 'start_campaign').count)
  end

  def contact_created_at_formatted
    Friendly.new.date(@contact.created_at, @client.time_zone, true)
  end

  def contact_lead_source_name
    @contact_lead_source_name ||= @contact.lead_source&.name || ' Unassigned'
  end

  def contact_message_thread
    @contact_message_thread ||= Messages::Message.contact_message_thread(contact: @contact, current_phone_number: self.current_phone_number)
  end

  def contact_notes_count
    @contact_notes_count ||= @contact.notes.count
  end

  def contact_scheduled_action_count
    @contact_scheduled_action_count ||= @contact.scheduled_actions.count
  end

  def contact_tasks_count
    @contact_tasks_count ||= Task.incomplete_by_contact(@contact.id).count
  end

  def current_email_address
    @contact.email
  end

  def contact_servicetitan_ext_reference
    @contact_servicetitan_ext_reference ||= @contact.ext_references.find_by(target: 'servicetitan')
  end

  def contact_servicetitan_ext_reference_id
    self.contact_servicetitan_ext_reference&.ext_id || ''
  end

  def current_phone_number
    @current_phone_number ||= self.user_settings.data.dig(:phone_number) || @contact.latest_client_phonenumber(current_session: @session, default_ok: true, phone_numbers_only: true)&.phonenumber.to_s
  end

  def facebook_meta_data
    %w[fbin].include?(@message.msg_type) && (page = self.facebook_page).present? ? "(#{page})" : ''
  end

  def facebook_page
    self.user_api_integration_fb&.pages&.find { |p| p.dig('id') == @message.account_sid.to_s }&.dig('name').to_s
  end

  def fieldset_disabled?
    self.current_phone_number.blank? || (@contact.ok2text.to_i.zero? && @contacts_array.blank?)
  end

  def folder_assignments
    @folder_assignments ||= @message.folder_assignments.pluck(:folder_id)
  end

  def folders
    @folders ||= Folder.where(client_id: @client.id, active: true, id: @contact.folders).order(name: :asc)
  end

  def from_phone_meta_data
    %w[textin textinuser textinother voicein voicemail].include?(@message.msg_type) ? ActionController::Base.helpers.number_to_phone(@message.from_phone) : ''
  end

  def google_location
    self.client_api_integration_ggl&.active_locations_names&.dig(self.message.account_sid).to_s.presence || self.message.account_sid.gsub('locations/', '')
  end

  def google_meta_data
    %w[gglin].include?(@message.msg_type) && (location = self.google_location).present? ? "(#{location})" : ''
  end

  def housecallpro_contact_api_integration
    @housecallpro_contact_api_integration ||= self.integration_allowed?('housecallpro') ? @contact.contact_api_integrations.find_by(target: 'housecallpro', name: '') : nil
  end

  def include_automated?
    self.user_settings.data.dig(:include_automated).to_bool
  end

  def include_email?
    self.user_settings.data.dig(:msg_types)&.blank? || self.user_settings.data.dig(:msg_types)&.include?('email')
  end

  def include_fb?
    self.user_settings.data.dig(:msg_types)&.blank? || self.user_settings.data.dig(:msg_types)&.include?('fb')
  end

  def include_ggl?
    self.user_settings.data.dig(:msg_types)&.blank? || self.user_settings.data.dig(:msg_types)&.include?('ggl')
  end

  def include_rvm?
    self.user_settings.data.dig(:msg_types)&.blank? || self.user_settings.data.dig(:msg_types)&.include?('rvm')
  end

  def include_sleeping?
    self.user_settings.data.dig(:include_sleeping).to_bool
  end

  def include_text?
    self.user_settings.data.dig(:msg_types)&.blank? || self.user_settings.data.dig(:msg_types)&.include?('text')
  end

  def include_video?
    self.user_settings.data.dig(:msg_types)&.blank? || self.user_settings.data.dig(:msg_types)&.include?('video')
  end

  def include_voice?
    self.user_settings.data.dig(:msg_types)&.blank? || self.user_settings.data.dig(:msg_types)&.include?('voice')
  end

  def include_widget?
    self.user_settings.data.dig(:msg_types)&.blank? || self.user_settings.data.dig(:msg_types)&.include?('widget')
  end

  def integration_allowed?(integration)
    @client.integrations_allowed.include?(integration)
  end

  def maestro_contact_api_integration
    @maestro_contact_api_integration ||= self.integration_allowed?('maestro') ? @contact.contact_api_integrations.find_by(target: 'maestro') : nil
  end

  def message=(message)
    @message = case message
               when Messages::Message
                 message
               when Integer
                 Messages::Message.find_by(id: message)
               else

                 if @contact.is_a?(Contact)
                   @contact.messages.new
                 else
                   Messages::Message.new
                 end
               end

    @folder_assignments = nil
  end

  def message_agent_info
    case @message.msg_type
    when 'textinuser', 'textinother'
      "(From: #{self.users_phones.dig(@message.from_phone) || ActionController::Base.helpers.number_to_phone(@message.from_phone)})"
    when 'textoutuser', 'textoutother'
      "(To: #{self.users_phones.dig(@message.to_phone) || ActionController::Base.helpers.number_to_phone(@message.to_phone)})"
    when 'aiagentstatus', 'emailout', 'emailin', 'fbin', 'fbout', 'gglin', 'gglout', 'payment', 'rvmout', 'textin', 'textout', 'textoutaiagent', 'voicein', 'voiceout', 'voicemail', 'widgetin', 'video'
      ''
    else
      sanitize("(From: #{self.users_phones.dig(@message.from_phone) || ActionController::Base.helpers.number_to_phone(@message.from_phone)})<br />(To: #{self.users_phones.dig(message.to_phone) || ActionController::Base.helpers.number_to_phone(@message.to_phone)})", tags: %w[br])
    end
  end

  def message_central_settings
    @user_settings, @active_contacts_list = @user.message_central_settings
    @clients = Client.where(id: @active_contacts_list.pluck(:client_id))
    @users   = User.where(id: @active_contacts_list.pluck(:user_id))
    @active_contacts_list
  end

  def message_color_class
    ApplicationController.helpers.message_color_class(@message.msg_type, @message.automated, @message.aiagent_session_id.present?)
  end

  def message_cost_in_credits
    message_cost = self.client_transactions.find { |d| d[0]['message_id'] == @message.id }&.last
    message_cost ? ActionController::Base.helpers.number_to_currency(message_cost.to_d, unit: '', format: '%n credits', precision: 2) : 'n/a'
  end

  def message_direction
    %w[emailin fbin gglin textin textinuser textinother voicein widgetin].include?(@message.msg_type) ? 'inbound' : 'outbound'
  end

  def message_display(message_id, message_content, message_type)
    if message_content.present?
      # rubocop:disable Rails/OutputSafety
      "<i class=\"#{Messages::Message.message_icon(message_type)}\"></i> #{ApplicationController.helpers.truncate(ApplicationController.helpers.strip_tags(message_content), length: 62)}".html_safe
      # rubocop:enable Rails/OutputSafety
    elsif (message = Messages::Message.find_by(id: message_id)) && message&.attachments.present?
      'Image'
    else
      'No messages.'
    end
  end

  def message_divider
    response  = '<li class="log-divider">'

    response += case @message.msg_type
                when 'aiagentstatus'
                  "<span><i class=\"fa fa-robot\"></i> #{@message.message} #{@message.status.present? ? "(#{@message.status.titleize.downcase})" : ''} #{Friendly.new.date(@message.created_at, @client.time_zone, true, true)} </span>"
                when 'review'
                  "<span><i class=\"fa fa-thumbs-up\"></i> #{@message.message} #{Friendly.new.date(@message.created_at, @client.time_zone, true, true)} </span>"
                when 'payment'
                  "<span><i class=\"fa fa-credit-card\"></i> #{@message.message} (#{@message.status}) #{Friendly.new.date(@message.created_at, @client.time_zone, true, true)}</span>"
                when 'postcard'
                  "<span><i class=\"fa fa-address-card\"></i> #{@message.message} (#{@message.status}) #{Friendly.new.date(@message.created_at, @client.time_zone, true, true)}</span>"
                else
                  ''
                end

    "#{response}</li>"
  end

  def message_error_message
    error_text = ''

    if @message.error_code.to_i.positive?

      case @message.error_code.to_i
      when 4_720
        error_text  = 'Possible Causes:<ul class="text-left">'
        error_text += 'Carrier Rejected as Invalid Destination Address. This could mean the number is not in the numbering plan (area code does not exist or the number is just invalid) or the number is not enabled for messaging (like a landline). Additionally, for toll free messages to TMobile, this could also mean the user has opted to block all toll free and short code traffic.'
      when 4_770
        error_text  = 'Possible Causes:<ul class="text-left">'
        error_text += 'The Carrier is reporting this message as blocked for SPAM. Spam blocks could be a result of content, SHAFT violations (including specific keywords), originating address has been flagged for repeated spam content.'
      when 30_003
        error_text  = 'Possible Causes:<ul class="text-left">'
        error_text += '<li>The destination handset you are trying to reach is switched off or otherwise unavailable.</li>'
        error_text += '<li>The device you are trying to reach does not have sufficient signal.</li>'
        error_text += '<li>The device cannot receive SMS (for example, the phone number belongs to a landline).</li>'
        error_text += '<li>There is an issue with the mobile carrier.</li>'
        error_text += '</ul>'
      when 30_004
        error_text  = 'Possible Causes:<ul class="text-left">'
        error_text += '<li>The destination number you are trying to reach is blocked from receiving this message (e.g., due to blacklisting).</li>'
        error_text += '<li>The device you are trying to reach does not have sufficient signal.</li>'
        error_text += '<li>The device cannot receive SMS (for example, the phone number belongs to a landline).</li>'
        error_text += '<li>The destination number is on India\'s national Do Not Call registry.</li>'
        error_text += '<li>There is an issue with the mobile carrier.</li>'
        error_text += '</ul>'
      when 30_005
        error_text  = 'Possible Causes:<ul class="text-left">'
        error_text += '<li>The destination number you are trying to reach is unknown and may no longer exist.</li>'
        error_text += '<li>The device you are trying to reach is not on or does not have sufficient signal.</li>'
        error_text += '<li>The device cannot receive SMS (for example, the phone number belongs to a landline).</li>'
        error_text += '<li>There is an issue with the mobile carrier.</li>'
        error_text += '</ul>'
      when 30_006
        error_text  = 'Possible Causes:<ul class="text-left">'
        error_text += '<li>The destination number is unable to receive this message.</li>'
        error_text += '<li>Potential reasons could include trying to reach a landline or, in the case of short codes, an unreachable carrier.</li>'
        error_text += '</ul>'
      when 30_007
        error_text  = 'Possible Causes:<ul class="text-left">'
        error_text += '<li>Your users complained to their carrier that they were receiving unwanted messages.</li>'
        error_text += '<li>Carriers are filtering you based on content (objectionable keywords or links).</li>'
        error_text += '<li>Carriers are filtering you because the volume of messages you are sending from each phone number it too large.</li>'
        error_text += '<li>You are sending similar or identical content to many multiple numbers within a short period time.</li>'
        error_text += '<li>Your messages have been caught by the carrier filter for some unknown reason. Carriers do not advertise how their spam filters work to avoid reverse engineering.</li>'
        error_text += '</ul>'
      when 30_008
        error_text  = 'Possible Causes:<ul class="text-left">'
        error_text += '<li>Delivery of your message failed with a generic error code from the carrier.</li>'
        error_text += '<li>The device you are trying to reach may not be on or may not have sufficient signal.</li>'
        error_text += '<li>There may be an issue with the mobile carrier.</li>'
        error_text += '<li>Try sending a shorter message to the phone, with simple content that does not include any special characters.</li>'
        error_text += '</ul>'
      else
        error_text = 'No additional information is available.'
      end
    else
      error_text = ''
    end

    error_text
  end

  def message_error_title
    if @message.error_code.to_i.positive?

      case @message.error_code.to_i
      when 4_470
        'Rejected Spam Detected'
      when 4_720
        'Invalid Destination Address'
      when 4_770
        'Carrier Rejected as SPAM'
      when 30_003
        'Unreachable Destination Handset'
      when 30_004
        'Message Blocked'
      when 30_005
        'Unknown Destination Handset'
      when 30_006
        'Landline or Unreachable Carrier'
      when 30_007
        'Carrier Violation'
      when 30_008
        'Unknown Error'
      else
        @message.error_message.presence || 'Unknown Error'
      end
    else
      'Error Not Reported'
    end
  end

  def message_from_phone_formatted
    if (Messages::Message::MSG_TYPES_TEXT + Messages::Message::MSG_TYPES_VOICE + Messages::Message::MSG_TYPES_RVM + Messages::Message::MSG_TYPES_VIDEO).include?(@message.msg_type)
      ActionController::Base.helpers.number_to_phone(@message.from_phone)
    elsif Messages::Message::MSG_TYPES_EMAIL.include?(@message.msg_type)
      @message.from_phone
    else
      'n/a'
    end
  end

  def message_message
    # rubocop:disable Lint/DuplicateBranch
    if %w[aiagentstatus review payment postcard].include?(@message.msg_type)
      ''
    elsif @message.message.present?
      "#{@message.message.gsub(%r{(?:\n\r?|\r\n?)}, '<br>')}#{self.message_agent_info.present? ? '<br />' : ''}#{@message_agent_info}"
    elsif @message.attachments.any? && self.message_agent_info.present?
      "&nbsp;<br />#{self.message_agent_info}"
    elsif self.message_agent_info.present?
      self.message_agent_info
    else
      ''
    end
    # rubocop:enable Lint/DuplicateBranch
  end

  def message_meta_data
    response  = [self.to_phone_meta_data]
    response << self.google_meta_data
    response << self.facebook_meta_data
    response << self.message_status
    response << "#{Friendly.new.date(@message.created_at, @client.time_zone, true)}"
    response << self.from_phone_meta_data
    response << @message.user&.firstname_last_initial.to_s if @message.user_id.present?
    response << "#{@message.triggeraction&.trigger&.campaign&.name}" if @message.triggeraction_id.present?

    response.compact_blank.join(' ')
  end

  def message_meta_data_hash
    {
      to_phone:      [self.to_phone_meta_data],
      google:        self.google_meta_data,
      facebook:      self.facebook_meta_data,
      status:        self.message.status,
      created_at:    Friendly.new.date(@message.created_at, @client.time_zone, true),
      from_phone:    self.from_phone_meta_data,
      user_name:     @message.user&.firstname_last_initial.to_s,
      campaign_name: @message.triggeraction&.trigger&.campaign&.name.to_s
    }
  end

  def message_status
    %w[fbin gglin textin voicein voiceout voicemail widgetin].exclude?(@message.msg_type) ? ActionController::Base.helpers.sanitize("<span id=\"msg-status-#{@message.id}\">(#{@message.status})</span> ", tags: %w[span], attributes: %w[id]).strip : ''
  end

  def message_to_phone_formatted
    if (Messages::Message::MSG_TYPES_TEXT + Messages::Message::MSG_TYPES_VOICE + Messages::Message::MSG_TYPES_RVM + Messages::Message::MSG_TYPES_VIDEO).include?(@message.msg_type)
      ActionController::Base.helpers.number_to_phone(@message.to_phone)
    elsif Messages::Message::MSG_TYPES_EMAIL.include?(@message.msg_type)
      @message.to_phone
    else
      'n/a'
    end
  end

  def ok2cardx?
    integration_allowed?('cardx') && (client_api_integration = @client.client_api_integrations.find_by(target: 'cardx', name: '')) && Integrations::CardX::Base.new(client_api_integration.account).valid_credentials?
  end

  def ok2facebook?
    @contact.fb_pages.any?
  end

  def ok2google?
    @contact.ggl_conversations.any?
  end

  def pcrichard_contact_api_integration
    @pcrichard_contact_api_integration ||= self.integration_allowed?('pcrichard')
  end

  def servicetitan_contact_api_integration
    @servicetitan_contact_api_integration ||= self.integration_allowed?('servicetitan')
  end

  def session=(session)
    @session = session || {}
  end

  def show_housecall_customer_data?(user:)
    (user.team_member? || user.agency_user_logged_in_as(session)&.team_member?) &&
      @client.integrations_allowed.include?('housecall') && @contact.ext_references.find_by(target: 'housecallpro')
  end

  def sunbasedata_api_integration
    @sunbasedata_api_integration ||= self.integration_allowed?('sunbasedata') ? @client.client_api_integrations.find_by(target: 'sunbasedata') : nil
  end

  def to_phone_meta_data
    %w[textout textoutuser textoutaiagent textoutother voiceout rvmout].include?(@message.msg_type) ? ActionController::Base.helpers.number_to_phone(@message.to_phone) : ''
  end

  def user=(user)
    super
    @active_contacts_list = nil
    @clients              = nil
    @user_settings        = nil
    @users                = nil
  end

  def user_client_tag
    if @user.access_controller?('central', 'all_contacts') && @client.agency_access && @user.agent?

      if @user.id == @contact.user_id
        ''
      else
        ActionController::Base.helpers.button_tag("#{@contact.user.initials} - #{@contact.client.name}", class: 'btn btn-secondary btn-xs ml-2')
      end
    else
      ActionController::Base.helpers.button_tag(@contact.user.firstname_last_initial, class: 'btn btn-secondary btn-xs ml-2')
    end
  end

  def user_settings
    @user_settings ||= @user.message_central_user_settings
  end

  def user_typing
    @user_typing ||= User.find_by(id: Contacts::RedisPool.new(@contact.id).user_id_typing) || User.new
  end

  def user_typing_display
    self.user_typing.new_record? ? 'none' : 'block'
  end

  def meta_data_display
    self.user_typing.new_record? ? 'block' : 'none'
  end

  def user_api_integration_fb
    if @user_api_integration_fb&.pages&.find { |p| p.dig('id') == @message.account_sid.to_s }
      @user_api_integration_fb
    else
      @user_api_integration_fb = UserApiIntegration.where(target: 'facebook', name: '').find_by('data @> ?', { pages: [id: @message.account_sid.to_s] }.to_json)
    end
  end

  def users_phones
    @users_phones ||= @client.users.pluck(:phone, :firstname, :lastname).to_h { |u| [u[0], Friendly.new.fullname(u[1], u[2])] }
  end

  def voice_disabled
    @contact.new_record? || (@client.current_balance.to_d / BigDecimal(100)) < @client.phone_call_credits.to_d
  end

  def xencall_contact_api_integration
    @xencall_contact_api_integration ||= self.integration_allowed?('xencall') ? @contact.contact_api_integrations.find_by(target: 'xencall') : nil
  end
end
