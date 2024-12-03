# frozen_string_literal: true

# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include Authorizable

  layout :layout_by_resource
  helper_method :lost_contacts

  before_action :remove_otp_session
  before_action :enforce_sign_in_at_interval
  before_action :validate_requested_domain
  before_action :store_request_in_thread
  before_action :validate_terms_accepted
  before_action :set_mailer_host
  before_action :set_session_vars
  before_action :redis_controller_action
  before_action :reset_booking_campaign_name
  before_action :clean_old_cookies

  after_action  :clear_xhr_flash

  include Sweetify::SweetAlert

  rescue_from ActionController::InvalidAuthenticityToken, with: :invalid_authenticity_token
  rescue_from ActionController::UnknownFormat, with: :unknown_format
  rescue_from ExceptionHandlers::UserNotAuthorized, with: :user_not_authorized

  # any contacts with Messages and NO User
  def lost_contacts
    Contact.joins(:messages).where(contacts: { user_id: [0, nil], client_id: current_user.client_id }, messages: { read_at: nil }).distinct if current_user&.admin?
  end

  protected

  def after_sign_out_path_for(*)
    new_user_session_path
  end

  # allow a page to be shown in a iFrame
  #   Rails sends "SAMEORIGIN" in all headers for X-Frame-Options
  #   we want to remove that for UserContactForms & Clients::Widgets
  # after_action :allow_iframe
  def allow_iframe
    response.headers.delete 'X-Frame-Options'
    response.headers['X-Content-Type-Options'] = ''
  end

  def allow_servicemonster_iframe(embedding_url)
    response.set_header('X-Frame-Options', "ALLOW-FROM #{embedding_url}")
    response.set_header('Content-Security-Policy', "frame-ancestors 'self' #{embedding_url}")
  end

  # TODO: remove this after Sep 17, 2025
  def clean_old_cookies
    cookies.delete(:_funyl_session)
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up) do |u|
      u.permit(:username, :email, :password,
               :password_confirmation, :remember_me, :avatar, :avatar_cache, :remove_avatar)
    end
    devise_parameter_sanitizer.permit(:account_update) do |u|
      u.permit(:username, :email, :password,
               :password_confirmation, :current_password, :avatar, :avatar_cache, :remove_avatar)
    end
  end

  def reset_booking_campaign_name
    session.delete(:booking_campaign_name)
  end

  def set_mailer_host
    ActionMailer::Base.default_url_options = {
      host:     I18n.t("tenant.#{Rails.env}.app_host"),
      protocol: I18n.t('tenant.app_protocol')
    }
  end

  def store_location
    session[:previous_url] = request.fullpath unless request.fullpath.include?('users')
  end

  def store_request_in_thread
    Thread.current[:request] = request
  end

  private

  def clear_xhr_flash
    flash.discard if request.xhr?
  end

  def enforce_sign_in_at_interval
    # do not enforce on sessions or two factor controller pages
    # this must occur before user_signed_in? check
    return if params[:controller] == 'users/sessions'
    return if params[:controller] == 'users/two_factor'

    # do not enforce when user is not signed in
    return unless user_signed_in?

    # check signed_in_at cookie
    signed_in_at = (Time.at(session[:sign_in_at]).utc if session[:sign_in_at].is_a?(Integer))

    # if no cookie exists, check our data for the last sign in
    signed_in_at ||= current_user.current_sign_in_at

    # do not enforce if within allowed time
    # return if signed_in_at.present? && signed_in_at.beginning_of_day > 20.seconds.ago

    return if signed_in_at.present? && signed_in_at.beginning_of_day >= 1.week.ago

    # sign out the user and redict to sign in page
    session.delete(:sign_in_at)
    sign_out current_user

    respond_to do |format|
      format.html { redirect_to(new_user_session_path(expired: 'true')) && return }
      format.js   { render(plain: "window.location = '#{new_user_session_path(expired: 'true')}'", status: :ok) && return }
      format.turbo_stream { render(turbo_stream: turbo_stream.redirect_to(new_user_session_path(expired: 'true'))) && return }
      format.json { head(:unauthorized) && return }
    end
  end

  def invalid_authenticity_token
    sweetalert_warning('Expired', 'Your request has expired. Please try again.', '', { persistent: 'Ok' })

    if controller_name == 'client_widgets' && action_name == 'save_contact'
      # SiteChat iFrame

      if request.fullpath.include?('/api/v2/')
        redirect_to api_v2_show_widget_path(params[:widget_key])
      else
        redirect_to show_widget_path(params[:widget_key])
      end
    else
      redirect_to root_url(host: I18n.t("tenant.#{Rails.env}.app_host"))
    end
  end

  def layout_by_resource
    if devise_controller?
      'devise'
    elsif turbo_frame_request?
      false
    elsif controller_name == 'central' && %w[conversation index].include?(action_name) && browser.chrome? && !browser.device.mobile? && current_user&.client&.integrations_allowed&.include?('five9')
      'left_menu_header_five9'
    else
      'left_menu_header'
    end
  end

  def redis_controller_action
    return unless current_user

    if request.format.html?
      Users::RedisPool.new.update(user_id: current_user.id, controller_name:, action_name:, controller_class: self.class.to_s.downcase, contact_id: params.dig(:contact_id).to_i)
    elsif request.format.js?

      Users::RedisPool.new.update(user_id: current_user.id, controller_name: 'central', action_name: 'index', controller_class: self.class.to_s.downcase, contact_id: params.dig(:contact_id).to_i) if controller_name == 'central' && action_name == 'conversation'
    end
  end

  # double check that the otp_user_id session is removed
  def remove_otp_session
    session.delete(:otp_user_id)
    session.delete(:otp_method)
  end

  def set_session_vars
    if current_user
      @phone_number_assigned    = Twnumber.where(client_id: current_user.client_id).any?
      @contact_created          = Contact.where(client_id: current_user.client_id).any?
      @user_phone_defined       = current_user.phone.present?
      # rubocop:disable Rails/NegateInclude / session does not respond to .exclude?
      session[:selected_number] = current_user.latest_client_phonenumber(current_session: session)&.phonenumber.to_s if !session.include?(:selected_number) || session[:selected_nummber].to_s.empty?
      # rubocop:enable Rails/NegateInclude
    else
      @phone_number_assigned = false
      @contact_created          = false
      @user_phone_defined       = false
      session[:selected_number] = ''
    end

    @minimum_password_length = 6
  end

  def unknown_format
    respond_to do |format|
      format.json { render json: { message: 'Unknown format!', status: :not_found } }
      format.js   { render js: 'Unknown format!', layout: false, status: :not_found }
      format.html { render 'exceptions/404', layout: false, status: :not_found, formats: :html }
      format.all  { render 'exceptions/404', layout: false, status: :not_found, formats: :html }
    end
  end

  def user_not_authorized(error)
    if defined?(current_user)
      sweetalert_warning('Unauthorized Access!', "You are not authorized to access #{error.message}. Please contact your company or account admin.", '', { persistent: 'Ok' })

      respond_to do |format|
        format.js   { render js: "window.location = '#{error.redirect_url}'" and return false }
        format.json { render json: { location: error.redirect_url } and return false }
        format.html { redirect_to error.redirect_url and return false }
        format.all  { render 'exceptions/404', layout: false, status: :not_found, formats: :html and return false }
      end
    else
      sweetalert_warning('Not Logged In', 'You are not logged in. Please login to gain access.', '', { persistent: 'Ok' })

      respond_to do |format|
        format.js   { render js: "window.location = '#{login_path}'" and return false }
        format.json { render json: { location: login_path } and return false }
        format.html { redirect_to login_path and return false }
        format.all  { render 'exceptions/404', layout: false, status: :not_found, formats: :html and return false }
      end
    end
  end

  # validate the requested domain as a primary domain
  def validate_requested_domain
    if controller_name == 'user_contact_forms' && %w[save_contact show_frame_init show_modal_init show_page].include?(action_name)
      # always allow UserContactForms (QuickPages) to pass
    elsif controller_name == 'surveys' && %w[show update_contact].include?(action_name)
      # always allow Surveys to pass
    elsif controller_name == 'trackable_links' && action_name == 'redirect'
      # always allow TrackableLinks to pass
    elsif controller_name == 'short_codes' && action_name == 'show'
      # always allow ShortCodes to pass
    else
      redirect_url = Tenant.validate_requested_domain(request)

      if redirect_url.present?
        respond_to do |format|
          format.js   { render js: "window.location = '#{redirect_url}'" }
          format.json { render json: { location: redirect_url } }
          format.html { redirect_to redirect_url, allow_other_host: true }
          format.all  { redirect_to redirect_url, allow_other_host: true }
        end
      end
    end
  end

  def validate_terms_accepted
    if %w[invitations registrations sessions].include?(controller_name)
      # don't do anything
    elsif current_user && current_user.client.terms_accepted.to_s.empty? &&
          !(controller_name == 'terms' && action_name == 'edit') &&
          !(controller_name == 'terms' && action_name == 'update') &&
          !(controller_name == 'client_widgets' && action_name == 'sitechat') &&
          !(controller_name == 'client_widgets' && action_name == 'show_widget') &&
          !(controller_name == 'users' && action_name == 'logout') &&
          !(controller_name == 'users' && action_name == 'rcvpushtoken') &&
          !(controller_name == 'users' && action_name == 'become') &&
          !(controller_name == 'users' && action_name == 'return_to_self') &&
          !(controller_name == 'notes' && action_name == 'index')

      respond_to do |format|
        format.js { render js: "window.location = '#{edit_clients_term_path(current_user.client)}'" }
        format.html { redirect_to edit_clients_term_path(current_user.client) }
      end
    end
  end
end
