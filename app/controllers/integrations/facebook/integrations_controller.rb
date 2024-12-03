# frozen_string_literal: true

# app/controllers/integrations/facebook/integrations_controller.rb
module Integrations
  module Facebook
    class IntegrationsController < ApplicationController
      skip_before_action :verify_authenticity_token, only: %i[endpoint logintest longlivetoken platform]
      before_action :authenticate_user!, except: %i[endpoint logintest longlivetoken platform]
      before_action :authorize_user!, except: %i[endpoint logintest longlivetoken platform]
      before_action :user_api_integration, except: %i[endpoint logintest longlivetoken platform sample_facebook_access]
      before_action :user_api_integration_leads, except: %i[endpoint logintest longlivetoken platform sample_facebook_access], if: -> { @user_api_integration&.user&.client&.integrations_allowed&.include?('facebook_leads') }
      before_action :user_api_integration_messenger, except: %i[endpoint logintest longlivetoken platform sample_facebook_access], if: -> { @user_api_integration&.user&.client&.integrations_allowed&.include?('facebook_messenger') }

      # curl app access token
      # curl -X GET "https://graph.facebook.com/oauth/access_token?client_id=1899169686842644&client_secret=0b34867c71735cf3ebc413ae2fdee2d9&redirect_uri=https://dev.tenant.com&grant_type=client_credentials"
      # curl leadgen subscription
      # curl -F "object=page" -F "callback_url=https://dev.tenant.com/facebook/webhooks" -F "fields=leadgen" -F "verify_token=abc123" -F "access_token=1899169686842644|hKvIfB3W6WmTjMqzoZYBP8U56yo" "https://graph.facebook.com/v3.1/1899169686842644/subscriptions"

      # UserApiIntegration data structure
      # {
      #   users: [
      #     {
      #       id:    String,
      #       name:  String,
      #       token: String
      #     }
      #   ],
      #   forms: [
      #     {
      #       id:          String,
      #       user_id:     String,
      #       page_id:     String,
      #       questions:   Hash,
      #       campaign_id: Integer,
      #       group_id:    Integer,
      #       stage_id:    Integer,
      #       tag_id:      Integer
      #     }...
      #   ],
      #   pages: [
      #     {
      #       id:      String,
      #       user_id: String,
      #       name:    String,
      #       token:   String,
      #     }...
      #   ]
      # }

      # (GET/POST)
      # /facebook/endpoint
      # facebook_endpoint_path
      # facebook_endpoint_url
      def endpoint
        if params.dig('hub.mode').to_s == 'subscribe'
          # webhook subscription
          # mode         = params['hub.mode'].to_s
          challenge = params.dig('hub.challenge').to_s
          # verify_token = params.dig('hub.verify_token').to_s

          # logger.debug "Hub Mode Subscribe Params: #{params.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"

          render plain: challenge.empty? ? 'Success' : challenge, content_type: 'text/plain', status: :ok, layout: false
        elsif params.include?(:deauthorize) && params.include?(:signed_request)
          oauth = Koala::Facebook::OAuth.new
          signed_request = oauth.parse_signed_request(params[:signed_request])
          # logger.debug "signed_request: #{signed_request.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"

          if !signed_request.dig('user_id').to_s.empty?
            # User unsubscribed from all Facebook connections

            # remove Facebook "Login with Facebook"
            if (user = User.find_by(provider: 'facebook', uid: signed_request['user_id']))
              user.update(provider: nil, uid: nil)
            end

            # remove Facebook user from UserApiIntegration
            UserApiIntegration.where(target: 'facebook').where('data @> ?', { users: [{ id: signed_request['user_id'] }] }.to_json).find_each do |uai|
              uai.forms.find_all { |f| f.dig('user_id') == signed_request['user_id'] }.each { |f| uai.forms.delete(f) }
              uai.pages.find_all { |p| p.dig('user_id') == signed_request['user_id'] }.each { |p| uai.pages.delete(p) }
              uai.users.find_all { |u| u.dig('id') == signed_request['user_id'] }.each { |u| uai.users.delete(u) }
              uai.save
            end
          elsif !signed_request.dig('profile_id').to_s.empty?
            # User unsubscribed from leads on a Facebook page

            UserApiIntegration.where(target: 'facebook').where('data @> ?', { pages: [{ id: signed_request['user_id'] }] }.to_json).find_each do |uai|
              uai.forms.find_all { |f| f['page_id'] = signed_request['profile_id'].to_s }.each { |form| uai.forms.delete(form) }
              uai.save
            end
          end

          render plain: 'Success', content_type: 'text/plain', status: :ok, layout: false
        elsif params.include?(:delete) && params.include?(:signed_request)
          oauth = Koala::Facebook::OAuth.new
          signed_request = oauth.parse_signed_request(params[:signed_request])
          # logger.debug "Deleted: File: #{__FILE__} - Line: #{__LINE__}"
          # logger.debug "Signed Request: #{signed_request.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"

          render plain: 'Success', content_type: 'text/plain', status: :ok, layout: false
        else
          process_entries(params)

          render plain: 'Success', content_type: 'text/plain', status: :ok, layout: false
        end
      end
      # example: facebook > page > leadgen
      # {
      # 	"object"=>"page",
      # 	"entry"=>[
      # 		{
      # 			"id"=>"0",
      # 			"time"=>1592848778,
      # 			"changes"=>[
      # 				{
      # 					"field"=>"leadgen",
      # 					"value"=>{
      # 						"ad_id"=>"444444444",
      # 						"form_id"=>"444444444444",
      # 						"leadgen_id"=>"444444444444",
      # 						"created_time"=>1592848777,
      # 						"page_id"=>"444444444444",
      # 						"adgroup_id"=>"44444444444"
      # 					}
      # 				}
      # 			]
      # 		}
      # 	]

      # example: Facebook Messenger webhook parameters
      # {
      #   "object"=>"page",
      #   "entry"=>[
      #     {
      #       "id"=>"298964710698004",
      #       "time"=>1640872960199,
      #       "messaging"=>[
      #         {
      #           "sender"=>{"id"=>"1633659450068920"},
      #           "recipient"=>{"id"=>"298964710698004"},
      #           "timestamp"=>1640872959864,
      #           "message"=>{"mid"=>"m_ZHiBBN9frPAYwj9yn2No5U5vGtgKX2NHTZUlhZRvGL1ulsgGMNwh1ADXWl3Xmrz01gZOjzT4JgA4eLys6ELHRg", "text"=>"Test"}
      #         }
      #       ]
      #     }
      #   ]
      # }

      def logintest; end

      def longlivetoken; end

      def platform; end

      # (GET) show Facebook integration
      # /integrations/facebook/integration
      # integrations_facebook_integration_path
      # integrations_facebook_integration_url
      def show
        validate_page_tokens

        respond_to do |format|
          format.js { render partial: 'integrations/facebook/js/show', locals: { cards: %w[show_overview] } }
          format.html { render 'integrations/facebook/show' }
        end
      end

      # get User pages on FB
      def sample_facebook_access
        user = Koala::Facebook::API.new(user_token)
        pages = user.get_connections('me', 'accounts')

        oauth = Koala::Facebook::OAuth.new
        oauth.url_for_oauth_code(permissions: 'manage_pages,leads_retrieval', callback: 'https://dev.chiirp.com/facebook/endpoint')
        # redirect User to generated URL to authorize at FB

        pages.each do |page|
          # {
          # 	"access_token"=>"EAAJ34loVljgBADwrUbx2ixUyAfZBfGJrKfSArZChaPAZA0nseVt00Rtaj2fAX82NwdpZCSXkj9XdODOfT2VZATqb7WoD10lrmsw1jmMr1JZADTTMcZC7pFocwn47SxLve1A3Xh49ZCAK1AM7ZBw9lC57j83IW0eZBbDMBtNrelXIZCh6gZDZD",
          # 	"category"=>"Software Company",
          # 	"category_list"=>[{"id"=>"1065597503495311", "name"=>"Software Company"}],
          # 	"name"=>"Chiirp",
          # 	"id"=>"298964710698004",
          # 	"tasks"=>["ANALYZE", "ADVERTISE", "MODERATE", "CREATE_CONTENT", "MANAGE"]
          # }

          page_data = Koala::Facebook::API.new(access_token)

          # get all forms for page (default fields)
          page_data.graph_call("#{page['id']}/leadgen_forms", {}, 'get', {})
          # [
          #  	{
          #  		"id"=>"320301552296525",
          #  		"leadgen_export_csv_url"=>"https://www.facebook.com/ads/lead_gen/export_csv/?id=320301552296525&type=form&source_type=graph_api",
          #  		"locale"=>"en_US",
          #  		"name"=>"Want a funnel just like this?",
          #  		"status"=>"ACTIVE"
          #  	}
          # ]

          # get all forms for page
          page_data.graph_call("#{page['id']}/leadgen_forms", { fields: 'id,name,status,page,questions' }, 'get', {})
          # [
          # 	{
          # 		"id"=>"320301552296525",
          # 		"name"=>"Want a funnel just like this?",
          # 		"status"=>"ACTIVE",
          # 		"page"=>{
          # 			"name"=>"Chiirp",
          # 			"id"=>"298964710698004"
          # 		},
          # 		"questions"=>[
          # 			{
          # 				"key"=>"yes_i_want_unlimited_leads,_text_me_the_demo_link",
          # 				"label"=>"Yes I want unlimited leads, text me the demo link",
          # 				"options"=>[
          # 					{
          # 						"key"=>"yes",
          # 						"value"=>"Yes"
          # 					},
          # 					{
          # 						"key"=>"no,_i_don't_want_leads",
          # 						"value"=>"No, I don't want leads"
          # 					}
          # 				],
          # 				"type"=>"CUSTOM",
          # 				"id"=>"3241558875910137"
          # 			},
          # 			{
          # 				"key"=>"full_name",
          # 				"label"=>"Full name",
          # 				"type"=>"FULL_NAME",
          # 				"id"=>"482961039178896"
          # 			},
          # 			{
          # 				"key"=>"phone_number",
          # 				"label"=>"Phone number",
          # 				"type"=>"PHONE",
          # 				"id"=>"423342005295624"
          # 			}
          # 		]
          # 	}
          # ]

          # get count of leads for each form
          page_data.graph_call("#{page['id']}/leadgen_forms", { fields: 'leads_count' }, 'get', {})
          # [
          # 	{
          # 		"leads_count"=>17,
          # 		"id"=>"320301552296525"
          # 	}
          # ]

          # get leads for a form
          page_data.graph_call("#{form['id']}/leads", { fields: '' }, 'get', {})
          # [
          #  	{
          #  	 	"created_time"=>"2020-06-29T16:21:10+0000",
          #  	 	"id"=>"708208906688646",
          #  	 	"field_data"=>[
          #  	 		{
          #  	 			"name"=>"yes!_text_me_the_video_right_now!",
          #  	 			"values"=>["yes"]
          #  	 		},
          #  	 		{
          #  	 			"name"=>"full_name",
          #  	 			"values"=>["Yasmin Khalil"]
          #  	 		},
          #  	 		{
          #  	 			"name"=>"phone_number",
          #  	 			"values"=>["+12135727406"]
          #  	 		}
          #  	 	]
          #  	}
          # ]

          # get a lead
          page_data.graph_call(lead_id.to_s, { fields: 'id,form_id,field_data' }, 'get', { api_version: 'v7.0' })
          # {
          # 	"id"=>"2931556360288575",
          # 	"form_id"=>"320301552296525",
          # 	"field_data"=>[
          # 		{
          # 			"name"=>"full_name",
          # 			"values"=>["Mark Hatton"]
          # 		},
          # 		{
          # 			"name"=>"yes_i_want_unlimited_leads,_text_me_the_demo_link",
          # 			"values"=>["yes"]
          # 		},
          # 		{
          # 			"name"=>"phone_number",
          # 			"values"=>["+16027435929"]
          # 		}
          # 	]
          # }

          # subscribe the page to the Chiirp app
          page_data.graph_call("#{page['id']}/subscribed_apps", {}, 'post', {})
          # {
          # 	"success"=>true
          # }

          # get info on subscribed page
          page_data.graph_call("#{page['id']}/subscribed_apps", {}, 'get', {})
          # [
          # 	{
          # 		"category"=>"Business",
          # 		"link"=>"https://dev.chiirp.com/",
          # 		"name"=>"Chiirp - Test1",
          # 		"id"=>"694764011099704"
          # 	}
          # ]

          # unsubscribe the page from the Chiirp app
          page_data.graph_call("#{page['id']}/subscribed_apps", {}, 'delete', {})
          # {
          # 	"success"=>true
          # }
        end

        updates = Koala::Facebook::RealtimeUpdates.new
        updates.list_subscriptions
      end

      private

      def authorize_user!
        super

        return if current_user.access_controller?('integrations', 'user', session) && (current_user.client.integrations_allowed.include?('facebook_leads') || current_user.client.integrations_allowed.include?('facebook_messenger'))

        sweetalert_error('Unathorized Access!', 'Your account is NOT authorized to access Facebook Integration. Please contact your account admin.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{integrations_path}'" and return false }
          format.html { redirect_to integrations_path and return false }
        end
      end

      def process_entries(args)
        object  = args.permit(:object).dig(:object).to_s
        entries = args.dig(:entry).to_a

        return unless %w[page].include?(object) && entries.is_a?(Array)

        begin
          entries.each do |entry|
            entry.dig('changes').to_a.each do |change|
              if change.dig('field').to_s.casecmp?('leadgen')

                UserApiIntegration.where(target: 'facebook', name: 'leads').where('data @> ?', { forms: [page_id: change.dig('value', 'page_id').to_s] }.to_json).where('data @> ?', { forms: [id: change.dig('value', 'form_id').to_s] }.to_json).find_each do |uai|
                  if (form = uai.forms.find_all { |f| f['page_id'] == change.dig('value', 'page_id').to_s }.find { |f| f['id'] == change.dig('value', 'form_id').to_s }) &&
                     !form.filter_map { |_key, values| values if values.is_a?(Hash) }.first.map { |_key, values| values.values }.flatten.delete_if { |x| (x.is_a?(Integer) && x.zero?) || (x.is_a?(String) && x.empty?) }.empty? &&
                     ((uai_pages = uai.user.user_api_integrations.find_by(target: 'facebook', name: '')) && (page = uai_pages.pages.find { |p| p['id'] == change.dig('value', 'page_id').to_s }))

                    lead = Integration::Facebook::Base.new(uai).page_lead(page_token: page['token'], lead_id: change.dig('value', 'leadgen_id'))
                    internal_fields = ::Webhook.internal_key_hash(uai.user.client, 'contact', %w[personal ext_references]).keys
                    custom_field_keys = uai.user.client.client_custom_fields.pluck(:id)

                    # process lead
                    contact_data = { sleep: false }
                    phone_numbers = {}
                    contact_custom_fields = {}
                    emails = []
                    facebook_form = uai.forms.find { |this_form| this_form['id'] == form['id'] }.to_h
                    campaign_ids  = facebook_form.dig('campaign_id')
                    campaign_ids  = campaign_ids&.positive? ? [campaign_ids] : []
                    ok2           = %w[ok2text ok2email]

                    form.dig('questions').to_h.each do |fb_field, values|
                      values.each do |field, value|
                        if field.casecmp?('custom_field_id')

                          if internal_fields.include?(value)
                            emails << (lead.dig(fb_field.to_sym) || '') if value.include?('email')

                            if value == 'fullname'
                              fullname = lead.dig(fb_field.to_sym).to_s.parse_name
                              contact_data[:firstname] = fullname[:firstname]
                              contact_data[:lastname] = fullname[:lastname]
                            else
                              contact_data[value] = lead.dig(fb_field.to_sym) || ''
                            end
                          elsif custom_field_keys.include?(value.to_i)
                            contact_custom_fields[value.to_i] = lead.dig(fb_field.to_sym) || ''
                          elsif value.include?('phone_') && lead.dig(fb_field.to_sym)
                            phone_numbers[(lead.dig(fb_field.to_sym) || '').clean_phone(uai.user.client.primary_area_code)] = value.gsub('phone_', '')
                          elsif ok2.include?(value)
                            contact_data[value.to_sym] = (lead.dig(fb_field.to_sym) || '').is_yes? ? 1 : 0
                          end
                        elsif lead.dig(fb_field.to_sym) == field && value.to_i.positive?
                          campaign_ids << value
                        end
                      end
                    end

                    contact = if phone_numbers.empty? && emails.empty?
                                uai.user.contacts.new
                              else
                                Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: uai.user.client_id, phones: phone_numbers, emails:)
                              end

                    if contact.update(contact_data)
                      # save any ContactCustomFields
                      contact.update_custom_fields(custom_fields: contact_custom_fields) if contact_custom_fields.present?

                      campaign_ids.each do |campaign_id|
                        # start new Campaign
                        Contacts::Campaigns::StartJob.perform_later(
                          campaign_id:,
                          client_id:   contact.client_id,
                          contact_id:  contact.id,
                          user_id:     contact.user_id
                        )
                      end

                      if (group_id = facebook_form.dig('group_id')).to_i.positive?
                        Contacts::Groups::AddJob.perform_later(
                          contact_id: contact.id,
                          group_id:
                        )
                      end

                      if (tag_id = facebook_form.dig('tag_id')).to_i.positive?
                        Contacts::Tags::ApplyJob.perform_later(
                          contact_id: contact.id,
                          tag_id:
                        )
                      end

                      if (stage_id = facebook_form.dig('stage_id')).to_i.positive?
                        Contacts::Stages::AddJob.perform_later(
                          client_id:  contact.client_id,
                          contact_id: contact.id,
                          stage_id:
                        )
                      end
                    end
                  end
                end
              end
            end

            entry.dig(:messaging).to_a.each do |message|
              page_scoped_id = message.dig(:sender, :id).to_s
              page_id        = message.dig(:recipient, :id).to_s
              content        = message.dig(:message, :text).to_s

              UserApiIntegration.where(target: 'facebook', name: '').where('data @> ?', { pages: [id: page_id] }.to_json).find_each do |uai|
                if (page = uai.pages.find { |p| p['id'] == page_id }) && (fb_user = Integrations::FaceBook::Base.new.messenger_user(page.dig('token').to_s, page_scoped_id)) &&
                   (contact = uai.user.client.contacts.joins(:fb_pages).find_by(fb_pages: { page_id:, page_scoped_id:, page_token: page.dig('token').to_s }) || uai.user.client.contacts.find_or_initialize_by(lastname: fb_user.dig(:last_name).to_s, firstname: fb_user.dig(:first_name).to_s))

                  contact.firstname = fb_user.dig(:first_name).to_s if (contact.firstname.blank? || contact.firstname.casecmp?('friend')) && fb_user.dig(:first_name).to_s.present?
                  contact.lastname  = fb_user.dig(:last_name).to_s if (contact.lastname.blank? || contact.lastname.casecmp?('friend')) && fb_user.dig(:last_name).to_s.present?
                  contact.sleep     = false
                  contact.save

                  contact.fb_pages.find_or_create_by(page_id:, page_scoped_id:, page_token: page.dig('token'))

                  unless contact.messages.find_by(from_phone: page_scoped_id, to_phone: page_id, account_sid: page_id, message_sid: message.dig(:message, :mid).to_s)
                    contact_message = contact.messages.create({
                                                                account_sid: page_id,
                                                                automated:   false,
                                                                from_phone:  page_scoped_id,
                                                                message:     content,
                                                                message_sid: message.dig(:message, :mid).to_s,
                                                                msg_type:    'fbin',
                                                                status:      'received',
                                                                to_phone:    page_id
                                                              })
                    image_result = ''

                    (message.dig(:message, :attachments) || []).each do |attachment|
                      if (media_url = attachment.dig(:payload, :url).to_s).present?
                        begin
                          contact_attachment = contact_message.contact.contact_attachments.create!(remote_image_url: media_url)

                          contact_message.attachments.create!(contact_attachment_id: contact_attachment.id) unless contact_attachment.nil?
                        rescue Cloudinary::CarrierWave::UploadError => e
                          image_result = 'Image file upload error'

                          e.set_backtrace(BC.new.clean(caller))

                          Appsignal.report_error(e) do |transaction|
                            # Only needed if it needs to be different or there's no active transaction from which to inherit it
                            Appsignal.set_action('Integrations::Facebook::IntegrationsController#process_entries')

                            # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
                            Appsignal.add_params(args)

                            Appsignal.set_tags(
                              error_level: 'info',
                              error_code:  0
                            )
                            Appsignal.add_custom_data(
                              attachment:,
                              contact_attachment:,
                              contact_message:,
                              e_message:          e.message,
                              error_message:      image_result,
                              media_url:,
                              message:,
                              file:               __FILE__,
                              line:               __LINE__
                            )
                          end
                        rescue ActiveRecord::RecordInvalid => e
                          image_result = e.inspect.include?('Image File size should be less than 5 MB') ? 'Image file too large - Max: 5 MB' : 'Image file upload error'

                          e.set_backtrace(BC.new.clean(caller))

                          Appsignal.report_error(e) do |transaction|
                            # Only needed if it needs to be different or there's no active transaction from which to inherit it
                            Appsignal.set_action('Integrations::Facebook::IntegrationsController#process_entries')

                            # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
                            Appsignal.add_params(args)

                            Appsignal.set_tags(
                              error_level: 'info',
                              error_code:  0
                            )
                            Appsignal.add_custom_data(
                              attachment:,
                              contact_attachment:,
                              contact_message:,
                              e_message:          e.message,
                              error_message:      image_result,
                              media_url:,
                              message:,
                              file:               __FILE__,
                              line:               __LINE__
                            )
                          end
                        rescue StandardError => e
                          image_result = 'Image file upload error'

                          e.set_backtrace(BC.new.clean(caller))

                          Appsignal.report_error(e) do |transaction|
                            # Only needed if it needs to be different or there's no active transaction from which to inherit it
                            Appsignal.set_action('Integrations::Facebook::IntegrationsController#process_entries')

                            # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
                            Appsignal.add_params(args)

                            Appsignal.set_tags(
                              error_level: 'info',
                              error_code:  0
                            )
                            Appsignal.add_custom_data(
                              attachment:,
                              contact_attachment:,
                              contact_message:,
                              e_message:          e.message,
                              error_message:      image_result,
                              media_url:,
                              message:,
                              file:               __FILE__,
                              line:               __LINE__
                            )
                          end
                        end
                      end
                    end

                    contact_message.update(message: "#{content} (#{image_result})") if image_result.length.positive?

                    show_live_messenger = ShowLiveMessenger.new(message: contact_message)
                    show_live_messenger.queue_broadcast_active_contacts
                    show_live_messenger.queue_broadcast_message_thread_message

                    contact_message.notify_users
                  end
                end
              end
            end
          end
        rescue StandardError => e
          e.set_backtrace(BC.new.clean(caller))

          Appsignal.report_error(e) do |transaction|
            # Only needed if it needs to be different or there's no active transaction from which to inherit it
            Appsignal.set_action('Integrations::Facebook::IntegrationsController#process_entries')

            # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
            Appsignal.add_params(args)

            Appsignal.set_tags(
              error_level: 'info',
              error_code:  0
            )
            Appsignal.add_custom_data(
              e_message: e.message,
              object:,
              entries:,
              file:      __FILE__,
              line:      __LINE__
            )
          end
        end
      end

      def user_api_integration
        @user_api_integration ||= current_user.user_api_integrations.find_or_create_by(target: 'facebook', name: '')
      end

      def user_api_integration_leads
        @user_api_integration_leads ||= current_user.user_api_integrations.find_or_create_by(target: 'facebook', name: 'leads')
      end

      def user_api_integration_messenger
        @user_api_integration_messenger ||= current_user.user_api_integrations.find_or_create_by(target: 'facebook', name: 'messenger')
      end

      def validate_page_tokens
        @user_api_integration.users.map(&:deep_symbolize_keys).each do |user|
          pages = Integrations::FaceBook::Base.new(fb_user_id: user.dig(:id), token: user.dig(:token)).user_pages

          pages.each do |page|
            if (uai_page = @user_api_integration.pages.find { |p| p.dig('id') == page.dig(:id) })
              uai_page[:name]  = page.dig(:name).to_s
              uai_page[:token] = page.dig(:token).to_s
            else
              @user_api_integration.pages << page.merge(user_id: user.dig(:id))
            end
          end

          if (uai_leads = current_user.user_api_integrations.find_by(target: 'facebook', name: 'leads'))
            @user_api_integration.pages.find_all { |p| p.dig('user_id') == user.dig(:id) }.each do |uai_page|
              unless pages.find { |p| p.dig(:id) == uai_page.dig('id') }
                @user_api_integration.pages.delete(uai_page)
                uai_leads.forms.find_all { |f| f.dig('page_id') == uai_page.dig('id') }.each { |f| uai_leads.forms.delete(f) }
              end
            end
          end

          @user_api_integration.save
        end
      end
    end
  end
end
