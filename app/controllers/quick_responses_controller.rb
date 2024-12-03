# frozen_string_literal: true

# app/controllers/quick_responses_controller.rb
class QuickResponsesController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user!
  before_action :contact
  before_action :quick_response, only: %i[destroy edit update]

  # (POST)
  # /quick_responses_path
  # /quick_responses_url
  def create
    @quick_response = current_user.client.quick_responses.new(quick_response_params)

    if @quick_response.save
      self.quick_responses

      render partial: 'quick_responses/js/show', locals: { cards: %w[index], message_id: params.dig(:message_id) }
    else
      render partial: 'quick_responses/js/show', locals: { cards: %w[edit], message_id: params.dig(:message_id) }
    end
  end

  # (DELETE)
  # /quick_responses/:id
  # quick_response_path(:id)
  # quick_response_url(:id)
  def destroy
    @quick_response.destroy
    self.quick_responses

    render partial: 'quick_responses/js/show', locals: { cards: %w[index], message_id: params.dig(:message_id) }
  end

  # (GET)
  # /quick_responses/:id/edit
  # edit_quick_response_path(:id)
  # edit_quick_response_url(:id)
  def edit
    render partial: 'quick_responses/js/show', locals: { cards: %w[edit], message_id: params.dig(:message_id) }
  end

  # (GET)
  # /quick_responses
  # quick_responses_path
  # quick_responses_url
  def index
    self.quick_responses

    render partial: 'quick_responses/js/show', locals: { cards: %w[index], message_id: params.dig(:message_id) }
  end

  # (GET)
  # /quick_responses/new
  # new_quick_response_path
  # new_quick_response_url
  def new
    @quick_response = current_user.client.quick_responses.new(name: 'New Quick Response')

    render partial: 'quick_responses/js/show', locals: { cards: %w[edit], message_id: params.dig(:message_id) }
  end

  # (PUT/PATCH)
  # /quick_responses/:id
  # quick_response_path(:id)
  # quick_response_url(:id)
  def update
    if @quick_response.update(quick_response_params)
      self.quick_responses

      render partial: 'quick_responses/js/show', locals: { cards: %w[index], message_id: params.dig(:message_id) }
    else
      render partial: 'quick_responses/js/show', locals: { cards: %w[edit], message_id: params.dig(:message_id) }
    end
  end

  private

  def contact
    # Contact may belong to User.Client or any Clients who are accounts of User.Client
    return if params.dig(:contact_id).blank? || (@contact = Contact.find_by(id: params.dig(:contact_id), client_id: Client.agency_accounts(current_user.client_id).pluck(:id) << current_user.client_id))

    respond_to do |format|
      format.js { render js: "window.location = '#{root_path}'" and return false }
      format.html { redirect_to root_path and return false }
    end
  end

  def quick_response
    return if (@quick_response = QuickResponse.where(client_id: Client.agency_accounts(current_user.client_id).pluck(:id) << current_user.client_id).find_by(id: params.dig(:id)))

    # return if (@quick_response = @contact.client.quick_responses.find_by(id: params.dig(:id)))

    respond_to do |format|
      format.js { render js: "window.location = '#{root_path}'" and return false }
      format.html { redirect_to root_path and return false }
    end
  end

  def quick_responses
    return if @contact.is_a?(Contact) && (@quick_responses = @contact.client.quick_responses)

    @quick_responses = current_user.client.quick_responses
  end

  def quick_response_params
    sanitized_params = params.require(:quick_response).permit(:name, :message)

    sanitized_params[:name]    = sanitized_params[:name].strip
    sanitized_params[:message] = sanitized_params[:message].strip

    sanitized_params
  end
end
