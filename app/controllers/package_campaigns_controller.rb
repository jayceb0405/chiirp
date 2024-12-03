# frozen_string_literal: true

# app/controllers/package_campaigns_controller.rb
class PackageCampaignsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user!
  before_action :set_package, only: %i[create destroy index new]
  before_action :set_package_campaign, only: [:destroy]

  # (POST) save a new PackageCampaign
  # /packages/:package_id/campaigns
  # package_campaigns_path(:package_id)
  # package_campaigns_url(:package_id)
  def create
    @package_campaign  = @package.package_campaigns.create(package_campaign_params)
    @package_campaigns = collect_package_campaigns

    respond_to do |format|
      format.js { render partial: 'package_campaigns/js/show', locals: { cards: [1] } }
      format.html { redirect_to packagemanager_path }
    end
  end

  # (DELETE) destroy a PackageCampaign
  # /packages/:package_id/campaigns/:id
  # package_campaign_path(:package_id, :id)
  # package_campaign_url(:package_id, :id)
  def destroy
    @package_campaign.destroy
    @package_campaign  = @package.package_campaigns.new
    @package_campaigns = collect_package_campaigns

    respond_to do |format|
      format.js { render partial: 'package_campaigns/js/show', locals: { cards: [1] } }
      format.html { redirect_to packagemanager_path }
    end
  end

  # (GET) list PackageCampaigns
  # /packages/:package_id/campaigns
  # package_campaigns_path(:package_id)
  # package_campaigns_url(:package_id)
  def index
    @package_campaigns = collect_package_campaigns

    respond_to do |format|
      format.js { render partial: 'package_campaigns/js/show', locals: { cards: [1] } }
      format.html { redirect_to packagemanager_path }
    end
  end

  # (GET) new PackageCampaign
  # /packages/:package_id/campaigns/new
  # new_package_campaign_path(:package_id)
  # new_package_campaign_url(:package_id)
  def new
    @package_campaign = @package.package_campaigns.new

    respond_to do |format|
      format.js { render partial: 'package_campaigns/js/show', locals: { cards: [2] } }
      format.html { redirect_to packagemanager_path }
    end
  end

  private

  def authorize_user!
    super
    return if current_user.team_member?

    raise ExceptionHandlers::UserNotAuthorized.new('Packages', root_path)
  end

  def collect_package_campaigns
    @package.package_campaigns.select('package_campaigns.id AS id, campaigns.name AS campaign_name, campaign_groups.name AS campaign_group_name')
            .left_outer_joins(:campaign, :campaign_group)
            .order('campaign_name, campaign_group_name')
  end

  def package_campaign_params
    sanitized_params = params.permit(:share_code)

    if sanitized_params.dig(:share_code).to_s.present? && (campaign_share_code = CampaignShareCode.find_by(share_code: sanitized_params[:share_code].to_s))
      sanitized_params[:campaign_id]       = campaign_share_code.campaign_id
      sanitized_params[:campaign_group_id] = campaign_share_code.campaign_group_id
    end

    sanitized_params.delete(:share_code)

    sanitized_params
  end

  def set_package
    sanitized_params = params.permit(:package_id)

    return if sanitized_params.dig(:package_id).to_i.positive? && (@package = Package.find_by(tenant: I18n.t('tenant.id'), id: sanitized_params[:package_id].to_i))

    sweetalert_warning('Package Not Found!', 'Package cound NOT be found.', '', { persistent: 'OK' })

    respond_to do |format|
      format.js { render js: "window.location = '#{packagemanager_path}'" and return false }
      format.html { redirect_to packagemanager_path and return false }
    end
  end

  def set_package_campaign
    sanitized_params = params.permit(:id)

    return if sanitized_params.dig(:id).to_i.positive? && (@package_campaign = @package.package_campaigns.find_by(id: sanitized_params[:id].to_i))

    sweetalert_warning('Unable to Confirm Access!', 'Package Campaign cound NOT be found.', '', { persistent: 'OK' })

    respond_to do |format|
      format.js { render js: "window.location = '#{packagemanager_path}'" and return false }
      format.html { redirect_to packagemanager_path and return false }
    end
  end
end
