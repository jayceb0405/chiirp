class WebhookClientApiIntegration < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Converting Webhooks in ClientApiIntegration table...' do

      ClientApiIntegration.where(target: 'webhook', name: '').find_each do |client_api_integration|
        webhooks = {}
        fields   = %w[firstname lastname fullname email address1 address2 city state zipcode birthdate] + ::Webhook.internal_key_hash(client_api_integration.client, 'contact', %w[ext_references phones custom_fields user]).keys + %w[ok2text, ok2email last_updated last_contacted notes tags trusted_form_token trusted_form_cert_url trusted_form_ping_url]

        if client_api_integration.data.dig('webhook_endpoints', 'contact_new_url')
          webhooks[SecureRandom.uuid] = {
            url:    client_api_integration.data['webhook_endpoints']['contact_new_url'],
            type:   'contact_created',
            fields: fields
          }
        end

        if client_api_integration.data.dig('webhook_endpoints', 'contact_delete_url')
          webhooks[SecureRandom.uuid] = {
            url:    client_api_integration.data['webhook_endpoints']['contact_delete_url'],
            type:   'contact_deleted',
            fields: fields
          }
        end

        if client_api_integration.data.dig('webhook_endpoints', 'contact_update_url')
          webhooks[SecureRandom.uuid] = {
            url:    client_api_integration.data['webhook_endpoints']['contact_update_url'],
            type:   'contact_updated',
            fields: fields
          }
        end

        client_api_integration.data.delete('webhook_endpoints')
        client_api_integration.data['webhooks'] = webhooks
        client_api_integration.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
