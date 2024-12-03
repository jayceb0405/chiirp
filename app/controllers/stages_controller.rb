# frozen_string_literal: true

# app/controllers/stages_controller.rb
class StagesController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user!
  before_action :set_stage_parent, only: %i[show user]

  # (GET)
  # /stages
  # stages_path
  # stages_url
  def index
    stage = if params.include?(:stage_id) && params.include?(:stage_parent_id)
              # display the Contacts for a Stage when a stage_id is received
              Stage.find_by(id: params[:stage_id].to_i, stage_parent_id: params[:stage_parent_id].to_i)
            end

    respond_to do |format|
      format.html { render 'stages/index', locals: { client: current_user.client } }
      format.js   { render partial: 'stages/js/show', locals: { cards: %w[index_stage], client: current_user.client, stage: } }
    end
  end

  # (PATCH)
  # /stage_parents/:stage_parent_id/search
  # stage_parent_search_path(:stage_parent_id)
  # stage_parent_search_url(:stage_parent_id)
  def search
    sanitized_params = params.permit(:search_string, :stage_id, :stage_parent_id)
    stage            = Stage.find_by(id: sanitized_params.dig(:stage_id).to_i, stage_parent_id: sanitized_params.dig(:stage_parent_id).to_i)

    respond_to do |format|
      format.js   { render partial: 'stages/js/show', locals: { cards: %w[index_stage], client: current_user.client, stage:, search_string: sanitized_params.dig(:search_string) } }
      format.html { redirect_to root_path }
    end
  end

  # (GET)
  # /stages/:id
  # stage_path
  # stage_url
  def show
    respond_to do |format|
      format.js   { render partial: 'stages/js/show', locals: { cards: %w[show], stage_parent: @stage_parent } }
      format.html { redirect_to root_path }
    end
  end

  # (PUT/PATCH)
  # /stages/:id
  # stage_path(:id)
  # stage_url(:id)
  def update
    contact_id      = params.dig(:contact_id).to_i
    stage_id        = params.dig(:old_stage_id).to_i
    stage_count     = 0
    new_stage_id    = params.dig(:new_stage_id).to_i
    new_stage_count = 0
    user_settings   = current_user.user_settings.find_or_create_by(controller_action: 'stages_index', current: 1)

    if contact_id.positive? && new_stage_id.positive? && (contact = current_user.client.contacts.find_by(id: contact_id))

      unless contact.stage_id == new_stage_id
        contact.update(stage_id: new_stage_id)

        if user_settings.data.dig(:user_ids).present? && current_user.access_controller?('stages', 'all_contacts', session)
          stage_count     = Contact.where(stage_id:, user_id: user_settings.data[:user_ids]).count
          new_stage_count = Contact.where(stage_id: new_stage_id, user_id: user_settings.data[:user_ids]).count
        elsif current_user.access_controller?('stages', 'all_contacts', session)
          stage_count     = Contact.where(stage_id:).count
          new_stage_count = Contact.where(stage_id: new_stage_id).count
        else
          stage_count     = Contact.where(stage_id:, user_id: current_user.id).count
          new_stage_count = Contact.where(stage_id: new_stage_id, user_id: current_user.id).count
        end
      end

      if params.dig(:start_campaign).to_bool && (stage = Stage.find_by(id: new_stage_id)) && stage.stage_parent.client_id == current_user.client_id && (campaign = current_user.client.campaigns.find_by(id: stage.campaign_id))
        Contacts::Campaigns::StartJob.perform_later(
          campaign_id: campaign.id,
          client_id:   current_user.client_id,
          contact_id:  contact.id,
          user_id:     current_user.id
        )
      end
    end

    respond_to do |format|
      format.js   { render partial: 'stages/js/show', locals: { cards: %w[contact_count], stage_id:, stage_count:, new_stage_id:, new_stage_count: } }
      format.html { redirect_to root_path }
    end
  end

  # (PATCH)
  # /stage_parents/:stage_parent_id/user/:user_id
  # stage_parent_user_path(:stage_parent_id, :user_id)
  # stage_parent_user_url(:stage_parent_id, :user_id)
  def user
    user_ids = params.permit(users: {}).dig(:users)&.keys || []

    user_settings = current_user.user_settings.find_or_create_by(controller_action: 'stages_index', current: 1)
    user_settings.data[:user_ids] = if !current_user.access_controller?('stages', 'all_contacts', session) || user_ids.blank?
                                      [current_user.id]
                                    else
                                      user_ids.map(&:to_i)
                                    end
    user_settings.save

    respond_to do |format|
      format.js   { render partial: 'stages/js/show', locals: { cards: %w[show], stage_parent: @stage_parent } }
      format.html { redirect_to root_path }
    end
  end

  private

  def authorize_user!
    super
    return if current_user.access_controller?('stages', 'allowed', session)

    raise ExceptionHandlers::UserNotAuthorized.new("My #{StageParent.title.pluralize}", root_path)
  end

  def set_stage_parent
    stage_parent_id = (params.dig(:stage_parent_id) || params.dig(:id)).to_i

    raise ExceptionHandlers::UserNotAuthorized.new("this #{StageParent.title.pluralize}", root_path) unless stage_parent_id.positive? && (@stage_parent = current_user.client.stage_parents.find_by(id: stage_parent_id))

    true
  end
end
