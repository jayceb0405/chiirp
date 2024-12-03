# frozen_string_literal: true

# app/controllers/api/v1/zapiers_controller.rb
module Api
  module V1
    class ZapiersController < ApiController
      skip_before_action :verify_authenticity_token
      before_action :set_user

      # (GET) respond with a list of campaigns & IDs
      # /api/v1/zapier/campaigns/:token
      # api_v1_zapier_campaigns_url(:token)
      # api_v1_zapier_campaigns_path(:token)
      def campaigns
        response = [{ 'campaign_id_trigger' => 0, 'campaign_name_trigger' => 'Do Not Start a Campaign' }]

        @user.client.campaign_collection([]).each do |c|
          response << { 'campaign_id_trigger' => c.id, 'campaign_name_trigger' => c.name }
        end

        render json: response.to_json
      end

      # (POST) receive a new Contact to add or update
      # /api/v1/zapier/contact_rcv/:token
      # api_v1_zapier_contact_rcv_url(:token)
      # api_v1_zapier_contact_rcv_path(:token)
      def contact_rcv
        phone      = params.dig(:phone).to_s.clean_phone(@user.client.primary_area_code)
        email      = params.dig(:email).to_s.split(%r{[\s,;]})[0].to_s
        ext_ref_id = params.dig(:ext_ref_id).to_s
        response   = { status: 200, message: 'Success' }

        if (phone.present? && phone != '5555555555' && phone != '8888888888') || email.present? || ext_ref_id.present?
          # received phone number
          contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: @user.client_id, phones: { phone => 'mobile' }, emails: [email], ext_refs: { 'zapier' => ext_ref_id })

          begin
            birthdate = params.dig(:birthdate).to_s.present? ? Date.parse(params.dig(:birthdate).to_s) : contact.birthdate
          rescue ArgumentError
            birthdate = nil
          end

          if params.dig(:fullname).to_s.present?
            fullname  = params[:fullname].to_s.parse_name
            firstname = fullname[:firstname].presence || contact.firstname
            lastname  = fullname[:lastname].presence || contact.lastname
          else
            firstname = params.dig(:firstname).to_s.presence || contact.firstname
            lastname  = params.dig(:lastname).to_s.presence || contact.lastname
          end

          alt_phone = params.dig(:alt_phone).to_s.clean_phone(@user.client.primary_area_code)

          if contact.update(
            lastname:,
            firstname:,
            address1:  params.dig(:address1).to_s.presence || contact.address1,
            address2:  params.dig(:address2).to_s.presence || contact.address2,
            city:      params.dig(:city).to_s.presence || contact.city,
            state:     params.dig(:state).to_s.presence || contact.state,
            zipcode:   params.dig(:zipcode).to_s.presence || contact.zipcode,
            email:     EmailAddress.valid?(email) ? EmailAddress.normal(email) : '',
            birthdate:,
            ok2text:   params.dig(:ok2text).nil? || params.dig(:ok2text).to_s.is_yes? ? '1' : '0',
            ok2email:  params.dig(:ok2email).nil? || params.dig(:ok2email).to_s.is_yes? ? '1' : '0'
          )

            contact.contact_phones.create(phone: alt_phone, label: 'other') if alt_phone.present?

            if params.dig(:custom_fields).to_s.present?

              params[:custom_fields].split(',').each do |custom_field|
                # split up the fields
                custom_field_split     = custom_field.split(':')
                custom_field_var_var   = custom_field_split.present? ? custom_field_split[0].to_s.downcase : ''
                custom_field_split.delete(custom_field_var_var)
                custom_field_var_value = custom_field_split.join(':')
                # custom_field_var_value = custom_field.length > 1 ? custom_field[1].to_s.downcase : ''

                if custom_field_var_var.present? && (client_custom_field = contact.client.client_custom_fields.find_by(var_var: custom_field_var_var))
                  # ClientCustomField was found / save a ContactCustomField
                  contact_custom_field = contact.contact_custom_fields.find_or_initialize_by(client_custom_field_id: client_custom_field.id)
                  contact_custom_field.update(var_value: custom_field_var_value)
                end
              end
            end

            contact.notes.create(user_id: contact.user_id, note: params[:notes].to_s) if params.include?(:notes)

            target_time = nil

            target_time = Time.use_zone(@user.client.time_zone) { Chronic.parse(params[:target_date_local]) } if params.dig(:target_date_local).to_s.present?

            target_time = Chronic.parse(params[:target_date_utc]) if params.dig(:target_date_utc).to_s.present?

            target_time = target_time.utc unless target_time.nil?

            if params.dig(:campaign_id_yes).to_i.positive? && contact.ok2text.to_i.positive?
              # Campaign was assigned
              Contacts::Campaigns::StartJob.perform_later(
                campaign_id: params[:campaign_id_yes],
                client_id:   contact.client_id,
                contact_id:  contact.id,
                target_time:,
                user_id:     contact.user_id
              )
            end

            if params.dig(:campaign_id_no).to_i.positive? && contact.ok2text.to_i.zero?
              # Campaign was assigned
              Contacts::Campaigns::StartJob.perform_later(
                campaign_id: params[:campaign_id_no],
                client_id:   contact.client_id,
                contact_id:  contact.id,
                target_time:,
                user_id:     contact.user_id
              )
            end

            if params.dig(:group_id_yes).to_i.positive? && contact.ok2text.to_i.positive?
              # Group was assigned
              Contacts::Groups::AddJob.perform_now(
                contact_id: contact.id,
                group_id:   params[:group_id_yes]
              )
            end

            if params.dig(:group_id_no).to_i.positive? && contact.ok2text.to_i.zero?
              # Group was assigned
              Contacts::Groups::AddJob.perform_now(
                contact_id: contact.id,
                group_id:   params[:group_id_no]
              )
            end

            if params.dig(:tag_id_yes).to_i.positive? && contact.ok2text.to_i.positive?
              # Tag was assigned
              Contacts::Tags::ApplyJob.perform_now(
                contact_id: contact.id,
                tag_id:     params[:tag_id_yes]
              )
            end

            if params.dig(:tag_id_no).to_i.positive? && contact.ok2text.to_i.zero?
              # Tag was assigned
              Contacts::Tags::ApplyJob.perform_now(
                contact_id: contact.id,
                tag_id:     params[:tag_id_no]
              )
            end
          else
            # Contact was NOT updated/created
            Users::SendPushOrTextJob.perform_later(
              title:      'Contact received from Zapier.',
              content:    "Unable to add #{fullname} with phone number #{ActionController::Base.helpers.number_to_phone(phone)}.",
              from_phone: I18n.t("tenant.#{Rails.env}.phone_number"),
              to_phone:   contact.user.phone,
              user_id:    contact.user_id
            )
          end
        end

        respond_to do |format|
          format.json { render json: { message: response[:message], status: response[:status] } }
          format.html { render plain: response[:message], content_type: 'text/plain', layout: false, status: response[:status] }
        end
      end
      # Example Parameters:
      #   "firstname"=>"John",
      #   "lastname"=>"Doe",
      #   "fullname"=>"John Doe",
      #   "phone"=>"8025554012",
      #   "email"=>"john.doe@chiirp.com",
      #   "birthdate"=>"2000-01-31T00:00:00-05:00",
      #   "ok2text"=>true,
      #   "ok2email"=>true,
      #   "campaign_id"=>8,
      #   "tag_id"=>47,
      #   "token"=>"76bf48dd919feaa55d1dc13bbcf6ef98f5fccd8c5241fca689521fefc0991748",
      #   "zapier"=>{
      #     "firstname"=>"John",
      #     "lastname"=>"Doe",
      #     "fullname"=>"John Doe",
      #     "phone"=>"8025554012",
      #     "email"=>"john.doe@chiirp.com",
      #     "birthdate"=>"2000-01-31T00:00:00-05:00",
      #     "ok2text"=>true,
      #     "ok2email"=>true,
      #     "campaign_id"=>8,
      #     "tag_id"=>47
      #   }
      #

      # (GET) Zapier requests placeholder data
      # /api/v1/zapier/contacts/:token
      # api_v1_zapier_contacts_url(:token)
      # api_v1_zapier_contacts_path(:token)
      def contacts
        response = []

        # select most recent 5 Contacts
        if (contacts = @user.contacts.order(updated_at: :desc).limit(5))

          contacts.each do |contact|
            # ContactCustomFields: "Name:Value,Name:Value,Name:Value"
            contacttag = contact.contacttags.first
            tag_id     = contacttag ? contacttag.tag_id : 0
            tag_name   = contacttag ? contacttag.tag.name : 'No Tags Assigned'

            response << {
              user_name:             @user.fullname.to_s,
              user_id:               @user.id.to_s,
              lastname:              contact.lastname.to_s,
              firstname:             contact.firstname.to_s,
              fullname:              contact.fullname.to_s,
              address1:              contact.address1.to_s,
              address2:              contact.address2.to_s,
              city:                  contact.city.to_s,
              state:                 contact.state.to_s,
              zipcode:               contact.zipcode.to_s,
              phone:                 contact.primary_phone&.phone.to_s,
              alt_phone:             contact.contact_phones.find_by(primary: false)&.phone.to_s,
              phone_was:             contact.primary_phone&.phone.to_s,
              email:                 contact.email.to_s,
              birthdate:             (contact.birthdate ? contact.birthdate.strftime('%Y/%m/%d') : ''),
              ok2text:               (contact.ok2text.to_i == 1 ? 'yes' : 'no'),
              ok2email:              (contact.ok2email.to_i == 1 ? 'yes' : 'no'),
              ext_ref_id:            (contact.ext_references.find_by(target: 'zapier')&.ext_id || contact.id).to_s,
              last_updated:          contact.updated_at.in_time_zone(contact.client.time_zone).strftime('%Y/%m/%d %T'),
              last_contacted:        (contact.last_contacted ? contact.last_contacted.in_time_zone(contact.client.time_zone).strftime('%Y/%m/%d %T') : ''),
              custom_fields:         contact.contact_custom_fields.joins(:client_custom_field).pluck('client_custom_fields.var_name', :var_value).map { |x| x.join(':') }.join(','),
              # rubocop:disable Rails/OutputSafety
              notes:                 contact.notes.pluck(:note).join(', ').html_safe,
              tags:                  contact.tags.pluck(:name).join(',').html_safe,
              # rubocop:enable Rails/OutputSafety
              tag_id:,
              tag:                   tag_name,
              trusted_form_token:    contact.trusted_form&.dig(:token),
              trusted_form_cert_url: contact.trusted_form&.dig(:cert_url),
              trusted_form_ping_url: contact.trusted_form&.dig(:ping_url)
            }
          end
        end

        render json: response.to_json
      end

      # (GET) respond with a list of available fields & IDs
      # /api/v1/zapier/fields/:token
      # api_v1_zapier_fields_url(:token)
      # api_v1_zapier_fields_path(:token)
      def fields
        response = []

        ::Webhook.internal_key_hash(@user.client, 'contact').each do |key, value|
          response << { 'field_id_trigger' => key, 'field_name_trigger' => value }
        end

        render json: response.to_json
      end

      # (GET) respond with a list of groups & IDs
      # /api/v1/zapier/groups/:token
      # api_v1_zapier_groups_url(:token)
      # api_v1_zapier_groups_path(:token)
      def groups
        response = [{ 'group_id_trigger' => 0, 'group_name_trigger' => 'Do Not Apply a Group' }]

        @user.client.group_collection([]).each do |g|
          response << { 'group_id_trigger' => g.id, 'group_name_trigger' => g.name }
        end

        render json: response.to_json
      end

      # (POST) Zapier registers a subscription
      # /api/v1/zapier/subscribe/:token
      # api_v1_zapier_register_subscription_url(:token)
      # api_v1_zapier_register_subscription_path(:token)
      def register_subscription
        event            = %w[receive_new_contact receive_updated_contact receive_new_tag receive_remove_tag].include?(params.dig(:event).to_s.downcase) ? params[:event].to_s.downcase : ''
        subscription_url = params.dig(:subscription_url).to_s
        response         = { status: 400, message: 'Fail' }

        if event.present? && subscription_url.present?
          @user.user_api_integrations.find_or_create_by(target: 'zapier', name: event, data: { zapier_subscription_url: subscription_url })
          response = { status: 200, message: 'Success' }
        end

        respond_to do |format|
          format.json { render json: { message: response[:message], status: response[:status] } }
          format.html { render plain: response[:message], content_type: 'text/plain', layout: false, status: response[:status] }
        end
      end
      # Example Parameters:
      #   "subscription_url"=>"https://hooks.zapier.com/hooks/standard/3645098/6202d1a772c94cbf922b5e770f2f9869/",
      #   "target_url"=>"https://hooks.zapier.com/hooks/standard/3645098/6202d1a772c94cbf922b5e770f2f9869/",
      #   "event"=>"receive_new_contact",
      #   "token"=>"d84db4b9df915907fa2982821213640ff9f57075f73d8191c3c1dcefc3a12a79",
      #   "zapier"=>{
      #     "subscription_url"=>"https://hooks.zapier.com/hooks/standard/3645098/6202d1a772c94cbf922b5e770f2f9869/",
      #     "target_url"=>"https://hooks.zapier.com/hooks/standard/3645098/6202d1a772c94cbf922b5e770f2f9869/",
      #     "event"=>"receive_new_contact"
      #   }
      #

      # (POST) Zapier registers an unsubscription
      # /api/v1/zapier/unsubscribe/:token
      # api_v1_zapier_register_unsubscription_url(:token)
      # api_v1_zapier_register_unsubscription_path(:token)
      def register_unsubscription
        event            = %w[receive_new_contact receive_updated_contact receive_new_tag receive_remove_tag].include?(params.dig(:event).to_s.downcase) ? params[:event].to_s.downcase : ''
        subscription_url = params.dig(:subscription_url).to_s
        response         = { status: 400, message: 'Fail' }

        if event.present? && subscription_url.present?
          if (user_api_integration = @user.user_api_integrations.find_by(target: 'zapier', name: event, data: { zapier_subscription_url: subscription_url }))
            user_api_integration.destroy
          end

          response = { status: 200, message: 'Success' }
        end

        respond_to do |format|
          format.json { render json: { message: response[:message], status: response[:status] } }
          format.html { render plain: response[:message], content_type: 'text/plain', layout: false, status: response[:status] }
        end
      end
      # Example Parameters:
      #   "subscription_url"=>"https://hooks.zapier.com/hooks/standard/3645098/6202d1a772c94cbf922b5e770f2f9869/",
      #   "target_url"=>"https://hooks.zapier.com/hooks/standard/3645098/6202d1a772c94cbf922b5e770f2f9869/",
      #   "event"=>"receive_new_contact",
      #   "token"=>"d84db4b9df915907fa2982821213640ff9f57075f73d8191c3c1dcefc3a12a79",
      #   "zapier"=>{
      #     "subscription_url"=>"https://hooks.zapier.com/hooks/standard/3645098/6202d1a772c94cbf922b5e770f2f9869/",
      #     "target_url"=>"https://hooks.zapier.com/hooks/standard/3645098/6202d1a772c94cbf922b5e770f2f9869/",
      #     "event"=>"receive_new_contact"
      #   }

      # (GET) respond with a list of tags & IDs
      # /api/v1/zapier/tags/:token
      # api_v1_zapier_tags_url(:token)
      # api_v1_zapier_tags_path(:token)
      def tags
        response = [{ 'tag_id_trigger' => 0, 'tag_name_trigger' => 'Do Not Apply a Tag' }]

        @user.client.tag_collection([]).each do |t|
          response << { 'tag_id_trigger' => t.id, 'tag_name_trigger' => t.name }
        end

        render json: response.to_json
      end

      private

      def set_user
        oauth_access_token = OauthAccessToken.find_by(token: Doorkeeper::SecretStoring::Sha256Hash.method(:transform_secret).call(params[:token]))

        if oauth_access_token && !oauth_access_token.user.suspended? && oauth_access_token.user.client.active?
          # OauthAccessToken was found

          @user = oauth_access_token.user
        else
          # OauthAccessToken was NOT found
          respond_to do |format|
            format.json { render json: { message: 'Unable to locate Agent.', status: 404 } and return false }
            format.html { render plain: 'Unable to locate Agent.', content_type: 'text/plain', layout: false, status: :not_found and return false }
          end
        end
      end
    end
  end
end
