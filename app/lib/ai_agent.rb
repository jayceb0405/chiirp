# frozen_string_literal: true

# app/lib/ai_agent.rb
class AiAgent
  class OpenAIFailedRequest < RuntimeError; end

  attr_accessor :error, :faraday_result, :functions, :history, :message, :model, :result, :success

  # initialize OpenAI
  # aa_client = AiAgent.new()
  #   (req) credentials: (Hash)
  def initialize(history, model: 'gpt-4o-mini', functions: [])
    reset_attributes

    self.functions = functions
    self.history = history
    self.model = model
  end

  def chat
    body = {
      model:       self.model,
      messages:    self.history,
      temperature: 0.7
    }
    body[:functions] = self.functions if self.functions.any?
    self.openai_request(
      body:,
      error_message_prepend: 'AiAgent.chat',
      method:                'post',
      params:                nil,
      default_result:        {},
      url:                   base_url
    )

    unless @result.is_a?(Hash)
      @success = false
      # @message = "Unexpected response: #{@result.inspect}"

      raise OpenAIFailedRequest, @message
    end

    @result
  end

  private

  def api_key
    Rails.application.credentials[:openai][:api_key]
  end

  def base_url
    'https://api.openai.com/v1/chat/completions'
  end

  # self.openai_request(
  #   body:                  Hash,
  #   error_message_prepend: 'AiAgent.xxx',
  #   method:                String,
  #   params:                Hash,
  #   default_result:        @result,
  #   url:                   String,
  # )
  def openai_request(args = {})
    reset_attributes
    body                  = args.dig(:body)
    error_message_prepend = args.dig(:error_message_prepend) || 'AiAgent.openai_request'
    faraday_method        = (args.dig(:method) || 'get').to_s
    params                = args.dig(:params)
    @result               = args.dig(:default_result)
    url                   = args.dig(:url).to_s

    success, error, message = Retryable.with_retries(
      rescue_class:          [Faraday::TimeoutError, Faraday::ConnectionFailed],
      error_message_prepend:,
      current_variables:     {
        parent_body:                  args.dig(:body),
        parent_error_message_prepend: args.dig(:error_message_prepend),
        parent_method:                args.dig(:method),
        parent_params:                args.dig(:params),
        parent_result:                args.dig(:default_result),
        parent_url:                   args.dig(:url),
        parent_file:                  __FILE__,
        parent_line:                  __LINE__
      }
    ) do
      @faraday_result = Faraday.send(faraday_method, url) do |req|
        req.headers['Authorization']       = "Bearer #{api_key}"
        req.headers['OpenAI-Organization'] = organization_id
        req.headers['Content-Type']        = 'application/json'
        req.params                         = params if params.present?
        req.body                           = body.to_json if body.present?
      end

      @faraday_result&.env&.dig('request_headers')&.delete('Authorization')
      result_body = JSON.is_json?(@faraday_result&.body) ? JSON.parse(@faraday_result.body) : nil

      case @faraday_result.status
      when 200
        @result  = if result_body.respond_to?(:deep_symbolize_keys)
                     result_body.deep_symbolize_keys
                   elsif result_body.respond_to?(:map)
                     result_body.map(&:deep_symbolize_keys)
                   else
                     result_body
                   end
        @success = !result_body.nil?
      when 400
        @error   = 400
        @message = "#{@faraday_result.reason_phrase} (#{@faraday_result.status}): #{result_body&.dig('errors', 'id')&.join(', ')}"
        @success = false
      when 401
        @error   = 401
        @message = "#{@faraday_result.reason_phrase} (#{@faraday_result.status}): #{result_body&.dig('errors', 'id')&.join(', ')}"
        @success = false
      when 404
        @error   = 404
        @message = "#{@faraday_result.reason_phrase} (#{@faraday_result.status}): #{result_body&.dig('errors', 'id')&.join(', ')}"
        @success = false
      when 409
        @error   = 409
        @message = "#{@faraday_result.reason_phrase} (#{@faraday_result.status}): #{result_body&.dig('errors', 'id')&.join(', ')}"
        @success = false
      else
        @error   = @faraday_result.status
        @message = "#{@faraday_result&.reason_phrase || 'Incomplete Faraday Request'} (#{@faraday_result&.status || 'Unknown Status'}): #{result_body&.dig('errors', 'id')&.join(', ')}"
        @success = false

        error = OpenAIFailedRequest.new('Incomplete Faraday Request')
        error.set_backtrace(BC.new.clean(caller))

        Appsignal.report_error(error) do |transaction|
          # Only needed if it needs to be different or there's no active transaction from which to inherit it
          Appsignal.set_action('AiAgent.openai_request')

          # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
          Appsignal.add_params(args)

          Appsignal.set_tags(
            error_level: 'error',
            error_code:  @error
          )
          Appsignal.add_custom_data(
            faraday_result:         @faraday_result&.to_hash,
            faraday_result_methods: @faraday_result&.public_methods.inspect,
            result:                 @result,
            result_body:,
            file:                   __FILE__,
            line:                   __LINE__
          )
        end
      end
    end

    @success = false unless success
    @error   = error if error.to_i.positive?
    @message = message if message.present?

    # JsonLog.info error_message_prepend, { success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }
    Rails.logger.info "#{error_message_prepend}: #{{ success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }.to_json} - File: #{__FILE__} - Line: #{__LINE__}"

    @result
  end

  def organization_id
    Rails.application.credentials[:openai][:organization_id]
  end

  def reset_attributes
    @error          = 0
    @faraday_result = nil
    @message        = ''
    @success        = false
  end
end
