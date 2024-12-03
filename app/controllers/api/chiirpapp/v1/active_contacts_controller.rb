# frozen_string_literal: true

# app/controllers/api/chiirpapp/v1/active_contacts_controller.rb
module Api
  module Chiirpapp
    module V1
      class ActiveContactsController < ChiirpappApiController
        before_action :user_settings

        # (GET) return ActiveContacts array
        # /api/chiirpapp/v1/user/:user_id/active_contacts
        # api_chiirpapp_v1_user_active_contacts_path(:user_id)
        # api_chiirpapp_v1_user_active_contacts_url(:user_id)
        def index
          sanitized_params = params.permit(:page, :per_page, :search)

          active_contacts_list_args = {
            group_id:          0,
            include_automated: @user_settings.data.dig(:include_automated).to_bool,
            include_sleeping:  false,
            msg_types:         @user_settings.data.dig(:msg_types),
            past_days:         15
          }

          result = @user_settings.contacts_list_clients_users(controller: 'central', user: @user, client: @user.client)
          active_contacts_list_args[:client_ids] = result[:client_ids]
          active_contacts_list_args[:user_ids]   = result[:user_ids]

          active_contacts_list = @user.active_contacts_list(active_contacts_list_args:, page: sanitized_params.dig(:page), per_page: sanitized_params.dig(:per_page))

          if sanitized_params.dig(:search).present?
            search        = sanitized_params[:search].split
            clients_users = @user_settings.contacts_list_clients_users(controller: 'my_contacts', user: @user)
            search_fields = %w[firstname lastname email contact_phones.phone]

            contacts = Contact.where(user_id: clients_users[:user_ids]).or(Contact.where(client_id: clients_users[:client_ids])) if clients_users.dig(:user_ids).present? || clients_users.dig(:client_ids).present?
            contacts = contacts.left_joins(:contact_phones).where(sleep: false).where(block: false).group('contacts.id')

            if search.length == 1
              contacts = contacts.where('firstname ilike ? or lastname ilike ? or email ilike ? or contact_phones.phone ilike ?', "%#{search[0]}%", "%#{search[0]}%", "%#{search[0]}%", "%#{search[0]}%").page([sanitized_params.dig(:page).to_i, 1].max).per([sanitized_params.dig(:per_page).to_i, 10].max)
            elsif search.length == 2
              contacts = contacts.where('(firstname ilike ? and lastname ilike ?) or (firstname ilike ? and lastname ilike ?) or (email ilike ? and email ilike ?) or (contact_phones.phone ilike ? and contact_phones.phone ilike ?)', "%#{search[0]}%", "%#{search[1]}%", "%#{search[1]}%", "%#{search[0]}%", "%#{search[0]}%", "%#{search[1]}%", "%#{search[0]}%", "%#{search[1]}%").page([sanitized_params.dig(:page).to_i, 1].max).per([sanitized_params.dig(:per_page).to_i, 10].max)
            elsif search.length > 2
              query_segments = []
              query_params   = []

              search.each do |s|
                search_fields.each do |f|
                  query_segments << "#{f} ilike ?"
                  query_params   << "%#{s}%"
                end
              end

              contacts = contacts.where(query_segments.join(' or '), *query_params).page([sanitized_params.dig(:page).to_i, 1].max).per([sanitized_params.dig(:per_page).to_i, 10].max)
            end

            active_contacts_list = active_contacts_list.select { |c| contacts.pluck(:id).include?(c.id) }.map { |contact| { contact_id: contact.id, firstname: contact.firstname, lastname: contact.lastname, created_at: contact.tw_created_at, message: contact.tw_message.presence || ((message = Messages::Message.find_by(id: contact.tw_id)) && message&.attachments&.any? ? 'Image' : 'No Messages') } }
          else
            active_contacts_list = active_contacts_list.map { |contact| { contact_id: contact.id, firstname: contact.firstname, lastname: contact.lastname, created_at: contact.tw_created_at, message: contact.tw_message.presence || ((message = Messages::Message.find_by(id: contact.tw_id)) && message&.attachments&.any? ? 'Image' : 'No Messages') } }
          end

          render json: active_contacts_list.to_json, layout: false, status: :ok
        end
      end
    end
  end
end
