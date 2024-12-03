# frozen_string_literal: true

# app/controllers/contacts_controller.rb
class ContactsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user!
  before_action :contact, only: %i[block edit_scheduled_action destroy destroy_scheduled_action edit file_upload index_scheduled_actions sleep tag_apply tag_remove update update_scheduled_action]

  # (POST)
  # /contacts/:contact_id/block
  # contact_block_path(:contact_id)
  # contact_block_url(:contact_id)
  def block
    # switch block
    @contact.update(block: !@contact.block)

    referrer = Rails.application.routes.recognize_path(request.referer)

    if referrer[:controller] == 'central' && referrer[:action] == 'index'
      render partial: 'central/js/show', locals: { cards: %w[active_contacts conversation contact_profile] }
    else
      render partial: 'my_contacts/js/show', locals: { cards: %w[index_contacts] }
    end
  end

  # (POST) create a new Contact
  # /contacts
  # contacts_path
  # contacts_url
  def create
    # return_to = params.dig(:return_to).to_s
    @contact = current_user.contacts.new(contact_params)

    if @contact.save
      # save ContactCustomFields
      @contact.update_custom_fields(custom_fields: client_custom_fields_params.to_h)
      params.dig(:contact_phones) ? @contact.update_contact_phones(params_contact_phones, true, true) : @contact.update_contact_phones([], true, true)
      params.dig(:ext_references) ? @contact.update_ext_references(params_ext_references, true) : @contact.update_ext_references([], true)
      @contact.save

      if params.dig(:campaign_id).to_i.positive?
        # Campaign was selected to apply to new Contact
        Contacts::Campaigns::StartJob.perform_later(
          campaign_id: params[:campaign_id].to_i,
          client_id:   @contact.client_id,
          contact_id:  @contact.id,
          user_id:     current_user.id
        )
      end

      Contacts::Tags::ApplyJob.perform_now(
        contact_id: @contact.id,
        tag_id:     params[:tag_id]
      )
    end

    if @contact.errors.any?
      sweetalert_error('Contact NOT created!', '', "We were not able to create the Contact you requested. #{@contact.errors.full_messages.join(' & ')}", { persistent: 'OK' })

      respond_to do |format|
        format.js { render partial: 'contacts/js/show' }
      end
    else
      respond_to do |format|
        if params.dig(:commit).to_s.casecmp?('save & open in message central')
          format.js { render js: "window.location = '#{central_path(contact_id: @contact.id)}'" }
        else
          format.js { render partial: 'contacts/js/show', locals: { cards: %w[edit_contact] } }
        end
      end
    end
  end

  # (DELETE) destroy a Contact
  # /contacts/:contact_id
  # contact_path(:contact_id)
  # contact_url(:contact_id)
  def destroy
    @contact.destroy

    @user_setting  = current_user.controller_action_settings('contacts_search', session.dig(:contacts_search).to_i)
    @contacts      = Contact.custom_search_query(
      user:                 current_user,
      my_contacts_settings: @user_setting,
      broadcast:            current_user.access_controller?('my_contacts', 'schedule_actions', session),
      page_number:          (params.dig(:page) || 1).to_i,
      order:                true
    )

    @page_number = (params.dig(:page) || 1).to_i
    @broadcast = current_user.access_controller?('my_contacts', 'schedule_actions')

    respond_to do |format|
      format.js { render partial: 'my_contacts/js/show', locals: { cards: %w[index_contacts], broadcast: @broadcast } }
      format.html { redirect_to root_path }
      format.turbo_stream
    end
  end

  # (DELETE) destroy 1 or more DelayedJobs for a Contact
  # /contacts/:contact_id/scheduled_action/:id
  # contact_scheduled_action_path(:contact_id, :id)
  # contact_scheduled_action_url(:contact_id, :id)
  def destroy_scheduled_action
    if params.dig(:id).to_i.zero?

      @contact.delayed_jobs.find_each do |delayed_job|
        self.destroy_delayed_job(delayed_job)
      end
    elsif params.dig(:id).to_i.positive?
      if (delayed_job = @contact.delayed_jobs.find_by(id: params[:id].to_i))
        self.destroy_delayed_job(delayed_job)
      end
    end

    @contact.reload

    render partial: 'contacts/js/show', locals: { cards: %w[index_scheduled_actions] }
  end

  # (GET) edit Contact in a modal
  # /contacts/:contact_id/edit
  # edit_contact_path(:contact_id)
  # edit_contact_url(:contact_id)
  def edit
    respond_to do |format|
      format.js { render partial: 'contacts/js/show', locals: { cards: %w[edit_contact edit_contact_show] } }
      format.html { redirect_to root_path }
      format.turbo_stream
    end
  end

  # (GET) edit a Scheduled Action
  # /contacts/:contact_id/scheduled_action/:id/edit
  # edit_contact_scheduled_action_path(:contact_id, :id)
  # edit_contact_scheduled_action_url(:contact_id, :id)
  def edit_scheduled_action
    @delayed_job = Delayed::Job.find_by(contact_id: @contact.id, id: params.dig(:id))

    render partial: 'contacts/js/show', locals: { cards: %w[edit_scheduled_action] }
  end

  # upload a file to Cloudinary for a Contact
  # /contacts/:contact_id/file_upload
  # contact_file_upload_path(:contact_id)
  # contact_file_upload_url(:contact_id)
  def file_upload
    file_id       = 0
    file_url      = ''
    error_message = ''

    if params.include?(:file)
      begin
        # upload into Contact images folder
        contact_attachment = @contact.contact_attachments.create!(image: params[:file])

        file_url = contact_attachment.image.thumb.url(resource_type: contact_attachment.image.resource_type, secure: true)
        retries  = 0

        while file_url.nil? && retries < 10
          retries += 1
          sleep ProcessError::Backoff.full_jitter(retries:)
          contact_attachment.reload
          file_url = contact_attachment.image.thumb.url(resource_type: contact_attachment.image.resource_type, secure: true)
        end
      rescue StandardError => e
        e.set_backtrace(BC.new.clean(caller))

        Appsignal.report_error(e) do |transaction|
          # Only needed if it needs to be different or there's no active transaction from which to inherit it
          Appsignal.set_action('ContactsController#file_upload')

          # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
          Appsignal.add_params(params)

          Appsignal.set_tags(
            error_level: 'error',
            error_code:  0
          )
          Appsignal.add_custom_data(
            contact_attachment:,
            file_url:,
            retries:,
            file:               __FILE__,
            line:               __LINE__
          )
        end

        error_message = 'We encountered an error while attempting to upload your file. Please try again.'
      end
    else
      contact_attachment = nil
      error_message      = 'File was NOT received.'
    end

    file_id = contact_attachment.id if contact_attachment

    respond_to do |format|
      format.json { render json: { fileId: file_id, fileUrl: file_url, errorMessage: error_message, status: 200 } }
      format.html { render plain: 'Invalid format.', content_type: 'text/plain', layout: false, status: :not_acceptable }
    end
  end

  # (GET) list DelayedJobs for a Contact
  # /contacts/:contact_id/scheduled_actions
  # contact_scheduled_actions_path(:contact_id)
  # contact_scheduled_actions_url(:contact_id)
  def index_scheduled_actions
    render partial: 'contacts/js/show', locals: { cards: %w[index_scheduled_actions] }
  end

  # (GET) prepare for a new Contact
  # /contacts/new
  # new_contact_path
  # new_contact_url
  def new
    return_to = params.dig(:return_to).to_s
    @contact  = current_user.contacts.new(ok2email: 1, ok2text: 1)

    respond_to do |format|
      format.js { render partial: 'contacts/js/show', locals: { cards: %w[edit_contact edit_contact_show], return_to: } }
      format.html { redirect_to root_path }
    end
  end

  # (POST)
  # /contacts/:contact_id/sleep
  # contact_sleep_path(:contact_id)
  # contact_sleep_url(:contact_id)
  def sleep
    @contact.update(sleep: !@contact.sleep)

    referrer = Rails.application.routes.recognize_path(request.referer)

    if referrer[:controller] == 'central' && referrer[:action] == 'index'
      render partial: 'central/js/show', locals: { cards: %w[active_contacts conversation contact_profile] }
    else
      @user_setting = current_user.controller_action_settings('contacts_search', session.dig(:contacts_search).to_i)
      render partial: 'my_contacts/js/show', locals: { cards: %w[index_contacts] }
    end
  end

  # (POST)
  # /contacts/:contact_id/tagapply
  # contact_tag_apply_path(:contact_id)
  # contact_tag_apply_url(:contact_id)
  def tag_apply
    Contacts::Tags::ApplyJob.perform_now(
      contact_id: @contact.id,
      tag_id:     params.dig(:tag_id)
    )

    referrer = Rails.application.routes.recognize_path(request.referer)

    respond_to do |format|
      if referrer[:controller] == 'central' && referrer[:action] == 'index'
        format.js { render partial: 'central/js/show', locals: { cards: %w[contact_profile tags] } }
      else
        format.js   { render partial: 'contacts/js/show', locals: { cards: [1, 2] } }
      end

      format.html { redirect_to central_path }
    end
  end

  # (DELETE)
  # /contacts/:contact_id/tagremove/:contacttag_id
  # contact_tag_remove_path(:contact_id, :contacttag_id)
  # contact_tag_remove_url(:contact_id, :contacttag_id)
  def tag_remove
    if (contact_tag = @contact.contacttags.find_by(id: params.dig(:contacttag_id).to_i))
      # Contacttag was found
      contact_tag.destroy
    end

    referrer = Rails.application.routes.recognize_path(request.referer)
    cards    = params.dig(:show_modal).to_bool ? %w[contact_profile tags] : %w[contact_profile]

    respond_to do |format|
      if referrer[:controller] == 'central' && referrer[:action] == 'index'
        format.js { render partial: 'central/js/show', locals: { cards: } }
      else
        format.js { render partial: 'contacts/js/show', locals: { cards: [1, 2] } }
      end

      format.html { redirect_to central_path }
    end
  end

  # (PUT/PATCH) save updates to Contact
  # /contacts/:contact_id
  # contact_path(:contact_id)
  # contact_url(:client_id)
  def update
    referrer  = Rails.application.routes.recognize_path(request.referer)
    return_to = params.dig(:return_to).to_s

    @contact.update_custom_fields(custom_fields: client_custom_fields_params.to_h) if @contact.update(contact_params)
    params.dig(:contact_phones) ? @contact.update_contact_phones(params_contact_phones, true, true) : @contact.update_contact_phones([], true, true)
    params.dig(:ext_references) ? @contact.update_ext_references(params_ext_references, true) : @contact.update_ext_references([], true)
    @contact.save

    if params.dig(:contact, :corp_client_id).to_i != @contact.corp_client&.id.to_i

      if params.dig(:contact, :corp_client_id).to_i.zero? && (client = Client.find_by(id: @contact.corp_client.id))
        client.update(contact_id: 0)
      elsif params.dig(:contact, :corp_client_id).to_i.positive? && (new_client = Client.find_by(id: params[:contact][:corp_client_id].to_i))

        if @contact.corp_client && (client = Client.find_by(id: @contact.corp_client.id))
          client.update(contact_id: 0)
        end

        new_client.update(contact_id: @contact.id)
      end
    end

    unless referrer[:controller] == 'central' && referrer[:action] == 'index'
      @user_setting  = current_user.controller_action_settings('contacts_search', session.dig(:contacts_search).to_i)
      @contacts      = Contact.custom_search_query(
        user:                 current_user,
        my_contacts_settings: @user_setting,
        broadcast:            current_user.access_controller?('my_contacts', 'schedule_actions'),
        page_number:          (params.dig(:page) || 1).to_i,
        order:                true
      )
    end

    respond_to do |format|
      if params.dig(:commit).to_s.casecmp?('save & open in message central')
        format.js { render js: "window.location = '#{central_path(contact_id: @contact.id)}'" }
        format.turbo_stream { redirect_to central_path(contact_id: @contact.id) }
      elsif referrer[:controller] == 'central' && referrer[:action] == 'index'
        if return_to.to_s == 'video'
          format.js { render partial: 'video/js/show', locals: { cards: [2] } }
        else
          format.js { render partial: 'central/js/show', locals: { cards: %w[active_contacts contact_phones contact_profile] } }
        end
      else
        format.js { render partial: 'my_contacts/js/show', locals: { cards: %w[index_contacts], broadcast: current_user.access_controller?('my_contacts', 'schedule_actions') } }
        format.turbo_stream
      end

      format.html { redirect_to root_path }
    end
  end

  # (PATCH) update a Scheduled Action
  # /contacts/:contact_id/scheduled_action/:id
  # update_contact_scheduled_action_path(:contact_id, :id)
  # update_contact_scheduled_action_url(:contact_id, :id)
  def update_scheduled_action
    if (delayed_job = Delayed::Job.find_by(contact_id: @contact.id, id: params.dig(:id)))
      args = delayed_job.payload_object.args.first

      case delayed_job.process
      when 'send_text'
        sanitized_params      = params_delayed_job_send_text
        args[:from_phone]     = sanitized_params[:from_phone]
        args[:to_label]       = sanitized_params[:to_label]
        args[:to_phone]       = ''
        args[:content]        = sanitized_params[:message]
        args[:image_id_array] = sanitized_params.dig(:image_id_array)
        delayed_job.payload_object.args = [args]
        delayed_job.handler = delayed_job.payload_object.to_yaml
        delayed_job.run_at  = sanitized_params[:run_at]
        delayed_job.data[:content] = args[:content]
        delayed_job.data[:image_id_array] = args[:image_id_array]
        delayed_job.save
      when 'send_email'
        sanitized_params              = params_delayed_job_send_email
        args[:email_template_id]      = sanitized_params[:email_template_id]
        args[:subject]                = sanitized_params[:email_template_subject]
        args[:email_template_yield]   = sanitized_params[:email_template_yield]
        args[:payment_request]        = sanitized_params[:payment_request].to_d
        args[:file_attachments]       = JSON.parse(sanitized_params.dig(:file_attachments) || '[]').collect(&:symbolize_keys)
        delayed_job.payload_object.args = [args]
        delayed_job.handler = delayed_job.payload_object.to_yaml
        delayed_job.run_at  = sanitized_params[:run_at]
        delayed_job.data[:email_template_id] = args[:email_template_id]
        delayed_job.save
      end
    end

    render partial: 'contacts/js/show', locals: { cards: %w[index_scheduled_actions] }
  end

  private

  def condition_test(column, tags)
    response = true

    ta = column.contacttags.pluck(:tag_id).uniq

    tags.each do |tag|
      response = false unless ta.include?(tag.to_i)
    end

    response
  end

  def client_custom_fields_params
    response = {}

    response = params.require(:client_custom_fields).permit(params[:client_custom_fields].keys) if params.include?(:client_custom_fields)

    response
  end

  def contact_params
    sanitized_params = params.require(:contact).permit(
      :firstname, :lastname, :address1, :address2, :city, :state, :zipcode, :email,
      :birthdate, :block, :companyname, :group_id, :lead_source_id, :notes, :ok2email, :ok2text, :salesrabit_lead_id, :sleep, :stage_id, :user_id, :campaign_group_id, folders: []
    )

    sanitized_params[:block]          = sanitized_params[:block].to_bool if sanitized_params.include?(:block)
    sanitized_params[:birthdate]      = Chronic.parse(sanitized_params[:birthdate]) if sanitized_params.include?(:birthdate)
    sanitized_params[:group_id]       = sanitized_params.dig(:group_id).to_i if sanitized_params.include?(:group_id)
    sanitized_params[:lead_source_id] = sanitized_params.dig(:lead_source_id) if sanitized_params.dig(:lead_source_id).to_i.positive?
    sanitized_params[:stage_id]       = sanitized_params.dig(:stage_id).to_i if sanitized_params.include?(:stage_id)
    sanitized_params[:sleep]          = sanitized_params[:sleep].to_bool if sanitized_params.include?(:sleep)

    sanitized_params
  end

  def destroy_delayed_job(delayed_job)
    delayed_job.destroy
    delayed_job.contact.triggeraction_complete(triggeraction_id: delayed_job.triggeraction_id, contact_campaign_id: delayed_job.contact_campaign_id)
  end

  def params_contact_phones
    params.require(:contact_phones).permit(params.dig(:contact_phones).keys.map { |k| [k => %i[label phone primary]] }).values.map { |v| [v.dig(:phone).to_s, v.dig(:label).to_s, v.dig(:primary).to_bool] }
  end

  def params_delayed_job_send_text
    sanitized_params = params.permit(:from_phone, :to_label, :run_at).merge(params.require(:message).permit(:file_attachments, :message))

    sanitized_params[:run_at]         = Time.use_zone(current_user.client.time_zone) { Chronic.parse(sanitized_params.dig(:run_at).to_s) }
    sanitized_params[:to_label]       = 'primary' if sanitized_params[:to_label].blank?
    sanitized_params[:image_id_array] = JSON.parse(sanitized_params.dig(:file_attachments)).map { |f| f.dig('id').to_i }

    sanitized_params
  end

  def params_delayed_job_send_email
    sanitized_params = params.permit(:run_at).merge(params.require(:message).permit(:file_attachments, :message, :email_template_id, :email_template_subject, :email_template_yield, :payment_request))

    sanitized_params[:run_at] = Time.use_zone(current_user.client.time_zone) { Chronic.parse(sanitized_params.dig(:run_at).to_s) }
    # sanitized_params[:image_id_array] = JSON.parse(sanitized_params.dig(:file_attachments)).map { |f| f.dig('id').to_i }

    sanitized_params
  end

  def params_ext_references
    params.require(:ext_references).permit(params.dig(:ext_references).keys.map { |k| [k => %i[target ext_id]] }).values.map { |v| [v.dig(:target).to_s, v.dig(:ext_id).to_s] }
  end

  def client
    @client = Client.find_by(id: params[:client_id])

    return if @client

    sweetalert_error('Client NOT found!', 'We were not able to access the Client you requested.', '', { persistent: 'OK' })

    respond_to do |format|
      format.js { render js: "window.location = '#{root_path}'" and return false }
      format.html { redirect_to root_path and return false }
    end
  end

  def contact
    return if action_name == 'dialer' && !request.post?

    @contact = Contact.find_by(id: params.dig(:contact_id).to_i)
    return @contact if @contact && current_user.access_contact?(@contact)

    sweetalert_error('Contact NOT found!', 'We were not able to access the Contact you requested.', '', { persistent: 'OK' })

    respond_to do |format|
      format.js { render js: "window.location = '#{root_path}'" and return false }
      format.html { redirect_to root_path and return false }
    end
  end

  def tag_name_parms
    params.require(:tag).permit(:name)
  end
end
