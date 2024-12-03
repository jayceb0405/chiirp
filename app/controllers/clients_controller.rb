# frozen_string_literal: true

# app/controllers/clients_controller.rb
class ClientsController < ApplicationController
  before_action :authenticate_user!, except: %i[create]
  before_action :authenticate_user!, only: %i[create], unless: -> { params.include?(:self_create) && params[:self_create].to_s.casecmp?('true') }
  before_action :authorize_user!, only: %i[destroy edit new]
  before_action :client, only: %i[destroy edit file_upload update upgrade upgrade_account user_list]

  # (POST) create a new Client
  # /clients
  # clients_path
  # clients_url
  # form_with model: @client, remote: true do |form|
  def create
    dlc10_brand_hash = dlc10_brand_params.to_h
    self_create      = params.dig(:self_create).to_bool
    send_invite      = params.dig(:send_invite).to_bool
    package_id       = params.dig(:package_id).to_i
    package_page_id  = params.dig(:package_page_id).to_i
    new_client_hash  = new_client_params.to_h
    new_client_hash.merge(tenant: I18n.t('tenant.id'))
    new_user_hash = user_params.to_h
    new_user_hash.merge({ phone: new_client_hash[:phone] }) if new_client_hash.include?(:phone)

    create_cc_customer = if self_create && (package = Package.find_by(tenant: I18n.t('tenant.id'), id: package_id))
                           package.requires_credit_card?
                         else
                           false
                         end

    result = NewClient.create(
      client:             new_client_hash,
      user:               new_user_hash,
      dlc10_brand:        dlc10_brand_hash,
      package_id:,
      package_page_id:,
      create_cc_customer:,
      credit_card:        create_cc_customer,
      charge_client:      self_create,
      send_invite:
    )

    if result[:success]
      new_client = result[:client]

      # send lead info to FirstPromoter
      if cookies[:_fprom_track].present?
        new_client.update(fp_affiliate: cookies[:_fprom_track])

        cookies.delete :_fprom_track, domain: I18n.t("tenant.#{Rails.env}.sales_host")
        cookies.delete :_fprom_code, domain: I18n.t("tenant.#{Rails.env}.sales_host")

        FirstPromoter.new.register_signup({ client_id: new_client.id, client_name: "#{new_client.users.first.fullname} (#{new_client.name})", affiliate_id: new_client.fp_affiliate })
      end

      # submit the new Client 10DLC brand
      dlc10_brand_register = (new_client.dlc10_brand.register if new_client.dlc10_brand.present?)

      Rails.logger.info "ClientsController#create: #{{ new_client:, dlc10_brand: new_client.dlc10_brand, dlc10_brand_register:, client_id: new_client.id, user_id: new_client.def_user_id }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
    else
      new_client = nil
    end

    respond_to do |format|
      if self_create

        if new_client
          format.js { render js: "window.location = '#{welcome_success_path(new_client.id)}'" }
          format.html { redirect_to welcome_success_path(new_client.id) }
        else
          @client       = Client.new(new_client_hash)
          @user         = User.new(new_user_hash)
          @package      = Package.find_by(id: package_id)
          @package_page = PackagePage.find_by(id: package_page_id)

          sweetalert_error('Oops...', "An error occured: #{result[:error_message].presence || 'Unknown'}", '', { persistent: 'OK' })

          format.js { render partial: 'welcome/js/join', locals: { package: @package } }
          format.html { redirect_to welcome_join_path(@package.package_key, pp: @package_page.page_key) }
        end
      else
        @clients_index_settings = current_user.controller_action_settings('clients_index', session.dig(:clients_index).to_i)

        if current_user.team_member?
          @clients = Client.where(tenant: I18n.t('tenant.id')).order(:name).page(@clients_index_settings.data[:page]).per(@clients_index_settings.data[:per_page])
        elsif current_user.agent?
          @clients = Client.where(tenant: I18n.t('tenant.id')).where('data @> ?', { my_agencies: [current_user.client_id] }.to_json).order(:name).page(@clients_index_settings.data[:page]).per(@clients_index_settings.data[:per_page])
        end

        format.js   { render partial: 'clients/js/show', locals: { cards: [1, 7], clients_list_collapsed: false } }
        format.html { redirect_to clients_companies_path }
      end
    end
  end

  # (DELETE) destroy a Client
  # /clients/:client_id
  # client_path(:client_id)
  # client_url(:client_id)
  def destroy
    Rails.logger.info "ClientsController#destroy: #{{ client: @client, client_id: @client.id, user_id: current_user.id }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"

    @client.transaction do
      @client.destroy
    end

    respond_to do |format|
      format.js   { render js: "window.location = '#{clients_companies_path}'" }
      format.html { redirect_to clients_companies_path, status: :see_other }
    end
  end

  # (GET) edit a Client
  # /clients/:client_id/edit
  # edit_client_path(:client_id)
  # edit_client_url(:client_id)
  def edit
    respond_to do |format|
      format.js { render partial: 'clients/js/show', locals: { cards: [1] } }
      format.html { redirect_to clients_companies_path }
    end
  end

  # upload a file to Cloudinary for a Client
  # /users/:client_id/file_upload
  # client_file_upload_path(:client_id)
  # client_file_upload_url(:client_id)
  def file_upload
    file_id       = 0
    file_url      = ''
    error_message = ''

    if params.include?(:file)
      begin
        # upload into Client images folder
        client_attachment = @client.client_attachments.create!(image: params[:file])

        file_url = client_attachment.image.thumb.url(resource_type: client_attachment.image.resource_type, secure: true)
        retries = 0

        while file_url.nil? && retries < 10
          retries += 1
          sleep ProcessError::Backoff.full_jitter(retries:)
          client_attachment.reload
          file_url = client_attachment.image.thumb.url(resource_type: client_attachment.image.resource_type, secure: true)
        end
      rescue StandardError => e
        e.set_backtrace(BC.new.clean(caller))

        Appsignal.report_error(e) do |transaction|
          # Only needed if it needs to be different or there's no active transaction from which to inherit it
          Appsignal.set_action('ClientsController#file_upload')

          # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
          Appsignal.add_params(params)

          Appsignal.set_tags(
            error_level: 'error',
            error_code:  0
          )
          Appsignal.add_custom_data(
            client_attachment:,
            retries:,
            file_url:,
            file:              __FILE__,
            line:              __LINE__
          )
        end

        error_message = 'We encountered an error while attempting to upload your file. Please try again.'
      end
    else
      client_attachment = nil
      error_message = 'File was NOT received.'
    end

    file_id = client_attachment.id if client_attachment

    respond_to do |format|
      format.json { render json: { fileId: file_id, fileUrl: file_url, errorMessage: error_message, status: 200 } }
      format.html { render plain: 'Invalid format.', content_type: 'text/plain', layout: false, status: :not_acceptable }
    end
  end

  # (GET) show a new Client form
  # /clients/new
  # new_client_path
  # new_client_url
  def new
    @client = Client.new

    respond_to do |format|
      format.js { render partial: 'clients/js/show', locals: { cards: [1] } }
      format.html { redirect_to clients_companies_path }
    end
  end

  # (PUT/PATCH) update a Client address
  # /clients/:client_id
  # client_path(:client_id)
  # client_url(:client_id)
  def update
    if params.include?(:logo_image_delete)
      # delete the image
      @client.logo_image.purge if params[:logo_image_delete].to_s == 'true'
    else
      @client.update(new_client_params)
    end

    Rails.logger.info "ClientsController#update: #{{ client: @client, referer_path: URI(request.referer).path.downcase, client_id: @client.id, user_id: current_user.id }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"

    respond_to do |format|
      if URI(request.referer).path.downcase.include?('/dashboards') || URI(request.referer).path.casecmp?('/')
        # called from onboarding Dashboard
        format.js   { render js: "window.location = '#{root_path}'" }
        format.html { redirect_to root_path }
      else
        format.js   { render partial: 'clients/js/show', locals: { cards: [1] } }
        format.html { redirect_to clients_companies_path }
      end
    end
  end

  # (PATCH)
  # /clients/:client_id/update_agency
  # client_update_agency_path(:client_id)
  # client_update_agency_url(:client_id)
  def update_agency
    if params.include?(:client_id) && current_user.team_member?
      agencies_approved = params.include?(:agencies_approved) && params[:agencies_approved].is_a?(Array) ? params[:agencies_approved] : []

      if (client = Client.find_by(id: params[:client_id]))
        client.my_agencies = []

        agencies = Client.where(id: agencies_approved.map(&:to_i))

        agencies.each do |agency|
          client.my_agencies << agency.id
        end

        client.save
      end
    end

    respond_to do |format|
      format.js { render js: '', layout: false, status: :ok }
      format.html { redirect_to clients_companies_path }
    end
  end

  # (GET) show Package upgrade modal
  # /clients/:client_id/upgrade
  # client_upgrade_path(:client_id)
  # client_upgrade_url(:client_id)
  def upgrade
    if (@package_page = PackagePage.find_by(id: @client.package_page_id))
      respond_to do |format|
        format.js { render partial: 'clients/js/show', locals: { cards: [12] } }
        format.html { redirect_to clients_companies_path }
      end
    else
      sweetalert_error('Packages NOT found!', "We were not able to access the upgrade packages. Please contact #{I18n.t('tenant.name')} support.", '', { persistent: 'OK' })

      respond_to do |format|
        format.js { render js: "window.location = '#{edit_clients_overview_path(@client)}'" }
        format.html { redirect_to edit_clients_overview_path(@client) }
      end
    end
  end

  # (POST) upgrade an existing Client account
  # /clients/:client_id/upgrade
  # client_upgrade_account_path(:client_id)
  # client_upgrade_account_url(:client_id)
  def upgrade_account
    result = @client.change_package(package: params.dig(:pk).to_s, package_page: params.dig(:pp).to_s)

    if result[:success]
      sweetalert_success('Upgrade was Successful!', 'Congratulations! Thank you for upgrading your account. Your new features have been applied.', '', { persistent: 'OK' })
    else
      sweetalert_error('Upgrade was Unsuccessful.', result[:error_message], '', { persistent: 'OK' })
    end

    respond_to do |format|
      format.js { render partial: 'clients/js/show', locals: { cards: [6] } }
      format.html { redirect_to edit_clients_overview_path(@client) }
    end
  end

  # (GET)
  # /clients/:client_id/user_list
  # client_users_list_path(:client_id)
  # client_users_list_url(:client_id)
  def user_list
    render json: {}, status: :bad_request and return if current_user.blank?

    users = User.where(client_id: @client.id).where.not(id: current_user.id)
    users = users.where("data->'super_admin' @> ANY(ARRAY[?]::JSONB[])", %w[false]) unless current_user.super_admin?
    users = users.where("data->'team_member' @> ANY(ARRAY[?]::JSONB[])", %w[false]) unless current_user.team_member?
    users = users.where.not("permissions->'users_controller' ?| array[:options]", options: ['permissions']) unless current_user.admin?
    users = users.where("data->'agent' @> ANY(ARRAY[?]::JSONB[])", %w[false]) unless current_user.agent?

    render json: users.order(:lastname, :firstname).map { |u| { user_id: u.id, fullname: "#{u.default? ? '* ' : ''}#{u.fullname}" } }, status: :ok
  end

  # validate an email address as unique and available for use as a User email
  # validate_unique_email
  # validate_unique_email_path
  # validate_unique_email_url
  def validate_unique_email
    response = User.find_by(email: params.permit(:email).dig(:email)).nil?

    respond_to do |format|
      format.json { render json: response }
    end
  end

  private

  def authorize_user!
    super
    return if current_user.team_member? || (current_user.client.agency_access && current_user.agent? && action_name == 'index')

    raise ExceptionHandlers::UserNotAuthorized.new('Clients', root_path)
  end

  def client_cc_token_param
    params.permit(:stripeToken)
  end

  def client_params
    response = params.require(:client).permit(
      :fp_affiliate,
      :card_brand, :card_last4, :card_exp_month, :card_exp_year, :client_token,
      :auto_recharge,
      :scheduleonce_api_key, :scheduleonce_webhook_id, :scheduleonce_booking_scheduled, :scheduleonce_booking_no_show, :scheduleonce_booking_canceled_reschedule_requested, :scheduleonce_booking_rescheduled, :scheduleonce_booking_canceled, :scheduleonce_booking_canceled_then_rescheduled, :scheduleonce_booking_completed
    )

    response[:package_id]                 = response[:package_id].to_i if response.include?(:package_id)
    response[:package_page_id]            = response[:package_page_id].to_i if response.include?(:package_page_id)
    response[:mo_charge_retry_count]      = response[:mo_charge_retry_count].to_i if response.include?(:mo_charge_retry_count)
    response[:credit_charge_retry_level]  = response[:credit_charge_retry_level].to_i if response.include?(:credit_charge_retry_level)

    response[:auto_recharge]              = response[:auto_recharge].to_i == 1 if response.include?(:auto_recharge)

    response[:scheduleonce_booking_scheduled]   = response[:scheduleonce_booking_scheduled].to_i if response.include?(:scheduleonce_booking_scheduled)
    response[:scheduleonce_booking_no_show]     = response[:scheduleonce_booking_no_show].to_i if response.include?(:scheduleonce_booking_no_show)
    response[:scheduleonce_booking_canceled_reschedule_requested] = response[:scheduleonce_booking_canceled_reschedule_requested].to_i if response.include?(:scheduleonce_booking_canceled_reschedule_requested)
    response[:scheduleonce_booking_rescheduled] = response[:scheduleonce_booking_rescheduled].to_i if response.include?(:scheduleonce_booking_rescheduled)
    response[:scheduleonce_booking_canceled]    = response[:scheduleonce_booking_canceled].to_i if response.include?(:scheduleonce_booking_canceled)
    response[:scheduleonce_booking_canceled_then_rescheduled] = response[:scheduleonce_booking_canceled_then_rescheduled].to_i if response.include?(:scheduleonce_booking_canceled_then_rescheduled)
    response[:scheduleonce_booking_completed] = response[:scheduleonce_booking_completed].to_i if response.include?(:scheduleonce_booking_completed)

    response
  end

  def new_client_params
    params.require(:client).permit(:name, :address1, :address2, :city, :state, :zip, :phone, :time_zone, :card_token)
  end

  def client
    @client = if params.dig(:client_id).to_i.positive?
                Client.find_by(id: params[:client_id].to_i)
              else
                current_user.client
              end

    return if @client

    sweetalert_error('Client NOT found!', 'We were not able to access the Client you requested.', '', { persistent: 'OK' })

    respond_to do |format|
      format.js { render js: "window.location = '#{root_path}'" and return false }
      format.html { redirect_to root_path and return false }
    end
  end

  def dlc10_brand_params
    sanitized_params = params.require(:client).permit(:name, :legal_name, :country, dlc10_brand: %i[entity_type ein ein_country vertical alt_business_id_type alt_business_id stock_exchange stock_symbol support_email website])

    sanitized_params[:ein]     = sanitized_params[:ein].gsub(%r{\D}, '') if sanitized_params[:ein].present?
    sanitized_params[:website] = nil if sanitized_params[:website].blank?

    sanitized_params
  end

  def user_params
    params.require(:user).permit(:firstname, :lastname, :email)
  end
end
