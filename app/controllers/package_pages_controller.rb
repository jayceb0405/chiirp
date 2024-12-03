# frozen_string_literal: true

# app/controllers/package_pages_controller.rb
class PackagePagesController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user!
  before_action :set_package_page, only: %i[destroy edit update]

  # (POST) save a new Package
  # /package_pages
  # package_pages_path
  # package_page_url
  def create
    @package_page  = PackagePage.create(package_page_params)
    @package_pages = PackagePage.where(tenant: I18n.t('tenant.id'))

    respond_to do |format|
      format.js { render partial: 'package_pages/js/show', locals: { cards: %w[dropdown edit] } }
      format.html { redirect_to package_manager_path }
    end
  end

  # (DELETE) destroy a PackagePage
  # /package_pages/:id
  # package_page_path(:id)
  # package_page_url(:id)
  def destroy
    @package_page.destroy
    @package_page  = PackagePage.new
    @package_pages = PackagePage.where(tenant: I18n.t('tenant.id'))

    respond_to do |format|
      format.js { render partial: 'package_pages/js/show', locals: { cards: %w[dropdown index] } }
      format.html { redirect_to package_manager_path }
    end
  end

  # (GET) show PackagePage to edit
  # /package_pages/:id/edit
  # edit_package_page_path(:id)
  # edit_package_page_url(:id)
  def edit
    respond_to do |format|
      format.js { render partial: 'package_pages/js/show', locals: { cards: %w[edit] } }
      format.html { redirect_to package_manager_path }
    end
  end

  # (GET) list PackagePages
  # /package_pages
  # package_pages_path
  # package_pages_url
  def index
    @package_page  = PackagePage.new
    @package_pages = PackagePage.where(tenant: I18n.t('tenant.id'))

    respond_to do |format|
      format.js { render partial: 'package_pages/js/show', locals: { cards: %w[dropdown edit] } }
      format.html { redirect_to package_manager_path }
    end
  end

  # (GET) new PackagePage
  # /package_pages/new
  # new_package_page_path
  # new_package_page_url
  def new
    @package_page = PackagePage.new(name: 'New Package/Page', primary_package: 1)

    respond_to do |format|
      format.js { render partial: 'package_pages/js/show', locals: { cards: %w[edit] } }
      format.html { redirect_to package_manager_path }
    end
  end

  # (GET) show Package manager
  # /packagepages
  # packagepages_path
  # packagepages_url
  def show
    @package_pages = PackagePage.where(tenant: I18n.t('tenant.id'))

    respond_to do |format|
      format.js { render js: "window.location = '#{packagepages_path}'" }
      format.html { render 'package_pages/show' }
    end
  end

  # (GET) return package hash for specific PackagePage
  # /package_pages/:id/select
  # package_pages_select_path(:id)
  # package_pages_select_url(:id)
  def select
    @package_page       = params.include?(:id) ? PackagePage.find_by(id: params[:id]) : nil
    selected_package_id = params.dig(:selected_package_id).to_i

    respond_to do |format|
      format.js { render partial: 'clients/js/show', locals: { cards: [11], selected_package_id: } }
      format.html { redirect_to package_manager_path }
    end
  end

  # (PUT/PATCH) update existing PackagePage
  # /package_pages/:id
  # package_page_path(:id)
  # package_page_url(:id)
  def update
    @package_page.update(package_page_params)

    if params.dig(:commit).to_s.casecmp?('copy')
      # copy Package
      @package_page = @package_page.copy || PackagePage.new
    end

    @package_pages = PackagePage.where(tenant: I18n.t('tenant.id'))

    respond_to do |format|
      format.js { render partial: 'package_pages/js/show', locals: { cards: %w[dropdown edit] } }
      format.html { redirect_to package_manager_path }
    end
  end

  private

  def authorize_user!
    super
    return if current_user.team_member?

    raise ExceptionHandlers::UserNotAuthorized.new('Packages', root_path)
  end

  def package_page_params
    if params.include?(:package_page)
      params.require(:package_page).permit(:name, :sys_default, :primary_package, :package_01_id, :package_02_id, :package_03_id, :package_04_id)
    else
      {}
    end
  end

  def set_package_page
    if params.include?(:id)

      sweetalert_warning('Unable to Confirm Access!', 'Package Page cound NOT be found.', '', { persistent: 'OK' }) unless (@package_page = PackagePage.find_by(tenant: I18n.t('tenant.id'), id: params[:id]))
    else
      sweetalert_warning('Unable to Confirm Access!', 'Package Page was NOT received.', '', { persistent: 'OK' })
      @package_page = nil
    end

    return if @package_page

    respond_to do |format|
      format.js { render js: "window.location = '#{packagemanager_path}'" and return false }
      format.html { redirect_to packagemanager_path and return false }
    end
  end
end
