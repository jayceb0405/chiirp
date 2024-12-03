# frozen_string_literal: true

# app/controllers/integrations/webhook/integrations_controller.rb
module Integrations
  module Webhook
    class IntegrationsController < ApplicationController
      skip_before_action :verify_authenticity_token, only: %i[api appsignal]
      before_action :authenticate_user!, except: %i[api appsignal]
      before_action :authorize_user!, except: %i[api appsignal]
      before_action :client_api_integration, except: %i[api appsignal]

      # (POST) webhooks API endpoint to add/update Contact
      # /integrations/webhook/clients/:client_id/:token
      # integrations_webhook_client_api_path(:client_id, :token)
      # integrations_webhook_client_api_url(:client_id, :token)

      # (POST) webhooks API endpoint to add/update User
      # /integrations/webhook/users/:client_id/:token
      # integrations_webhook_user_api_path(:client_id, :token)
      # integrations_webhook_user_api_url(:client_id, :token)
      def api
        client_id = params.permit(:client_id).dig(:client_id).to_i
        token     = params.permit(:token).dig(:token).to_s

        if (client = Client.find_by(id: client_id)) && (webhook = client.webhooks.find_by(token:))
          data_received = params.to_unsafe_h
          data_received.delete('controller')
          data_received.delete('action')
          data_received.delete('client_id')
          data_received.delete('token')
          data_received.delete('webhook')

          if data_received.empty?
            begin
              data_received = JSON.parse(request.raw_post)
            rescue StandardError
              # do nothing
            end
          end

          if webhook.testing == '1'
            # Webhook is in test mode
            webhook.update(sample_data: data_received)
          elsif webhook.data_type == 'contact'
            add_or_update_contact({ webhook:, data_received: })
          elsif webhook.data_type == 'user'
            add_or_update_user({ client:, webhook:, data_received: })
          end
        end

        render plain: 'Success', content_type: 'text/plain', layout: false
      end

      # (POST) receive webhook data from AppSignal and restart Heroku dynos as needed
      # /integrations/webhook/appsignal
      # integrations_webhook_appsignal_path
      # integrations_webhook_appsignal_url
      def appsignal
        dyno = params.dig(:alert, :tags, :hostname)
        Rails.logger.info "AppSignal webhook params: #{params.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
        Rails.logger.info "AppSignal webhook dyno: #{dyno.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"

        if dyno.present? && params.dig(:alert, :last_value).to_d > 100.0
          # send Slack notification to Key User
          Integrations::Slack::PostMessageJob.perform_later(
            token:   Rails.application.credentials[:slack][:token],
            channel: 'chiirp_slack',
            content: "Restarting Heroku dyno (#{dyno})."
          )

          # restart dyno
          Heroku.new.delay(
            priority: DelayedJob.job_priority('restart_dyno'),
            queue:    DelayedJob.job_queue('restart_dyno'),
            user_id:  0,
            process:  'restart_dyno'
          ).restart_dyno dyno
        end

        respond_to do |format|
          format.js   { render js: '', layout: false, status: :ok and return }
          format.html { render plain: '', content_type: 'text/plain', layout: false, status: :ok and return }
        end
      end
      # example webhook payload from AppSignal
      # {
      #   method:      'POST',
      #   path:        '/webhooks/appsignal',
      #   format:      '*/*',
      #   controller:  'Integrations::Webhook::IntegrationsController',
      #   action:      'appsignal',
      #   status:      500,
      #   allocations: 1044,
      #   duration:    1.18,
      #   view:        0.0,
      #   db:          0.0,
      #   request:     {
      #     id:        '28d0598c-a54f-4175-85da-c1c18af915db',
      #     remote_ip: '162.158.78.240',
      #     host:      'app.chiirp.com',
      #     params:    {
      #       alert:      {
      #         kind:                   'HostMemoryUsage',
      #         alert_id:               '661d5200d2a5e4a471664aea',
      #         state:                  'open',
      #         site:                   'Chiirp',
      #         environment:            'production',
      #         tags:                   {
      #           host_metric: '',
      #           state:       'used',
      #           hostname:    'web.2'
      #         },
      #         human_tags:             ['state: used', 'hostname: web.2'],
      #         name:                   null,
      #         metric_name:            'memory',
      #         field:                  'gauge',
      #         trigger_label:          'Host memory usage',
      #         trigger_description:    'This is a description.',
      #         message:                null,
      #         last_value:             2678.81,
      #         peak_value:             2678.81,
      #         mean_value:             2678.81,
      #         comparison_operator:    '>',
      #         comparison_value:       2560.0,
      #         human_last_value:       '2.62 GB',
      #         human_peak_value:       '2.62 GB',
      #         human_mean_value:       '2.62 GB',
      #         human_comparison_value: '2.5 GB',
      #         created_at:             '2024-04-15T16:10:00Z',
      #         opened_at:              '2024-04-15T16:10:00Z',
      #         resolved_at:            null,
      #         closed_at:              null,
      #         warmup_duration:        0,
      #         cooldown_duration:      0,
      #         alert_url:              'https://appsignal.com/why-18-llc-chiirp/sites/66199d7ed2a5e4a1cf521261/alerts/661d5200d2a5e4a471664aea',
      #         edit_trigger_url:       'https://appsignal.com/why-18-llc-chiirp/sites/66199d7ed2a5e4a1cf521261/triggers?overlay=triggerForm&triggerId=661d51bc2cf81dbaf4973a07',
      #         number:                 449
      #       },
      #       controller: 'integrations/webhook/integrations',
      #       action:     'appsignal'
      #     },
      #     referer:   null
      #   },
      #   chiirp:      { user_id: null, client_id: null }
      # }

      # (GET) show Webhooks & APIs
      # /integrations/webhook/integration
      # integrations_webhook_integration_path
      # integrations_webhook_integration_url
      def show
        respond_to do |format|
          format.js   { render partial: 'integrations/webhooks/js/show', locals: { cards: %w[overview] } }
          format.html { render 'integrations/webhooks/show', locals: { partial_to_show: params.dig(:card).present? ? "integrations/webhooks/#{params[:card]}/index" : '' } }
        end
      end

      private

      def add_or_update_contact(args = {})
        if args.dig(:data_received).is_a?(Hash)
          data_received = args[:data_received].dup
          args[:data_received].each_key do |k|
            data_received[k.delete('[').delete(']')] = data_received.delete(k)
          end
        else
          data_received = {}
        end

        data_received.map { |k, v| data_received[k] = JSON.parse(v) if JSON.is_json?(v) }

        return nil unless args.dig(:webhook).is_a?(::Webhook) && data_received.present?

        # collect external references
        ext_refs = {}

        args[:webhook].webhook_maps.where(internal_key: ::Webhook.internal_key_hash(args[:webhook].client, 'contact', %w[ext_references]).keys).find_each do |webhook_map|
          ext_refs[webhook_map.internal_key.gsub('contact-', '').gsub('-id', '')] = data_received.dig(*webhook_map.external_key.split(':')).to_s if data_received.dig(*webhook_map&.external_key&.split(':')).present?
        end

        # collect phone numbers
        client_phone_labels = args[:webhook].client.contact_phone_labels.map { |label| "phone_#{label}" }
        phones              = {}

        args[:webhook].webhook_maps.where(internal_key: client_phone_labels).find_each do |wm|
          phones[data_received.dig(*wm.external_key.split(':')).to_s.clean_phone(args[:webhook].client.primary_area_code)] = wm.internal_key.gsub('phone_', '') if data_received.dig(*wm.external_key.split(':')).present?
        end

        # collect emails
        emails = []

        args[:webhook].webhook_maps.where(internal_key: 'email').find_each do |wm|
          emails << data_received.dig(*wm.external_key.split(':')).presence
        end

        emails.compact_blank!

        contact = if ext_refs.present? || phones.present? || emails.present?
                    # find or create new Contact with data received
                    Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: args[:webhook].client.id, phones:, emails:, ext_refs:)
                  else
                    args[:webhook].client.contacts.new
                  end

        #
        # ready to update new / existing Contact
        #
        # target_time = nil
        client_custom_fields  = args[:webhook].client.client_custom_fields.pluck(:var_var, :id).to_h
        contact_custom_fields = {}
        tags = []

        # scan through WebhookMaps / update Contact with data received
        args[:webhook].webhook_maps.each do |wm|
          value = data_received.dig(*wm.external_key.split(':')).to_s

          if value.present?

            case wm.internal_key
            when 'yesno'
              # nothing to do here
            when 'fullname'
              fullname = value.parse_name
              contact.firstname = fullname[:firstname]
              contact.lastname  = fullname[:lastname]
            when 'note'
              contact.notes.new(user_id: contact.user_id, note: value)
            when 'datetimel'
              # parse string to time local
              # target_time = Time.use_zone(args[:webhook].client.time_zone) { Chronic.parse(value) }.utc
            when 'datetimez'
              # parse string to time UTC
              # target_time = Chronic.parse(value).utc
            when 'datetimeu'
              # parse string to time UNIX
              # target_time = Time.at(value).utc
            when 'email'
              # email is already applied to Contact
            when 'tag'
              tags << value
            when 'tags'
              tags += value.split(',').map(&:strip)
            when 'nested_fields'
              # ignore data
            else

              if client_phone_labels.include?(wm.internal_key)
                # phone numbers are already applied to Contact
              elsif client_custom_fields.include?(wm.internal_key)
                contact_custom_fields[client_custom_fields[wm.internal_key]] = value.delete(',') # remove commas to maintain compatibility with Custom Fields defined options
              elsif ::Webhook.internal_key_hash(args[:webhook].client, 'contact', %w[ext_references]).key?(wm.internal_key)
                # ext_references are already applied to Contact
              else
                contact.write_attribute(wm.internal_key, value)
              end
            end
          end
        end

        # some data may be received as nil / normalize it
        contact.firstname  = contact.firstname.to_s
        contact.lastname   = contact.lastname.to_s
        contact.address1   = contact.address1.to_s
        contact.address2   = contact.address2.to_s
        contact.city       = contact.city.to_s
        contact.state      = contact.state.to_s
        contact.zipcode    = contact.zipcode.to_s

        if contact.save
          tags.each do |tag_name|
            Contacts::Tags::ApplyByNameJob.perform_now(
              contact_id: contact.id,
              tag_name:
            )
          end

          # save any ContactCustomFields
          contact.update_custom_fields(custom_fields: contact_custom_fields) if contact_custom_fields.present?

          contact.process_actions(
            campaign_id:       args[:webhook].campaign_id,
            group_id:          args[:webhook].group_id,
            stage_id:          args[:webhook].stage_id,
            tag_id:            args[:webhook].tag_id,
            stop_campaign_ids: args[:webhook].stop_campaign_ids
          )

          # scan through WebhookMaps / process Campaigns
          args[:webhook].webhook_maps.each do |wm|
            if wm.response.present? && data_received.dig(*wm.external_key.split(':')).present?
              # if m.internal_key == "yesno" and data_received.has_key? m.external_key

              wm.response.each do |k, v|
                if data_received.dig(*wm.external_key.split(':')).to_s.casecmp?(k)
                  actions = v.split(',')

                  # start new Campaign
                  if actions[0].to_i.positive?
                    Contacts::Campaigns::StartJob.perform_later(
                      campaign_id: actions[0].to_i,
                      client_id:   contact.client_id,
                      contact_id:  contact.id,
                      user_id:     contact.user_id
                    )
                  end

                  Contacts::Tags::ApplyJob.perform_now(
                    contact_id: contact.id,
                    tag_id:     actions[1]
                  )
                end
              end
            end
          end
        end

        contact
      end

      def add_or_update_user(args)
        client        = args.dig(:client)
        webhook       = args.dig(:webhook)
        data_received = args.dig(:data_received)
        user          = nil

        if client.is_a?(Client) && webhook.is_a?(::Webhook) && data_received.is_a?(Hash) && data_received.present?
          webhook_map = webhook.webhook_maps.find_by(internal_key: 'ext_ref_id')
          ext_ref_id  = data_received.dig(webhook_map&.external_key).to_s

          webhook_map = webhook.webhook_maps.find_by(internal_key: 'email')
          email       = data_received.dig(webhook_map&.external_key).to_s

          webhook_map = webhook.webhook_maps.find_by(internal_key: 'phone')
          phone       = data_received.dig(webhook_map&.external_key).to_s

          user   = nil
          user   = client.users.find_by(email:) if email.present?
          user   = client.users.find_by(ext_ref_id:) if user.nil? && ext_ref_id.present?
          user   = client.users.find_by(phone:) if user.nil? && phone.present?
          user ||= client.users.new

          # scan through WebhookMaps / update Contact with data received
          webhook.webhook_maps.each do |m|
            if data_received.key?(m.external_key)

              case m.internal_key
              when 'fullname'
                fullname       = data_received[m.external_key].to_s.parse_name
                user.firstname = fullname[:firstname]
                user.lastname  = fullname[:lastname]
              when 'email'
                user.email = data_received[m.external_key] if user.new_record? || client.users.where(email: data_received[m.external_key]).where.not(id: user.id).empty?
              else
                user.write_attribute(m.internal_key, data_received[m.external_key])
              end
            end
          end

          user.skip_password_validation = true if user.new_record?

          user.save
        end

        user
      end

      def authorize_user!
        super

        return if current_user.access_controller?('integrations', 'client', session) && current_user.client.integrations_allowed.include?('webhook')

        sweetalert_error('Unathorized Access!', 'Your account is NOT authorized to access Webhooks. Please contact your account admin.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def client_api_integration
        return if (@client_api_integration = current_user.client.client_api_integrations.find_or_create_by(target: 'webhook', name: ''))

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end
    end
  end
end
