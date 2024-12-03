# frozen_string_literal: true

# app/controllers/clients/folders_controller.rb
module Clients
  class FoldersController < Clients::ClientController
    before_action :authenticate_user!
    before_action :client
    before_action :authorize_user!
    before_action :set_folder, only: %i[destroy edit update]

    def create
      # (POST)
      # /client/:client_id/folders
      # client_folders_path(:client_id)
      # client_folders_url(:client_id)
      @folder = current_user.client.folders.create(params_folder)

      respond_to do |format|
        format.js   { render partial: 'clients/js/show', locals: { cards: %w[folders] } }
        format.html { redirect_to root_path }
      end
    end

    def destroy
      # (DELETE)
      # /client/:client_id/folders/:id
      # client_folder_path(:client_id, :id)
      # client_folder_url(:client_id, :id)
      @folder.destroy
      @folder = nil

      respond_to do |format|
        format.js   { render partial: 'clients/js/show', locals: { cards: %w[folders] } }
        format.html { redirect_to root_path }
      end
    end

    def edit
      # (GET)
      # /client/:client_id/folders/:id/edit
      # edit_client_folder_path(:client_id, :id)
      # edit_client_folder_url(:client_id, :id)
      respond_to do |format|
        format.js   { render partial: 'clients/js/show', locals: { cards: %w[folders_edit] } }
        format.html { redirect_to root_path }
      end
    end

    def index
      # (GET)
      # /client/:client_id/folders
      # client_folders_path(:client_id)
      # client_folders_url(:client_id)
      respond_to do |format|
        format.js   { render partial: 'clients/js/show', locals: { cards: %w[folders] } }
        format.html { render 'clients/show', locals: { client_page_section: 'folders' } }
      end
    end

    def new
      # (GET)
      # /client/:client_id/folders/new
      # new_client_folder_path(:client_id)
      # new_client_folder_url(:client_id)
      @folder = current_user.client.folders.new

      respond_to do |format|
        format.js   { render partial: 'clients/js/show', locals: { cards: ['folders'] } }
        format.html { redirect_to root_path }
      end
    end

    def update
      # (PUT/PATCH)
      # /client/:client_id/folders/:id
      # client_folder_path(:client_id, :id)
      # client_folder_url(:client_id, :id)
      @folder.update(params_folder)

      respond_to do |format|
        format.js   { render partial: 'clients/js/show', locals: { cards: %w[folders_edit td_folder_name] } }
        format.html { redirect_to root_path }
      end
    end

    private

    def authorize_user!
      super

      return if current_user.access_controller?('clients', 'folder_assignments', session)

      raise ExceptionHandlers::UserNotAuthorized.new("My Company Profile > #{Folder.title.pluralize}", root_path)
    end

    def params_folder
      params.require(:folder).permit(:name)
    end

    def set_folder
      folder_id = params.dig(:id).to_i

      if folder_id.positive? && (@folder = @client.folders.find_by(id: folder_id))
        true
      else
        sweetalert_error('Unathorized Access!', 'Your account could NOT be confirmed.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end
    end
  end
end
