# frozen_string_literal: true

# app/controllers/notes_controller.rb
class NotesController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user!
  before_action :set_contact
  before_action :set_contact_note, only: %i[destroy edit update]

  # (POST)
  # /contacts/:contact_id/notes
  # contact_notes_path(:contact_id)
  # contact_notes_url(:contact_id)
  def create
    @contact.notes.create(user_id: current_user.id, note: params.dig(:note).to_s)

    respond_to do |format|
      referrer = Rails.application.routes.recognize_path(request.referer)

      if %w[central stages].include?(referrer[:controller]) && referrer[:action] == 'index'
        format.js { render partial: 'notes/js/show', locals: { cards: %w[index contact_profile notes_light_on] } }
        format.html { redirect_to root_path }
      end
    end
  end

  # (DELETE)
  # /contacts/:contact_id/notes/:id
  # contact_note_path(:contact_id, :id)
  # contact_note_url(:contact_id, :id)
  def destroy
    @contact_note.destroy
    referrer = Rails.application.routes.recognize_path(request.referer)

    if %w[central stages].include?(referrer[:controller]) && referrer[:action] == 'index'
      cards = params.dig(:index).to_bool ? %w[index contact_profile] : %w[contact_profile]
      cards << 'notes_light_off' unless @contact.notes.any?
    end

    respond_to do |format|
      if cards.present?
        format.js { render partial: 'notes/js/show', locals: { cards: } }
        format.html { redirect_to root_path }
      end
    end
  end

  # (GET)
  # /contacts/:contact_id/notes/:id/edit
  # edit_contact_note_path(:contact_id, :id)
  # edit_contact_note_url(:contact_id, :id)
  def edit
    respond_to do |format|
      format.js { render partial: 'notes/js/show', locals: { cards: %w[edit] } }
      format.html { redirect_to root_path }
    end
  end

  # (GET)
  # /contacts/:contact_id/notes
  # contact_notes_path(:contact_id)
  # contact_notes_url(:contact_id)
  def index
    respond_to do |format|
      format.js { render partial: 'notes/js/show', locals: { cards: %w[index] } }
      format.html { redirect_to root_path }
    end
  end

  # (PATCH/PUT)
  # /contacts/:contact_id/notes/:id
  # contact_note_path(:contact_id, :id)
  # contact_note_url(:contact_id, :id)
  def update
    @contact_note.update(user_id: current_user.id, note: params.dig(:note).to_s)

    respond_to do |format|
      referrer = Rails.application.routes.recognize_path(request.referer)

      if %w[central stages].include?(referrer[:controller]) && referrer[:action] == 'index'
        format.js { render partial: 'notes/js/show', locals: { cards: %w[index contact_profile] } }
        format.html { redirect_to root_path }
      end
    end
  end

  private

  def set_contact
    contact_id = params.permit(:contact_id).dig(:contact_id).to_i

    return if contact_id.positive? && (@contact = current_user&.client&.contacts&.find_by(id: contact_id))
    return if (@contact = Contact.find_by(id: contact_id)) && current_user&.access_contact?(@contact)

    respond_to do |format|
      format.js { render js: "window.location = '#{root_path}'" and return false }
      format.html { redirect_to root_path and return false }
    end
  end

  def set_contact_note
    return if params.dig(:id).to_i.positive? && (@contact_note = @contact.notes.find_by(id: params[:id]))

    respond_to do |format|
      format.js   { render js: '', layout: false, status: :ok and return }
      format.html { render plain: '', content_type: 'text/plain', layout: false, status: :ok and return }
    end
  end
end
