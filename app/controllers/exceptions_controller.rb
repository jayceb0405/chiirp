# frozen_string_literal: true

# app/controllers/exceptions_controller.rb
# rubocop:disable Rails/ApplicationController / must be ActionController::Base
class ExceptionsController < ActionController::Base
  class ExceptionsControllerError < StandardError; end

  # rubocop:enable Rails/ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_status

  include Sweetify::SweetAlert

  def humans
    redirect_to "#{I18n.t('tenant.app_protocol')}://#{I18n.t("tenant.#{Rails.env}.sales_host")}"
  end

  def internal_server_error
    render_500(false)
  end

  def not_found
    render_404
  end

  def something_else
    render_500(true)
  end

  private

  def render_500(send_error_report)
    request.format ||= 'html'

    if send_error_report && send_error_report?
      Rails.logger.info "ExceptionsController#render_500: #{{ message: @exception.message, status_code: @status_code }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"

      if @status_code == 406 && @exception.instance_of?(ActionDispatch::Http::MimeNegotiation::InvalidType)
        Rails.logger.info "ExceptionsController#render_500: #{{ class: 'ActionDispatch::Http::MimeNegotiation::InvalidType', ignored: true }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
      else
        error = ExceptionsControllerError.new("#{@exception.class}: #{@exception.message}")
        error.set_backtrace(BC.new.clean(caller))

        Appsignal.report_error(error) do |transaction|
          # Only needed if it needs to be different or there's no active transaction from which to inherit it
          Appsignal.set_action('ExceptionsController#render_500')

          # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
          Appsignal.add_params(defined?(params) ? params.merge({ send_error_report: }) : { send_error_report: })

          Appsignal.set_tags(
            error_level: 'error',
            error_code:  0
          )
          Appsignal.add_custom_data(
            domain:                     request.domain,
            exception:                  @exception,
            exception_class:            @exception.class,
            exception_location:         @trace,
            exception_message:          @exception.message,
            exception_original_message: @exception.original_message,
            exception_detailed_message: @exception.detailed_message,
            exception_methods:          @exception.methods,
            fullpath:                   request.fullpath,
            ip_address:                 request.remote_ip,
            referer:                    request.referer,
            request_format:             request.format,
            request_fullpath:           request.fullpath,
            request_method:             request.request_method,
            request_methods:            request.methods,
            status_code:                @status_code,
            subdomain:                  request.subdomain,
            url:                        request.url,
            file:                       __FILE__,
            line:                       __LINE__
          )
        end
      end
    else
      Rails.logger.error "Exception #{@exception.message} (#{@status_code}) NOT reported: File: #{__FILE__} - Line: #{__LINE__} - Trace: #{@trace}"
    end

    if Rails.env.development? && @exception
      Rails.logger.info "Development - Raising Exception Now! File: #{__FILE__} - Line: #{__LINE__}"
      raise @exception
    end

    ### Handle XHR Requests
    if request.format.html? && request.xhr?
      render "/exceptions/#{@status_code}", layout: false, status: @status_code, formats: :html
      return
    end

    ### Determine URL
    url = (request.referer if request.referer.present? && request.referer.exclude?(request.path))

    sweetalert_error('Unexpected Error!', @exception.message, '', { persistent: 'OK' })

    ### Handle Redirect Based on Request Format
    respond_to do |format|
      format.json { render json: { message: @exception.message, status: @status_code } }

      if url
        format.js   { render js: "window.location = '#{url}';" }
        format.html { redirect_to url, allow_other_host: true }
      else
        format.js   { render js: 'Exception', layout: false, status: @status_code }
        format.html { render 'exceptions/500', layout: false, status: @status_code, formats: :html }
        format.all  { render 'exceptions/500', layout: false, status: @status_code, formats: :html }
      end
    end
  end

  def render_404
    if request.get?
      respond_to do |format|
        format.json { render json: { message: 'File not found!', status: 404 } }
        format.js   { render js: '', layout: false, status: :not_found }
        format.html { render 'exceptions/404', layout: false, status: :not_found, formats: :html }
        format.all  { render 'exceptions/404', layout: false, status: :not_found, formats: :html }
      end
    else
      render plain: 'not found', content_type: 'text/plain', layout: false, status: :not_found
    end
  end

  def send_error_report?
    # rubocop:disable Lint/DuplicateBranch
    case
    when @status_code == 404 && (!current_user && !request.referer)
      ### Handle Direct URL entry & Bots
      return false
    when @exception.nil?
      return false
    when @exception.instance_of?(ActionController::BadRequest)
      return false if @exception.message.start_with?('Invalid query parameters: expected ')
      return false if @exception.message.start_with?('Invalid path parameters: Invalid encoding')
    end
    # rubocop:enable Lint/DuplicateBranch

    true
  end

  def set_status
    @exception = request.env['action_dispatch.exception']

    render_404 and return false unless @exception

    exception_wrapper = ActionDispatch::ExceptionWrapper.new(request.env['action_dispatch.backtrace_cleaner'], @exception)
    @status_code = exception_wrapper.status_code
    @trace = exception_wrapper.application_trace

    nil
  end
end
