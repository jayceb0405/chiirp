# frozen_string_literal: true

# app/lib/retryable.rb
require 'rexml/document'

# rubocop:disable ThreadSafety/InstanceVariableInClassMethod
# handles common Faraday errors
module Retryable
  # @error          = 0
  # @faraday_result = nil
  # @message        = ''
  # @result         = ''
  # @success        = false
  #
  # success, error, message = Retryable.with_retries(
  #   rescue_class:          [Faraday::TimeoutError, Faraday::ConnectionFailed],
  #   retry_skip_reason:     'getaddrinfo: Name or service not known',
  #   error_message_prepend: 'PhoneNumbers::Bandwidth::PhoneNumberDelete:',
  #   current_variables:     {
  #     args:        args.inspect,
  #     parent_file: __FILE__,
  #     parent_line: __LINE__
  #   }
  # ) do
  #   @faraday_result = Faraday.send(faraday_method, url) do |req|
  #     req.headers['Authorization'] = "Basic #{basic_auth}"
  #     req.headers['Content-Type']  = 'application/json'
  #     req.params                   = params if params.present?
  #     req.body                     = body.to_json if body.present?
  #   end
  #
  #   case @faraday_result.status
  #   when 200
  #   when 404
  #   end
  # end
  #
  # @success = false unless success
  # @error   = error
  # @message = message if message.present?
  def self.with_retries(rescue_class:, retries: 3, retry_skip_reason: nil, error_message_prepend: '', current_variables: {})
    success       = true
    error_code    = 0
    error_message = ''
    tries         = 0

    begin
      yield
    rescue *rescue_class => e
      tries += 1

      if tries <= retries && (retry_skip_reason.nil? || e.message.exclude?(retry_skip_reason))
        sleep ProcessError::Backoff.full_jitter(retries: tries)
        retry
      else
        derived_result = if defined?(conn)
                           conn
                         elsif defined?(result)
                           result
                         elsif defined?(faraday_result)
                           faraday_result
                         elsif defined?(@faraday_result)
                           @faraday_result
                         end
        success        = false
        error_code     = derived_result&.status.to_i
        error_message  = "#{error_message_prepend}::#{e.exception}: #{e.message}"
        local_vars     = self.local_variables.index_with { |key| binding.local_variable_get(key.to_s) }

        e.set_backtrace(BC.new.clean(caller))

        Appsignal.report_error(e) do |transaction|
          # Only needed if it needs to be different or there's no active transaction from which to inherit it
          Appsignal.set_action(error_message_prepend)

          # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
          Appsignal.add_params(
            rescue_class:,
            retries:,
            retry_skip_reason:,
            error_message_prepend:,
            current_variables:
          )

          Appsignal.set_tags(
            error_level: 'info',
            error_code:
          )
          Appsignal.add_custom_data(
            conn:                   defined?(conn) ? conn : 'Undefined',
            error_message:,
            faraday_result:         @faraday_result&.to_hash,
            faraday_result_methods: @faraday_result&.public_methods.inspect,
            derived_result:         derived_result || 'Undefined',
            derived_result_methods: derived_result&.methods&.inspect || 'Undefined',
            e_full_message:         defined?(e.full_message) ? e.full_message : 'Undefined',
            e_http_status:          defined?(e.http_status) ? e.http_status : 'Undefined',
            e_message:              e.message,
            e_methods:              e.public_methods.inspect,
            local_vars:,
            result:                 defined?(result) ? result : 'Undefined',
            result_methods:         defined?(result) ? result.methods.inspect : 'Undefined',
            tries:,
            file:                   __FILE__,
            line:                   __LINE__
          )
        end
      end
    rescue JSON::ParserError => e
      derived_result = if defined?(conn)
                         conn
                       elsif defined?(result)
                         result
                       elsif defined?(faraday_result)
                         faraday_result
                       elsif defined?(@faraday_result)
                         @faraday_result
                       end
      success        = false
      error_code     = derived_result&.status.to_i
      error_message  = "#{error_message_prepend}::#{e.exception}: #{e.message}"
      local_vars     = self.local_variables.index_with { |key| binding.local_variable_get(key.to_s) }

      e.set_backtrace(BC.new.clean(caller))

      Appsignal.report_error(e) do |transaction|
        # Only needed if it needs to be different or there's no active transaction from which to inherit it
        Appsignal.set_action(error_message_prepend)

        # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
        Appsignal.add_params(
          rescue_class:,
          retries:,
          retry_skip_reason:,
          error_message_prepend:,
          current_variables:
        )

        Appsignal.set_tags(
          error_level: 'info',
          error_code:
        )
        Appsignal.add_custom_data(
          conn:                   defined?(conn) ? conn : 'Undefined',
          e_exception:            e.exception,
          e_full_message:         defined?(e.full_message) ? e.full_message : 'Undefined',
          e_http_status:          defined?(e.http_status) ? e.http_status : 'Undefined',
          e_message:              e.message,
          e_methods:              e.public_methods.inspect,
          e_source:               defined?(e.source) ? e.source : 'Undefined',
          error_message:,
          derived_result:         derived_result || 'Undefined',
          derived_result_methods: derived_result&.methods&.inspect || 'Undefined',
          local_vars:,
          result:                 defined?(result) ? result : 'Undefined',
          result_methods:         defined?(result) ? result.methods.inspect : 'Undefined',
          tries:,
          file:                   __FILE__,
          line:                   __LINE__
        )
      end
    rescue REXML::ParseException => e
      derived_result = if defined?(conn)
                         conn
                       elsif defined?(result)
                         result
                       elsif defined?(faraday_result)
                         faraday_result
                       elsif defined?(@faraday_result)
                         @faraday_result
                       end
      success        = false
      error_code     = derived_result&.status.to_i
      error_message  = "#{error_message_prepend}::#{e.exception}: #{e.message}"
      local_vars     = self.local_variables.index_with { |key| binding.local_variable_get(key.to_s) }

      e.set_backtrace(BC.new.clean(caller))

      Appsignal.report_error(e) do |transaction|
        # Only needed if it needs to be different or there's no active transaction from which to inherit it
        Appsignal.set_action(error_message_prepend)

        # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
        Appsignal.add_params(
          rescue_class:,
          retries:,
          retry_skip_reason:,
          error_message_prepend:,
          current_variables:
        )

        Appsignal.set_tags(
          error_level: 'info',
          error_code:
        )
        Appsignal.add_custom_data(
          conn:                   defined?(conn) ? conn : 'Undefined',
          e_exception:            e.exception,
          e_full_message:         defined?(e.full_message) ? e.full_message : 'Undefined',
          e_http_status:          defined?(e.http_status) ? e.http_status : 'Undefined',
          e_message:              e.message,
          e_methods:              e.public_methods.inspect,
          e_source:               defined?(e.source) ? e.source : 'Undefined',
          error_message:,
          derived_result:         derived_result || 'Undefined',
          derived_result_methods: derived_result&.methods&.inspect || 'Undefined',
          local_vars:,
          result:                 defined?(result) ? result : 'Undefined',
          result_methods:         defined?(result) ? result.methods.inspect : 'Undefined',
          tries:,
          file:                   __FILE__,
          line:                   __LINE__
        )
      end
    rescue StandardError => e
      derived_result = if defined?(conn)
                         conn
                       elsif defined?(result)
                         result
                       elsif defined?(faraday_result)
                         faraday_result
                       elsif defined?(@faraday_result)
                         @faraday_result
                       end
      success        = false
      error_code     = derived_result&.status.to_i
      error_message  = "#{error_message_prepend}::#{e.exception}: #{e.message}"
      local_vars     = self.local_variables.index_with { |key| binding.local_variable_get(key.to_s) }

      e.set_backtrace(BC.new.clean(caller))

      Appsignal.report_error(e) do |transaction|
        # Only needed if it needs to be different or there's no active transaction from which to inherit it
        Appsignal.set_action(error_message_prepend)

        # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
        Appsignal.add_params(
          rescue_class:,
          retries:,
          retry_skip_reason:,
          error_message_prepend:,
          current_variables:
        )

        Appsignal.set_tags(
          error_level: 'info',
          error_code:
        )
        Appsignal.add_custom_data(
          conn:                   defined?(conn) ? conn : 'Undefined',
          e_exception:            e.exception,
          e_full_message:         defined?(e.full_message) ? e.full_message : 'Undefined',
          e_http_status:          defined?(e.http_status) ? e.http_status : 'Undefined',
          e_message:              e.message,
          e_methods:              e.public_methods.inspect,
          e_source:               defined?(e.source) ? e.source : 'Undefined',
          error_message:,
          derived_result:         derived_result || 'Undefined',
          derived_result_methods: derived_result&.methods&.inspect || 'Undefined',
          local_vars:,
          result:                 defined?(result) ? result : 'Undefined',
          result_methods:         defined?(result) ? result.methods.inspect : 'Undefined',
          tries:,
          file:                   __FILE__,
          line:                   __LINE__
        )
      end
    end

    [success, error_code, error_message]
  end
end
# rubocop:enable ThreadSafety/InstanceVariableInClassMethod
