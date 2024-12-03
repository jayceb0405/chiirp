# frozen_string_literal: true

# app/controllers/api/chiirpapp/v1/contacts_controller.rb
module Api
  module Chiirpapp
    module V1
      class ContactsController < ChiirpappApiController
        # (POST) create a new Contact
        # /api/chiirpapp/v1/user/:user_id/contacts
        # api_chiirpapp_v1_user_contacts_path(:user_id)
        # api_chiirpapp_v1_user_contacts_url(:user_id)
        def create
          create_or_update_contact(contact_params)

          render json: contact_json, layout: false, status: :ok
        end

        # (DELETE) delete a Contact
        # /api/chiirpapp/v1/user/:user_id/contacts/:id
        # api_chiirpapp_v1_user_contact_path(:user_id, :id)
        # api_chiirpapp_v1_user_contact_url(:user_id, :id)
        def destroy
          id = params.permit(:id).dig(:id).to_i

          @user.client.contacts.find_by(id:)&.destroy if id.positive?

          render json: {}, layout: false, status: :ok
        end

        # (GET) return all Contacts
        # /api/chiirpapp/v1/user/:user_id/contacts
        # api_chiirpapp_v1_user_contacts_path
        # api_chiirpapp_v1_user_contacts_url
        def index
          sanitized_params = params.permit(:firstname, :lastname, :search_string, :user_client)

          @contacts = if sanitized_params.dig(:user_client).to_s.casecmp?('client')
                        @user.client.contacts
                      else
                        @user.contacts
                      end

          @contacts = if sanitized_params.dig(:firstname).present? || sanitized_params.dig(:lastname).present? || sanitized_params.dig(:search_string).present?
                        @contacts.string_search(sanitized_params.dig(:search_string), sanitized_params.dig(:firstname), sanitized_params.dig(:lastname))
                      else
                        @contacts
                      end

          @contacts = @contacts.select(:id, :lastname, :firstname, :companyname, :address1, :address2, :city, :state, :zipcode, :birthdate, :user_id, :client_id, :ok2text, :ok2email, :sleep, :block, :last_contacted, :lead_source_id)

          render json: @contacts.to_json, layout: false, status: :ok
        end

        # (GET) return Contact data
        # /api/chiirpapp/v1/user/:user_id/contacts/:id
        # api_chiirpapp_v1_user_contact_path(:user_id, :id)
        # api_chiirpapp_v1_user_contact_url(:user_id, :id)
        def show
          sanitized_params = params.permit(:id)

          @contact = @user.client.contacts.find_by(id: sanitized_params.dig(:id))

          render json: contact_json, layout: false, status: :ok
        end

        # (PUT/PATCH) save Contact data
        # /api/chiirpapp/v1/user/:user_id/contacts/:id
        # api_chiirpapp_v1_user_contact_path(:user_id, :id)
        # api_chiirpapp_v1_user_contact_url(:user_id, :id)
        def update
          create_or_update_contact(contact_params)

          render json: contact_json, layout: false, status: :ok
        end

        private

        def contact_json
          Contact.where(id: @contact&.id)
                 &.select(:id, :lastname, :firstname, :companyname, :address1, :address2, :city, :state, :zipcode, :birthdate, :user_id, :client_id, :ok2text, :ok2email, :sleep, :block, :last_contacted, :lead_source_id)
                 &.select('"users"."lastname" AS user_lastname, "users"."firstname" AS user_firstname, "clients_lead_sources"."name" AS lead_source_name')
                 &.left_joins(:user, :lead_source)
                 &.first
                 &.attributes
                 &.merge({ 'phones' => @contact&.contact_phones&.select(:id, :phone, :label, :primary)&.map(&:attributes) })
                 &.merge({ 'tags' => @contact&.contacttags&.select(:id, :tag_id)&.select('"tags"."name" AS tag_name')&.joins(:tag)&.map(&:attributes) })
                 &.merge({ 'notes' => @contact&.notes&.select(:id, :user_id, :note, :created_at)&.select('"users"."lastname" AS user_lastname, "users"."firstname" AS user_firstname')&.joins(:user)&.map(&:attributes) })
                 &.merge({ 'ext_references' => @contact&.ext_references&.select(:id, :ext_id, :target)&.map(&:attributes) }).to_json
        end

        def contact_params
          params.permit(:address1, :address2, :birthdate, :city, :delete_unfound, :email, :firstname, :id, :lastname, :ok2email, :ok2text, :state, :update_primary, :zipcode, phones: %i[phone label primary])
        end

        def create_or_update_contact(args = {})
          Rails.logger.info "API::Chiirpapp::V1::ContactsController#create_or_update_contact: #{{ args: }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
          phones = (args.dig(:phones).is_a?(Array) ? args[:phones].map { |p| p.permit(:phone, :label, :primary) } : []).map { |p| p.respond_to?(:dig) && p.dig(:phone) && p.dig(:label) ? [p[:phone].to_s.clean_phone(@user.client.primary_area_code), p[:label].to_s, p.dig(:primary).to_bool] : nil }.compact_blank
          email  = args.dig(:email).to_s.split(%r{[\s,;]})[0]
          id     = args.dig(:id).to_i

          return unless id.positive? || phones.present? || email.present?

          @contact = @user.client.contacts.find_by(id:) || Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: @user.client_id, phones:, emails: [email])

          if args.dig(:fullname).to_s.present?
            fullname  = args[:fullname].to_s.parse_name
            firstname = fullname[:firstname].presence || @contact.firstname
            lastname  = fullname[:lastname].presence || @contact.lastname
          else
            firstname = args.dig(:firstname).to_s.presence || @contact.firstname
            lastname  = args.dig(:lastname).to_s.presence || @contact.lastname
          end

          @contact.update(
            lastname:,
            firstname:,
            address1:  args.dig(:address1).to_s.presence || @contact.address1,
            address2:  args.dig(:address2).to_s.presence || @contact.address2,
            city:      args.dig(:city).to_s.presence || @contact.city,
            state:     args.dig(:state).to_s.presence || @contact.state,
            zipcode:   args.dig(:zipcode).to_s.presence || @contact.zipcode,
            email:     EmailAddress.valid?(email) ? EmailAddress.normal(email) : '',
            birthdate: Time.use_zone(@user.client.time_zone) { Chronic.parse(args.dig(:birthdate).to_s) },
            ok2text:   args.dig(:ok2text).nil? || args.dig(:ok2text).to_s.is_yes? ? '1' : '0',
            ok2email:  args.dig(:ok2email).nil? || args.dig(:ok2email).to_s.is_yes? ? '1' : '0'
          )

          @contact.update_contact_phones(phones, args.dig(:delete_unfound).to_bool, args.dig(:update_primary).to_bool)
        end
      end
    end
  end
end
