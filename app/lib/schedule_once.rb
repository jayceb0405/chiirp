# frozen_string_literal: true

# app/lib/schedule_once.rb
class ScheduleOnce
  # webhook processing for ScheduleOnce
  require 'net/http'
  require 'uri'

  # create a new webhook
  # so = ScheduleOnce.new
  # so.create_webhook( { api_key: String, webhook_url: String, webhook_name: String, webhook_events: Array } )
  def create_webhook(params)
    api_key        = (params.include?(:api_key) ? params[:api_key].to_s : '')
    webhook_url    = (params.include?(:webhook_url) ? params[:webhook_url].to_s : '')
    webhook_name   = (params.include?(:webhook_name) ? params[:webhook_name].to_s : '')
    webhook_events = (params.include?(:webhook_events) && params[:webhook_events].is_a?(Array) ? params[:webhook_events] : [])

    return unless !api_key.empty? && !webhook_url.empty? && !webhook_name.empty? && !webhook_events.empty?

    uri = URI.parse('https://api.scheduleonce.com/v1/webhooks')
    header = { 'Content-Type': 'application/json', Accept: 'application/json', 'API-Key': api_key }
    body = { url: webhook_url, name: webhook_name, events: webhook_events }

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri, header)
    request.body = body.to_json

    response = http.request(request)

    # Rails.logger.info "ScheduleOnce:create_webhook:response.code: #{response.code.inspect}"
    # Rails.logger.info "ScheduleOnce:create_webhook:response.read_body: #{JSON.parse(response.read_body).symbolize_keys.inspect}"

    (response.code.to_i >= 200 && response.code.to_i <= 299 ? JSON.parse(response.read_body).symbolize_keys[:id].to_s : '')
  end

  # delete a webhook
  # so = ScheduleOnce.new
  # so.delete_webhook( { api_key: String, webhook_id: String } )
  def delete_webhook(params)
    api_key    = (params.include?(:api_key) ? params[:api_key].to_s : '')
    webhook_id = (params.include?(:webhook_id) ? params[:webhook_id].to_s : '')

    return unless !api_key.empty? && !webhook_id.empty?

    uri = URI.parse("https://api.scheduleonce.com/v1/webhooks/#{webhook_id}")
    header = { 'Content-Type': 'application/json', Accept: 'application/json', 'API-Key': api_key }

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Delete.new(uri.request_uri, header)

    response = http.request(request)

    # Rails.logger.info "ScheduleOnce:delete_webhook:response.code: #{response.code.inspect}"
    # Rails.logger.info "ScheduleOnce:delete_webhook:response.read_body: #{response.read_body.inspect}"

    response.code.to_i >= 200 && response.code.to_i <= 299
  end
end
