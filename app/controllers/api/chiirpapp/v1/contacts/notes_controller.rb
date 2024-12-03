# frozen_string_literal: true

# app/controllers/api/chiirpapp/v1/contacts/notes_controller.rb
module Api
  module Chiirpapp
    module V1
      module Contacts
        class NotesController < ChiirpappApiController
          before_action :contact

          # (POST) create a new Contacts::Note
          # /api/chiirpapp/v1/user/:user_id/contact/:contact_id/notes
          # api_chiirpapp_v1_user_contact_notes_path(:user_id, :contact_id)
          # api_chiirpapp_v1_user_contact_notes_url(:user_id, :contact_id)
          def create
            sanitized_note = params.permit(:note).dig(:note).to_s
            contact_note = sanitized_note.present? ? @contact.notes.create!(user_id: @user.id, note: sanitized_note) : {}

            render json: contact_note.to_json, layout: false, status: (contact_note.present? ? :ok : :bad_request)
          end

          # (DELETE) delete a Contacts::Note
          # /api/chiirpapp/v1/user/:user_id/contact/:contact_id/notes/:id
          # api_chiirpapp_v1_user_contact_note_path(:user_id, :contact_id, :id)
          # api_chiirpapp_v1_user_contact_note_url(:user_id, :contact_id, :id)
          def destroy
            @contact.notes.find_by(id: params.dig(:id).to_i)&.destroy

            render json: {}, layout: false, status: :ok
          end

          # (GET) return all Contacts::Notes for a Contact
          # /api/chiirpapp/v1/user/:user_id/contact/:contact_id/notes
          # api_chiirpapp_v1_user_contact_notes_path(:user_id, :contact_id)
          # api_chiirpapp_v1_user_contact_notes_url(:user_id, :contact_id)
          def index
            render json: @contact.notes.to_json, layout: false, status: :ok
          end

          # (GET) return a Contacts::Note
          # /api/chiirpapp/v1/user/:user_id/contact/:contact_id/notes/:id
          # api_chiirpapp_v1_user_contact_note_path(:user_id, :contact_id, :id)
          # api_chiirpapp_v1_user_contact_note_url(:user_id, :contact_id, :id)
          def show
            render json: @contact.notes.find_by(id: params.dig(:id).to_i).to_json, layout: false, status: :ok
          end

          # (PUT/PATCH) save Contacts::Note data
          # /api/chiirpapp/v1/user/:user_id/contact/:contact_id/notes/:id
          # api_chiirpapp_v1_user_contact_note_path(:user_id, :contact_id, :id)
          # api_chiirpapp_v1_user_contact_note_url(:user_id, :contact_id, :id)
          def update
            if (contact_note = @contact.notes.find_by(id: params.dig(:id).to_i))
              contact_note.update(
                user_id: @user.id,
                note:    params.permit(:note).dig(:note).to_s
              )
            end

            render json: contact_note.to_json, layout: false, status: :ok
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
