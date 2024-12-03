# frozen_string_literal: true

# app/controllers/api/chiirpapp/v1/contacts/tags_controller.rb
module Api
  module Chiirpapp
    module V1
      module Contacts
        class TagsController < ChiirpappApiController
          before_action :contact

          # (POST) create a new Contacttag
          # /api/chiirpapp/v1/user/:user_id/contact/:contact_id/tags
          # api_chiirpapp_v1_user_contacttags_path(:user_id, :contact_id)
          # api_chiirpapp_v1_user_contacttags_url(:user_id, :contact_id)
          def create
            sanitized_tag_name = params.permit(:tag).dig(:tag).to_s
            contacttag         = if sanitized_tag_name.present?
                                   if (ct = Contacts::Tags::ApplyByNameJob.perform_now(
                                     contact_id: @contact.id,
                                     tag_name:   sanitized_tag_name
                                   )).present?
                                     ct.attributes.merge({ name: ct.tag.name })
                                   else
                                     {}
                                   end
                                 else
                                   {}
                                 end

            render json: contacttag.to_json, layout: false, status: (contacttag.present? ? :ok : :bad_request)
          end

          # (DELETE) delete a Contacttag
          # /api/chiirpapp/v1/user/:user_id/contact/:contact_id/tags/:id
          # api_chiirpapp_v1_user_contacttag_path(:user_id, :contact_id, :id)
          # api_chiirpapp_v1_user_contacttag_url(:user_id, :contact_id, :id)
          def destroy
            @contact.contacttags.where(id: params.dig(:id).to_i)&.destroy_all

            render json: {}, layout: false, status: :ok
          end

          # (GET) return all Contacttags for a Contact
          # /api/chiirpapp/v1/user/:user_id/contact/:contact_id/tags
          # api_chiirpapp_v1_user_contacttags_path(:user_id, :contact_id)
          # api_chiirpapp_v1_user_contacttags_url(:user_id, :contact_id)
          def index
            render json: @contact.contacttags.joins(:tag).select('contacttags.*, tags.name AS name').to_json, layout: false, status: :ok
          end

          # (GET) return a Contacttag
          # /api/chiirpapp/v1/user/:user_id/contact/:contact_id/tags/:id
          # api_chiirpapp_v1_user_contacttag_path(:user_id, :contact_id, :id)
          # api_chiirpapp_v1_user_contacttag_url(:user_id, :contact_id, :id)
          def show
            render json: (contacttag = @contact.contacttags.find_by(id: params.dig(:id).to_i)).present? ? contacttag.attributes.merge({ name: contacttag.tag.name }).to_json : {}, layout: false, status: :ok
          end

          private

          def contact
            render json: { message: 'Contact Not Found' }, layout: false, status: :not_found and return false unless (@contact = @user.client.contacts.find_by(id: params.dig(:contact_id).to_i))
          end
        end
      end
    end
  end
end
