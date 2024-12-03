# frozen_string_literal: true

# lib/process_error/report.rb
module ProcessError
  module Report
    class CustomException < StandardError; end

    def self.send(args)
      # report error
      #
      # ProcessError::Report.send(
      #   error_message: "Exception: #{e.message}",
      #   variables: {
      #     args: args.inspect,
      #     e: e.inspect,
      #     params: params.inspect
      #   },
      #   file: __FILE__,
      #   line: __LINE__
      # )
      variables        = args.dig(:variables).is_a?(Hash) ? args[:variables] : {}
      error_code       = args.dig(:error_code).to_s.present? ? " (#{args[:error_code]})" : ''
      error_message    = args.dig(:error_message).to_s.present? ? args[:error_message].to_s : 'Unknown'
      error_level      = (args.dig(:error_level) || 'info').to_s
      variables[:file] = (args.dig(:file) || args.dig(:variables, :file)).to_s
      variables[:line] = (args.dig(:line) || args.dig(:variables, :line)).to_s

      # Debug: The debug level should be used for detailed messages that assist in debugging. Typically, these logs are used by developers or system admins who need as much detail as possible about what might be going on in the system. In Ruby, this is the most verbose level.
      # Info: In the case of info-level logs, these provide information regarding normal application processing. This could be log information about services starting and stopping, or application metrics.
      # Warn: Warnings indicate something’s wrong. It might not be an error since the application may have recovered. Or, the warning may inform us of a rare business scenario we want to track.
      # Error: When we see errors, we know something failed. Perhaps a transaction was unable to update the database. Or maybe a dependency couldn’t be reached. Overall the application still functions, but things aren’t working properly.
      # Fatal: Fatal logs should only be used when something happens that causes the application to crash. This type of error may need support or intervention from the development team. It shouldn’t be used for general business errors.
      # Unknown: The unknown logging level will catch anything that doesn’t have a known level. It’s a catch-all for anything that might sneak through.

      if Rails.env.development?
        Rails.logger.send(error_level, '')
        Rails.logger.send(error_level, '<--- BEGIN ERROR MESSAGE --->')
        Rails.logger.send(error_level, "#{error_message}: #{error_code}")

        variables.each do |key, value|
          Rails.logger.send(error_level, "#{key}: #{value}")
        end

        Rails.logger.send(error_level, '<--- END ERROR MESSAGE --->')
        Rails.logger.send(error_level, '')
      elsif Rails.env.test?
        Rails.logger.info "ProcessError::Report::StandardError: #{{ error_level:, error_code:, error_message:, variables: }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
      elsif Rails.env.production?
        error = CustomException.new(args.dig(:error_message))
        error.set_backtrace(BC.new.clean(caller))

        Appsignal.report_error(error) do |transaction|
          # Only needed if it needs to be different or there's no active transaction from which to inherit it
          Appsignal.set_action('ProcessError::Report.send')

          # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
          Appsignal.add_params(args)

          Appsignal.set_tags(
            error_level:,
            error_code:
          )
          Appsignal.add_custom_data(
            variables: args.dig(:variables),
            file:      __FILE__,
            line:      __LINE__
          )
        end
      end
    end
  end
end
