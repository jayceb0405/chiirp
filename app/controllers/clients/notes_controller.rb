# frozen_string_literal: true

# app/controllers/clients/notes_controller.rb
module Clients
  class NotesController < Clients::ClientController
    before_action :authenticate_user!
    before_action :authorize_user!
    before_action :client
    before_action :note, only: %i[edit destroy update]

    # (POST) save a newly created note
    # /clients/:client_id/notes
    # client_notes_path(:client_id)
    # client_notes_url(:client_id)
    def create
      @client.notes.create(params_note.merge({ user_id: current_user.agency_user_logged_in_as(session)&.id || current_user.id }))

      render partial: 'clients/notes/js/show', locals: { cards: %w[index] }
    end

    # (GET) display a note to edit
    # /clients/:client_id/notes/:id/edit
    # edit_client_note_path(:client_id, :id)
    # edit_client_note_url(:client_id, :id)
    def edit
      render partial: 'clients/notes/js/show', locals: { cards: %w[edit] }
    end

    # (DELETE) destroy a note
    # /clients/:client_id/notes/:id
    # client_note_path(:client_id, :id)
    # client_note_url(:client_id, :id)
    def destroy
      @note.destroy

      render partial: 'clients/notes/js/show', locals: { cards: %w[index] }
    end

    # (GET) list all notes for Client in a modal
    # /clients/:client_id/notes
    # client_notes_path(:client_id)
    # client_notes_url(:client_id)
    def index
      render partial: 'clients/notes/js/show', locals: { cards: %w[dash_modal_show index] }
    end

    # (GET) start a new note
    # /clients/:client_id/notes/new
    # new_client_note_path(:client_id)
    # new_client_note_url(:client_id)
    def new
      @note = @client.notes.new

      render partial: 'clients/notes/js/show', locals: { cards: %w[new] }
    end

    # (PATCH/PUT) save updated note
    # /clients/:client_id/notes/:id
    # client_note_path(:client_id, :id)
    # client_note_url(:client_id, :id)
    def update
      @note.update(params_note)

      render partial: 'clients/notes/js/show', locals: { cards: %w[index] }
    end

    private

    def authorize_user!
      return if current_user.team_member? || current_user.agency_user_logged_in_as(session)&.team_member?
      return if current_user.agency_user_logged_in_as(session) && (render js: "window.location = '#{user_return_to_self_path(current_user.agency_user_logged_in_as(session)&.id)}'" and return false)

      raise ExceptionHandlers::UserNotAuthorized.new('Client Notes', root_path)
    end

    def client
      return if (@client = Client.find_by(id: params[:client_id].to_i))

      sweetalert_error('Client NOT found!', 'We were not able to access the client you requested.', '', { persistent: 'OK' }) if current_user.team_member?

      render partial: 'clients/notes/js/show', locals: { cards: %w[] }
    end

    def note
      return if (@note = @client.notes.find_by(id: params.dig(:id).to_i))

      sweetalert_error('Note NOT found!', 'The requested note was NOT found.', '', { persistent: 'OK' })

      render partial: 'clients/notes/js/show', locals: { cards: %w[] }
    end

    def params_note
      params.require(:clients_note).permit(:note)
    end
  end
end
