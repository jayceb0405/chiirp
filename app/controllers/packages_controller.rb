# frozen_string_literal: true

# app/controllers/packages_controller.rb
class PackagesController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user!
  before_action :set_package, only: %i[destroy edit image update]
  before_action :prepare_index_data, only: %i[show]

  # (POST) save a new Package
  # /packages
  # packages_path
  # packages_url
  def create
    if package_params[:onetime]
      # create a page and a package
      @package = Package.new(package_params)
      @package.package_pages_01.build(name: @package.name, tenant: package_params[:tenant], onetime: true, expired_on: @package.expired_on)
      @package.save!
    else
      @package = Package.create(package_params)
    end

    prepare_index_data

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to packagemanager_path }
    end
  end

  # (DELETE) destroy a Package
  # /packages/:id
  # package_path(:id)
  # package_url(:id)
  def destroy
    @package.destroy
    @package = Package.new

    prepare_index_data

    respond_to do |format|
      format.js { render partial: 'packages/js/show', locals: { cards: %w[dropdown index] } }
      format.html { redirect_to packagemanager_path }
    end
  end

  # (GET) show package to edit
  # /packages/:id/edit
  # edit_package_path(:id)
  # edit_package_url(:id)
  def edit
    respond_to do |format|
      format.js { render partial: 'packages/js/show', locals: { cards: %w[edit] } }
      format.html { redirect_to packagemanager_path }
    end
  end

  # (PATCH) receive a direct uploaded image
  # /packages/:id/image
  # image_package_path(:id)
  # image_package_url(:id)
  def image
    join_form_image_delete = params.dig(:join_form_image_delete).to_bool
    join_form_image        = package_params.dig(:join_form_image)

    if join_form_image_delete
      # deleting an image
      @package.join_form_image.purge
    elsif join_form_image
      @package.update(join_form_image:)
    end

    respond_to do |format|
      format.json { render json: { imageUrl: Cloudinary::Utils.cloudinary_url(@package.join_form_image.key, { secure_distribution: I18n.t("tenant.#{Rails.env}.cloudinary_cname"), transformation: [height: 77, crop: 'scale'], format: 'jpg' }), status: 200 } }
      format.js { render partial: 'packages/js/show', locals: { cards: %w[edit] } }
      format.html { redirect_to packagemanager_path }
    end
  end

  # (GET) list Packages
  # /packages
  # packages_path
  # packages_url
  def index
    @package  = Package.new
    @packages = Package.where(tenant: I18n.t('tenant.id'))

    respond_to do |format|
      format.js { render partial: 'packages/js/show', locals: { cards: %w[dropdown edit] } }
      format.html { redirect_to packagemanager_path }
    end
  end

  # (GET) new package
  # /packages/new
  # new_package_path
  # new_package_url
  def new
    @package = Package.new(name: 'New Package')

    respond_to do |format|
      format.js { render partial: 'packages/js/show', locals: { cards: %w[edit] } }
      format.html { redirect_to packagemanager_path }
    end
  end

  # (GET) new onetime package from existing
  # /packages/onetime/:package_id
  # package_onetime_path
  # package_onetime_url
  def onetime
    @package = Package.find_by(tenant: I18n.t('tenant.id'), id: params[:package_id])&.dup
    @package ||= Package.new(name: 'New Package')
    @package&.set_package_key
    @package.onetime = true
  end

  # (GET) show Package manager
  # /packagemanager
  # packagemanager_path
  # packagemanager_url
  def show
    respond_to do |format|
      format.js { render js: "window.location = '#{packagemanager_path}'" }
      format.html { render 'packages/show' }
    end
  end

  # (PUT/PATCH) update existing Package
  # /packages/:id
  # package_path(:id)
  # package_url(:id)
  def update
    @package.update(package_params)

    if params.dig(:commit).to_s.casecmp?('copy')
      # copy Package
      @package = @package.copy || Package.new
    end

    prepare_index_data

    respond_to do |format|
      format.js { render partial: 'packages/js/show', locals: { cards: %w[dropdown edit] } }
      format.html { redirect_to packagemanager_path }
    end
  end

  private

  def authorize_user!
    super
    return if current_user.team_member?

    raise ExceptionHandlers::UserNotAuthorized.new('Packages', root_path)
  end

  def prepare_index_data
    @packages_count = Package.where(tenant: I18n.t('tenant.id')).persistent.count
    @pages = Hash.new { |hash, key| hash[key] = [] }

    # pages with packages
    PackagePage.where(tenant: I18n.t('tenant.id')).persistent.joins(:package_01).find_each do |page|
      @pages[page] << page.package_01 if page.package_01
      @pages[page] << page.package_02 if page.package_02
      @pages[page] << page.package_03 if page.package_03
      @pages[page] << page.package_04 if page.package_04
    end

    Package.where(tenant: I18n.t('tenant.id')).persistent.includes(:package_pages_01, :package_pages_02, :package_pages_03, :package_pages_04).find_each do |package|
      next if package.package_pages_01.any?
      next if package.package_pages_02.any?
      next if package.package_pages_03.any?
      next if package.package_pages_04.any?

      @pages[nil] << package
    end

    # find packages without any pages
    # pack_ids = []
    # Package.find_each do |pack|
    #   pack_ids << pack.id unless pack.package_pages_01.any?
    # end;1

    # find packages with multiple pages
    # pack_ids = []
    # Package.find_each do |pack|
    #   pack_ids << pack.id if pack.package_pages_01.count > 1
    # end;1
  end

  def package_params
    # sanitize Package parameters
    #
    # Example:
    #   package_params
    #
    # Required Parameters:
    #   none
    #
    # Optional Parameters:
    #   package: (Hash)
    #
    if params.include?(:package)
      response = params.require(:package).permit(
        :aiagent_base_charge, :aiagent_included_count, :aiagent_message_credits, :aiagent_overage_charge, :aiagent_trial_period_days, :aiagent_trial_period_months, :campaign_id, :campaigns_count, :credit_charge, :custom_fields_count, :dlc10_required, :dlc10_charged, :expired_on, :first_payment_delay_days, :first_payment_delay_months, :folders_count,
        :group_id, :groups_count, :import_contacts_count, :join_form_image,
        :max_contacts_count, :max_email_templates, :max_kpis_count, :max_phone_numbers, :max_users_count, :max_voice_recordings, :message_central_allowed,
        :mo_charge, :mo_credits, :my_contacts_allowed, :my_contacts_group_actions_all_allowed, :name,
        :affiliate_id, :onetime, :phone_calls_allowed, :phone_call_credits, :phone_vendor, :promo_credit_charge, :promo_max_phone_numbers, :promo_mo_charge, :promo_mo_credits, :promo_months,
        :quick_leads_count, :rvm_allowed, :rvm_credits, :searchlight_fee, :share_aiagents_allowed, :share_email_templates_allowed, :share_funnels_allowed, :share_quick_leads_allowed, :share_surveys_allowed, :share_widgets_allowed, :share_stages_allowed, :setup_fee, :stages_count, :stage_id, :surveys_count,
        :tag_id, :tasks_allowed, :text_image_credits, :text_message_credits, :text_message_images_allowed, :text_segment_charge_type, :trackable_links_count, :trial_credits,
        :user_chat_allowed, :video_calls_allowed, :video_call_credits, :widgets_count, integrations_allowed: [], training: [], stop_campaign_ids: [], agency_ids: []
      )

      response[:agency_ids]                            = response[:agency_ids].compact_blank if response.include?(:agency_ids)
      response[:aiagent_base_charge]                   = response[:aiagent_base_charge].to_i if response.include?(:aiagent_base_charge)
      response[:aiagent_included_count]                = response[:aiagent_included_count].to_i if response.include?(:aiagent_included_count)
      response[:aiagent_message_credits]               = response[:aiagent_message_credits].to_f if response.include?(:aiagent_message_credits)
      response[:aiagent_overage_charge]                = response[:aiagent_overage_charge].to_f if response.include?(:aiagent_overage_charge)
      response[:aiagent_trial_period_days]             = response[:aiagent_trial_period_days].to_i if response.include?(:aiagent_trial_period_days)
      response[:aiagent_trial_period_months]           = response[:aiagent_trial_period_months].to_i if response.include?(:aiagent_trial_period_months)
      response[:campaign_id]                           = response[:campaign_id].to_i if response.include?(:campaign_id)
      response[:campaigns_count]                       = response[:campaigns_count].to_i if response.include?(:campaigns_count)
      response[:credit_charge]                         = response[:credit_charge].to_f if response.include?(:credit_charge)
      response[:custom_fields_count]                   = response[:custom_fields_count].to_i if response.include?(:custom_fields_count)
      response[:dlc10_required] = response[:dlc10_required].to_bool if response.include?(:dlc10_required)
      response[:dlc10_charged]                         = response[:dlc10_charged].to_bool if response.include?(:dlc10_charged)
      response[:expired_on]                            = Chronic.parse(response[:expired_on]) if response.include?(:expired_on)
      response[:first_payment_delay_days]              = response[:first_payment_delay_days].to_i if response.include?(:first_payment_delay_days)
      response[:first_payment_delay_months]            = response[:first_payment_delay_months].to_i if response.include?(:first_payment_delay_months)
      response[:folders_count]                         = response[:folders_count].to_i if response.include?(:folders_count)
      response[:group_id]                              = response[:group_id].to_i if response.include?(:group_id)
      response[:groups_count]                          = response[:groups_count].to_i if response.include?(:groups_count)
      response[:import_contacts_count]                 = response[:import_contacts_count].to_i if response.include?(:import_contacts_count)
      response[:max_contacts_count]                    = response[:max_contacts_count].to_i if response.include?(:max_contacts_count)
      response[:max_email_templates]                   = response[:max_email_templates].to_i if response.include?(:max_email_templates)
      response[:max_kpis_count]                        = response[:max_kpis_count].to_i if response.include?(:max_kpis_count)
      response[:max_phone_numbers]                     = response[:max_phone_numbers].to_i if response.include?(:max_phone_numbers)
      response[:max_users_count]                       = response[:max_users_count].to_i if response.include?(:max_users_count)
      response[:max_voice_recordings]                  = response[:max_voice_recordings].to_i if response.include?(:max_voice_recordings)
      response[:message_central_allowed]               = response[:message_central_allowed].to_bool if response.include?(:message_central_allowed)
      response[:mo_charge]                             = response[:mo_charge].to_d if response.include?(:mo_charge)
      response[:mo_credits]                            = response[:mo_credits].to_d if response.include?(:mo_credits)
      response[:my_contacts_allowed]                   = response[:my_contacts_allowed].to_bool if response.include?(:my_contacts_allowed)
      response[:my_contacts_group_actions_all_allowed] = response[:my_contacts_group_actions_all_allowed].to_bool if response.include?(:my_contacts_group_actions_all_allowed)
      response[:affiliate_id]                          = response.dig(:affiliate_id).to_i.positive? ? response[:affiliate_id].to_i : nil
      response[:onetime]                               = response.dig(:onetime).to_bool if response.include?(:onetime)
      response[:phone_calls_allowed]                   = response[:phone_calls_allowed].to_bool if response.include?(:phone_calls_allowed)
      response[:phone_call_credits]                    = response[:phone_call_credits].to_d if response.include?(:phone_call_credits)
      response[:phone_vendor]                          = response[:phone_vendor].to_s if response.include?(:phone_vendor)
      response[:promo_credit_charge]                   = response[:promo_credit_charge].to_d if response.include?(:promo_credit_charge)
      response[:promo_max_phone_numbers]               = response[:promo_max_phone_numbers].to_i if response.include?(:promo_max_phone_numbers)
      response[:promo_mo_charge]                       = response[:promo_mo_charge].to_d if response.include?(:promo_mo_charge)
      response[:promo_mo_credits]                      = response[:promo_mo_credits].to_d if response.include?(:promo_mo_credits)
      response[:promo_months]                          = response[:promo_months].to_i if response.include?(:promo_months)
      response[:quick_leads_count]                     = response[:quick_leads_count].to_i if response.include?(:quick_leads_count)
      response[:rvm_allowed]                           = response[:rvm_allowed].to_bool if response.include?(:rvm_allowed)
      response[:rvm_credits]                           = response[:rvm_credits].to_d if response.include?(:rvm_credits)
      response[:searchlight_fee]                       = response[:searchlight_fee].to_d if response.include?(:searchlight_fee)
      response[:share_aiagents_allowed]                = response[:share_aiagents_allowed].to_bool if response.include?(:share_aiagents_allowed)
      response[:share_email_templates_allowed]         = response[:share_email_templates_allowed].to_bool if response.include?(:share_email_templates_allowed)
      response[:share_funnels_allowed]                 = response[:share_funnels_allowed].to_bool if response.include?(:share_funnels_allowed)
      response[:share_quick_leads_allowed]             = response[:share_quick_leads_allowed].to_bool if response.include?(:share_quick_leads_allowed)
      response[:share_surveys_allowed]                 = response[:share_surveys_allowed].to_bool if response.include?(:share_surveys_allowed)
      response[:share_widgets_allowed]                 = response[:share_widgets_allowed].to_bool if response.include?(:share_widgets_allowed)
      response[:share_stages_allowed]                  = response[:share_stages_allowed].to_bool if response.include?(:share_stages_allowed)
      response[:setup_fee]                             = response[:setup_fee].to_d if response.include?(:setup_fee)
      response[:stages_count]                          = response[:stages_count].to_i if response.include?(:stages_count)
      response[:stage_id]                              = response[:stage_id].to_i if response.include?(:stage_id)
      response[:stop_campaign_ids]                     = response[:stop_campaign_ids]&.compact_blank
      response[:stop_campaign_ids]                     = [0] if response[:stop_campaign_ids]&.include?('0')
      response[:surveys_count]                         = response[:surveys_count].to_i if response.include?(:surveys_count)
      response[:tag_id]                                = response[:tag_id].to_i if response.include?(:tag_id)
      response[:tasks_allowed]                         = response[:tasks_allowed].to_bool if response.include?(:tasks_allowed)
      response[:text_image_credits]                    = response[:text_image_credits].to_d if response.include?(:text_image_credits)
      response[:text_message_credits]                  = response[:text_message_credits].to_d if response.include?(:text_message_credits)
      response[:text_message_images_allowed]           = response[:text_message_images_allowed].to_bool if response.include?(:text_message_images_allowed)
      response[:text_segment_charge_type]              = response[:text_segment_charge_type].to_i if response.include?(:text_segment_charge_type)
      response[:trackable_links_count]                 = response[:trackable_links_count].to_i if response.include?(:trackable_links_count)
      response[:trial_credits]                         = response[:trial_credits].to_f if response.include?(:trial_credits)
      response[:user_chat_allowed]                     = response[:user_chat_allowed].to_bool if response.include?(:user_chat_allowed)
      response[:video_calls_allowed]                   = response[:video_calls_allowed].to_bool if response.include?(:video_calls_allowed)
      response[:video_call_credits]                    = response[:video_call_credits].to_d if response.include?(:video_call_credits)
      response[:widgets_count]                         = response[:widgets_count].to_i if response.include?(:widgets_count)

      response[:integrations_allowed]                  = response.include?(:integrations_allowed) ? response[:integrations_allowed] : []
      response[:training]                              = response.include?(:training) ? response[:training] : []

      response[:tenant]                                = I18n.locale.to_s
    else
      response = {}
    end

    response
  end

  def set_package
    # set up Package object
    #
    # Required Parameters:
    #   id: (Integer)
    #
    # Optional Parameters:
    #   none
    #
    if params.include?(:id)
      # Package id was received

      @package = Package.find_by(tenant: I18n.t('tenant.id'), id: params[:id])

      unless @package
        # Package was NOT found
        sweetalert_warning('Unable to Confirm Access!', 'Package cound NOT be found.', '', { persistent: 'OK' })
      end
    else
      # package id was NOT received
      sweetalert_warning('Unable to Confirm Access!', 'Package was NOT received.', '', { persistent: 'OK' })
      @package = nil
    end

    return if @package

    respond_to do |format|
      format.js { render js: "window.location = '#{packagemanager_path}'" and return false }
      format.html { redirect_to packagemanager_path and return false }
    end
  end
end
