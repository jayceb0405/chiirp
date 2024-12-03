# frozen_string_literal: true

# app/controllers/campaign_groups_controller.rb
class CampaignGroupsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user!
  before_action :set_campaign_group, only: %i[destroy edit update]

  # (POST) create a new CampaignGroup
  # /campaign_groups
  # campaign_groups_path
  # campaign_groups_url
  def create
    @campaign_group  = current_user.client.campaign_groups.create(campaign_group_params)
    @campaign_groups = current_user.client.campaign_groups.order(:name).includes(:campaign_share_code)

    respond_to do |format|
      format.js   { render partial: 'campaigns/groups/js/show', locals: { cards: %w[index_table_body] } }
      format.html { redirect_to campaigns_path }
    end
  end

  # (DELETE) destroy a CampaignGroup
  # /campaign_groups/:id
  # campaign_group_path(:id)
  # campaign_group_url(:id)
  def destroy
    campaign_id = params.dig(:campaign_id).to_i
    confirm     = params.dig(:confirm).to_s.downcase

    if confirm == 'remove_campaign'
      # received Campaign id to remove from CampaignGroup

      if campaign_id.positive? && (campaign = current_user.client.campaigns.find_by(id: campaign_id))
        campaign.update(campaign_group_id: 0)
      end

      cards = %w[edit]
    else
      @campaign_group.destroy
      @campaign_group = current_user.client.campaign_groups.new
      cards = %w[index_table_body]
    end

    @campaign_groups = current_user.client.campaign_groups.order(:name).includes(:campaign_share_code)

    respond_to do |format|
      format.js   { render partial: 'campaigns/groups/js/show', locals: { cards: } }
      format.html { redirect_to campaigns_path }
    end
  end

  # (GET) edit a CampaignGroup
  # /campaign_groups/:id/edit
  # edit_campaign_group_path(:id)
  # edit_campaign_group_url(:id)
  def edit
    respond_to do |format|
      format.js   { render partial: 'campaigns/groups/js/show', locals: { cards: %w[edit] } }
      format.html { redirect_to campaigns_path }
    end
  end

  # (GET)
  # /campaign_groups
  # campaign_groups_path
  # campaign_groups_url
  def index
    @campaign_group  = current_user.client.campaign_groups.new(name: 'New Campaign Group')
    @campaign_groups = current_user.client.campaign_groups.order(:name).includes(:campaign_share_code)

    respond_to do |format|
      format.js   { render partial: 'campaigns/groups/js/show', locals: { cards: %w[index] } }
      format.html { redirect_to campaigns_path }
    end
  end

  # (GET) create a new CampaignGroup
  # /campaign_groups/new
  # new_campaign_group_path
  # new_campaign_group_url
  def new
    @campaign_group  = current_user.client.campaign_groups.new
    @campaign_groups = current_user.client.campaign_groups.order(:name).includes(:campaign_share_code)

    respond_to do |format|
      format.js   { render partial: 'campaigns/js/show', locals: { cards: %w[index] } }
      format.html { redirect_to campaigns_path }
    end
  end

  # (PUT/PATCH) update a CampaignGroup
  # /campaign_groups/:id
  # campaign_group_path(:id)
  # campaign_group_url(:id)
  def update
    campaign_id = params.dig(:campaign_id).to_i
    commit      = params.dig(:commit).to_s.downcase

    if commit == 'add_campaign' && campaign_id.positive?
      # received a Campaign id to add to CampaignGroup

      if (campaign = current_user.client.campaigns.find_by(id: campaign_id))
        campaign.update(campaign_group_id: @campaign_group.id)
      end
    else
      # update the CampaignGroup
      @campaign_group.update(campaign_group_params)
    end

    @campaign_groups = current_user.client.campaign_groups.order(:name).includes(:campaign_share_code)

    respond_to do |format|
      format.js   { render partial: 'campaigns/groups/js/show', locals: { cards: %w[edit] } }
      format.html { redirect_to campaigns_path }
    end
  end

  private

  def authorize_user!
    super
    return if current_user.access_controller?('campaigns', 'allowed', session)

    raise ExceptionHandlers::UserNotAuthorized.new('Campaign Builder', root_path)
  end

  def campaign_group_params
    params.require(:campaign_group).permit(:name, :description)
  end

  def set_campaign_group
    return true if params.dig(:id).to_i.positive? && (@campaign_group = CampaignGroup.find_by(id: params[:id].to_i))
    return true if (@campaign_group = current_user.client.campaign_groups.new)

    sweetalert_warning('Unable to Confirm Access!', 'Campaign Group cound NOT be found.', '', { persistent: 'OK' })

    respond_to do |format|
      format.js { render js: "window.location = '#{campaigns_path}'" and return false }
      format.html { redirect_to campaigns_path and return false }
    end
  end
end
