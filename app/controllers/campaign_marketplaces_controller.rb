# frozen_string_literal: true

# app/controllers/campaigns_controller.rb
class CampaignMarketplacesController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user!
  before_action :set_campaign, only: %i[approve buy edit image show update]

  # (POST) approve a Campaign or CampaignGroup for Marketplace
  # /campaign_marketplaces/:id/approve
  # approve_campaign_path(:id)
  # approve_campaign_url(:id)
  def approve
    if @campaign.marketplace_ok
      @campaign.update(marketplace_ok: false)
    else
      @campaign.update(marketplace_ok: true)
    end

    respond_to do |format|
      format.js { render js: "window.location = '#{campaign_marketplaces_path}'" }
      format.html { redirect_to campaign_marketplaces_path }
    end
  end

  # (POST) get/buy a Campaign or CampaignGroup
  # /campaign_marketplaces/:id/buy
  # buy_campaign_path(:id)
  # buy_campaign_url(:id)
  def buy
    @campaign.copy(new_client_id: current_user.client_id)

    respond_to do |format|
      format.js { render js: "window.location = '#{campaigns_path}'" }
      format.html { redirect_to campaigns_path }
    end
  end

  # (GET) edit Campaign marketplace data
  # /campaign_marketplaces/:id/edit
  # edit_campaign_marketplace_path(:id)
  # edit_campaign_marketplace_utl(:id)
  def edit
    respond_to do |format|
      format.js { render partial: 'campaign_marketplaces/js/show', locals: { cards: %w[edit] } }
      format.html { redirect_to campaigns_path }
    end
  end

  # (PATCH) add an image to a Campaign in a marketplace
  # /campaigns/:id/image
  # image_campaign_path(:id)
  # image_campaign_url(:id)
  def image
    image_delete      = params.dig(:image_delete).to_bool
    marketplace_image = campaign_params.dig(:marketplace_image)

    if image_delete
      # deleting an image
      @campaign.marketplace_image.purge
    elsif marketplace_image
      @campaign.update(marketplace_image:)
    end

    respond_to do |format|
      format.json { render json: { imageUrl: Cloudinary::Utils.cloudinary_url(@campaign.marketplace_image.key, { secure_distribution: I18n.t("tenant.#{Rails.env}.cloudinary_cname"), transformation: [width: 200, height: 200, crop: 'fit'], format: 'png' }), status: 200 } }
      format.js { render partial: 'campaign_marketplaces/js/show', locals: { cards: %w[edit] } }
      format.html { redirect_to campaigns_path }
    end
  end

  # (GET) list Campaigns & CampaignGroups available in CampaignMarketplace
  # /campaign_marketplaces
  # campaign_marketplaces_path
  # campaign_marketplaces_url
  def index
    @campaigns = Campaign.by_tenant(I18n.t('tenant.id')).where(marketplace_ok: true).order(:name).to_a.map(&:serializable_hash) << CampaignGroup.by_tenant.where(marketplace_ok: true).order(:name).to_a.map(&:serializable_hash)
    @campaigns = @campaigns.flatten.sort_by { |c| c['name'] }

    @campaigns_unapproved = Campaign.by_tenant(I18n.t('tenant.id')).where(marketplace: true, marketplace_ok: false).order(:name).to_a.map(&:serializable_hash) << CampaignGroup.by_tenant.where(marketplace: true, marketplace_ok: false).order(:name).to_a.map(&:serializable_hash)
    @campaigns_unapproved = @campaigns_unapproved.flatten.sort_by { |c| c['name'] }

    respond_to do |format|
      format.js { render js: "window.location = '#{campaign_marketplaces_path}'" }
      format.html { render 'campaign_marketplaces/index' }
    end
  end

  # (GET) show a Campaign or CampaignGroup to get/buy
  # /campaign_marketplaces/:id
  # campaign_marketplace_path(:id)
  # campaign_marketplace_url(:id)
  def show
    respond_to do |format|
      format.js { render partial: 'campaign_marketplaces/js/show', locals: { cards: %w[show] } }
      format.html { redirect_to campaigns_path }
    end
  end

  # (PUT/PATCH) save updated Campaign marketplace data
  # /campaign_marketplaces/:id
  # campaign_marketplace_path(:id)
  # campaign_marketplace_url(:id)
  def update
    @campaign.update(campaign_params)

    case params.dig(:commit).to_s.downcase
    when 'submit to marketplace'
      @campaign.update(marketplace: true)
      # @campaign.campaigns.update_all( marketplace: true ) if @campaign.campaign_share_code.campaign_group
    when 'withdraw from marketplace'
      @campaign.update(marketplace: false, marketplace_ok: false)
      # @campaign.campaigns.update_all( marketplace: false, marketplace_ok: false ) if @campaign.campaign_share_code.campaign_group
    end

    respond_to do |format|
      format.js { render partial: 'campaign_marketplaces/js/show', locals: { cards: %w[edit] } }
      format.html { redirect_to campaigns_path }
    end
  end

  private

  def authorize_user!
    super
    return if current_user.access_controller?('campaigns', 'allowed', session)

    raise ExceptionHandlers::UserNotAuthorized.new('Campaign Builder', root_path)
  end

  def campaign_params
    response = if params.include?(:campaign)
                 params.require(:campaign).permit(:description, :price, :marketplace_image)
               elsif params.include?(:campaign_group)
                 params.require(:campaign_group).permit(:description, :price, :marketplace_image)
               else
                 {}
               end

    response[:price] = response[:price].to_d if response.include?(:price)

    response
  end

  def set_campaign
    return true if params.dig(:id).to_s.present? && (campaign_share_code = CampaignShareCode.find_by(id: params[:id])) && (@campaign = campaign_share_code.campaign_id ? campaign_share_code.campaign : campaign_share_code.campaign_group)

    sweetalert_warning('Unable to Confirm Access!', 'Campaign or Campaign Package cound NOT be found.', '', { persistent: 'OK' })

    respond_to do |format|
      format.json { render json: { imageUrl: '', status: 404 } and return false }
      format.js { render js: "window.location = '#{campaigns_path}'" and return false }
      format.html { redirect_to campaigns_path and return false }
    end
  end
end
