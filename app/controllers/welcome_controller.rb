# frozen_string_literal: true

# app/controllers/welcome_controller.rb
class WelcomeController < ApplicationController
  skip_before_action :verify_authenticity_token, only: %i[join join_min pricing_init pricing]
  before_action :authenticate_user!, only: %i[training]
  before_action :package, only: %i[join join_min]
  before_action :package_page, only: %i[join join_min pricing pricing_init]
  before_action :contact, only: %i[join join_min]

  # (GET) respond to a failed TrackableLink request
  # /welcome/failed_link
  # welcome_failed_link_path
  # welcome_failed_link_url
  def failed_link
    render 'welcome/failed_link'
  end

  # show join page
  # /welcome/join/:package_key
  # welcome_join_path(:package_key)
  # welcome_join_url(:package_key)
  def join
    if @contact
      @client = Client.new(
        name:      @contact.fullname,
        address1:  @contact.address1,
        address2:  @contact.address2,
        city:      @contact.city,
        state:     @contact.state,
        zip:       @contact.zipcode,
        phone:     @contact.primary_phone&.phone.to_s,
        time_zone: 'Mountain Time (US & Canada)'
      )

      @user = @client.users.new(
        firstname: @contact.firstname,
        lastname:  @contact.lastname,
        email:     @contact.email
      )
    else
      @client = Client.new
      @client.build_dlc10_brand
    end

    respond_to do |format|
      format.js   { render js: "window.location = '#{welcome_pricing_default_path}'" }
      format.html { render 'welcome/join', layout: 'landing_page' }
    end
  end

  # show join page
  # /welcome/join_min/:package_key
  # welcome_join_min_path(:package_key)
  # welcome_join_min_url(:package_key)
  def join_min
    @package_page ||= PackagePage.find_by(package_01_id: @package.id)
    @package_page ||= PackagePage.find_by(package_02_id: @package.id)
    @package_page ||= PackagePage.find_by(package_03_id: @package.id)
    @package_page ||= PackagePage.find_by(package_04_id: @package.id)
    @package_page ||= PackagePage.new

    if @contact
      @client = Client.new(
        name:      @contact.fullname,
        address1:  @contact.address1,
        address2:  @contact.address2,
        city:      @contact.city,
        state:     @contact.state,
        zip:       @contact.zipcode,
        phone:     @contact.primary_phone&.phone.to_s,
        time_zone: 'Mountain Time (US & Canada)'
      )

      @user = @client.users.new(
        firstname: @contact.firstname,
        lastname:  @contact.lastname,
        email:     @contact.email
      )
    else
      @client = Client.new
    end

    respond_to do |format|
      format.js { render js: "window.location = '#{welcome_pricing_default_path}'" }

      if @client && @user && @user.lastname.present? && @user.firstname.present? && @user.email.present? && @client.phone.present?
        format.html { render 'welcome/join_min', layout: 'landing_page' }
      else
        format.html { render 'welcome/join', layout: 'landing_page' }
      end
    end
  end

  # (GET) show pricing page
  # /welcome/pricing/:package_page_key
  # welcome_pricing_path(:package_page_key)
  # welcome_pricing_url(:package_page_key)
  def pricing
    respond_to do |format|
      format.json { render json: PackagePage.where(page_key: @package_page.page_key), include: %i[package_01 package_02 package_03 package_04] }
      format.js   { render js: "window.location = '#{welcome_pricing_path(params[:package_page_key])}'" }
      format.html { render 'welcome/pricing', layout: 'landing_page' }
    end
  end

  # (GET) get javascript code to load packages on forward facing site
  # /welcome/pricing/init/:package_page_key
  # welcome_pricing_init_path(:package_page_key)
  # welcome_pricing_init_url(:package_page_key)
  def pricing_init
    @package_page_key = params.dig(:package_page_key).to_s

    respond_to do |format|
      format.js   { render partial: 'welcome/js/init' }
      format.html { redirect_to root_path }
    end
  end

  # (GET) show success page after successfully creating a new Client
  # /welcome/success/:id
  # welcome_success_path(:id)
  # welcome_success_url(:id)
  def success
    respond_to do |format|
      format.html { render 'welcome/success', layout: 'landing_page' }
      # format.js   { render partial: 'welcome/js/init' }
    end
  end

  # (GET) training videos
  # /welcome/training
  # welcome_training_path
  # welcome_training_url
  def training
    respond_to do |format|
      format.js   { render js: "window.location = '#{welcome_training_path}'" }
      format.html { render 'welcome/training' }
    end
  end

  # /welcome/unsubscribe/:client_id/:contact_id
  # welcome_unsubscribe_path(:client_id, :contact_id)
  # welcome_unsubscribe_url(:client_id, :contact_id)
  def unsubscribe
    client_id  = params.dig(:client_id).to_i
    contact_id = params.dig(:contact_id).to_i

    @contact.update(ok2email: 0) if client_id.positive? && contact_id.positive? && (@contact = Contact.find_by(id: contact_id, client_id:))

    render 'welcome/unsubscribe', layout: 'landing_page'
  end

  private

  def contact
    contact_id = params.dig(:contact_id).to_s
    @contact   = Contact.find_by(id: Base64.decode64(CGI.unescape(contact_id))) if contact_id.present?
  end

  def package
    @package = params.include?(:package_key) ? Package.find_by(tenant: I18n.t('tenant.id'), package_key: params[:package_key].to_s) : nil

    return if @package

    respond_to do |format|
      format.js   { render js: "window.location = '#{welcome_pricing_default_path}'" and return false }
      format.html { redirect_to welcome_pricing_default_path and return false }
    end
  end

  def package_page
    package_page_key = (params.dig(:package_page_key) || params.dig(:pp)).to_s
    @package_page    = PackagePage.find_by(tenant: I18n.t('tenant.id'), page_key: package_page_key)

    if %w[join join_min].include?(action_name)
      @package_page ||= PackagePage.find_by(package_01_id: @package.id)
      @package_page ||= PackagePage.find_by(package_02_id: @package.id)
      @package_page ||= PackagePage.find_by(package_03_id: @package.id)
      @package_page ||= PackagePage.find_by(package_04_id: @package.id)
    end

    @package_page ||= PackagePage.find_by(tenant: I18n.t('tenant.id'), sys_default: 1)
    @package_page ||= PackagePage.new
  end
end
