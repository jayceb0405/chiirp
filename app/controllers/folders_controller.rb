# frozen_string_literal: true

# app/controllers/folders_controller.rb
class FoldersController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user!
  before_action :set_folder

  # (POST) add one or more Messages::Messages to a Folder
  # /folders/:folder_id/message_apply?message_id=[Integer]
  # folder_message_apply_path(:folder_id, message_id: [Integer])
  # folder_message_apply_url(:folder_id, message_id: [Integer])
  def message_apply
    message_ids = params.permit(:message_id).dig(:message_id).to_s.split(',')

    Messages::Message.where(id: message_ids).find_each do |message|
      if (message_folder = Messages::FolderAssignment.find_by(message_id: message.id, folder_id: @folder.id))
        # update Messages::FolderAssignment
        message_folder.update(updated_at: Time.current)
      else
        # create new Messages::FolderAssignment
        message.folder_assignments.create(folder_id: @folder.id)
      end
    end

    render js: '', layout: false, status: :ok
  end

  # (POST) remove one or more Messages::Messages from a Folder
  # /folders/:folder_id/message_remove
  # folder_message_remove_path(:folder_id)
  # folder_message_remove_url(:folder_id)
  def message_remove
    message_ids = params.permit(:message_id).dig(:message_id).to_s.split(',')

    Messages::FolderAssignment.where(message_id: message_ids, folder_id: @folder.id).destroy_all

    render js: '', layout: false, status: :ok
  end

  # (POST) add one or more Messages::Messages to a Folder
  # /folders/:folder_id/message_toggle?message_id=[Integer]
  # folder_message_toggle_path(:folder_id, message_id: [Integer])
  # folder_message_toggle_url(:folder_id, message_id: [Integer])
  def message_toggle
    message_ids = params.permit(:message_id).dig(:message_id).to_s.split(',')

    Messages::Message.where(id: message_ids).find_each do |message|
      if (message_folder = Messages::FolderAssignment.find_by(message_id: message.id, folder_id: @folder.id))
        # remove Messages::FolderAssignment
        message_folder.destroy
      else
        # create new Messages::FolderAssignment
        message.folder_assignments.create(folder_id: @folder.id)
      end
    end

    render js: '', layout: false, status: :ok
  end

  private

  def authorize_user!
    super
    return if current_user.access_controller?('clients', 'folder_assignments', session)

    raise ExceptionHandlers::UserNotAuthorized.new('Message Folders', root_path)
  end

  def set_folder
    folder_id = params.dig(:folder_id).to_i

    return if folder_id.positive? && (@folder = Folder.find_by(id: folder_id))

    respond_to do |format|
      format.js { render js: "window.location = '#{root_path}'" and return false }
      format.html { redirect_to root_path and return false }
    end
  end
end
