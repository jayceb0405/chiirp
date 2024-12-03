# frozen_string_literal: true

# app/controllers/campaigns_controller.rb
class UserContactFormMarketplacesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user_contact_form, only: %i[approve buy edit image show update]

  def approve
    # (POST) approve a  UserContactForm for Marketplace
    # /user_contact_form_marketplaces/:id/approve
    # approve_user_contact_form_path(:id)
    # approve_user_contact_form_url(:id)
    if @user_contact_form.marketplace_ok
      @user_contact_form.update(marketplace_ok: false)
    else
      @user_contact_form.update(marketplace_ok: true)
    end

    respond_to do |format|
      format.js { render js: "window.location = '#{user_contact_form_marketplaces_path}'" }
      format.html { redirect_to user_contact_form_marketplaces_path }
    end
  end

  def buy
    # (POST) get/buy a UserContactForm
    # /user_contact_form_marketplaces/:id/buy
    # buy_user_contact_form_path(:id)
    # buy_user_contact_form_url(:id)
    if @user_contact_form.price.to_d.zero? || current_user.client.credit_card_on_file?
      # UserContactForm has no cost or credit card is on file
      new_user_contact_form = nil

      if @user_contact_form.price.to_d.positive?
        # UserContactForm has a cost
        result = current_user.client.charge_card(
          charge_amount: @user_contact_form.price.to_d,
          setting_key:   'user_contact_form_charge'
        )

        if result[:success]
          # credit card charge succeeded
          new_user_contact_form = @user_contact_form.copy(new_user_id: current_user.id)
        else
          # credit card charge failed
          sweetalert_error('QuickPage could NOT be added!', result[:error_message], '', { persistent: 'OK' })
        end
      else
        # UserContactForm has no cost
        new_user_contact_form = @user_contact_form.copy(new_user_id: current_user.id)
      end

      if new_user_contact_form
        # UserContactForm was copied successfully
        sweetalert_success('Congratulations!', "QuickPage: #{new_user_contact_form.form_name} was added successfully.", '', { persistent: 'OK' })
      end
    else
      # no credit card on file
      sweetalert_error('QuickPage could NOT be added!', 'A credit card is not on file.', '', { persistent: 'OK' })
    end

    respond_to do |format|
      format.js { render js: "window.location = '#{user_contact_forms_path}'" }
      format.html { redirect_to user_contact_forms_path }
    end
  end

  def edit
    # (GET) edit UserContactForm marketplace data
    # /user_contact_form_marketplaces/:id/edit
    # edit_user_contact_form_marketplace_path(:id)
    # edit_user_contact_form_marketplace_utl(:id)
    respond_to do |format|
      format.js { render partial: 'user_contact_form_marketplaces/js/show', locals: { cards: %w[edit] } }
      format.html { redirect_to user_contact_forms_path }
    end
  end

  def image
    # (PATCH) add an image to a UserContactForm in a marketplace
    # /user_contact_form_marketplaces/:id/image
    # image_user_contact_form_marketplaces_path(:id)
    # image_user_contact_form_marketplaces_url(:id)
    marketplace_image_delete = params.include?(:marketplace_image_delete) && params[:marketplace_image_delete].to_s.casecmp?('true')
    marketplace_image        = user_contact_form_params.include?(:marketplace_image) ? user_contact_form_params[:marketplace_image] : nil

    if marketplace_image_delete
      # deleting an image
      @user_contact_form.marketplace_image.purge
    elsif marketplace_image
      @user_contact_form.update(user_contact_form_params)
    end

    respond_to do |format|
      format.json { render json: { imageUrl: Cloudinary::Utils.cloudinary_url(@user_contact_form.marketplace_image.key, { secure_distribution: I18n.t("tenant.#{Rails.env}.cloudinary_cname"), transformation: [width: 200, height: 200, crop: 'fit'], format: 'png' }), status: 200 } }
      format.js { render partial: 'user_contact_form_marketplaces/js/show', locals: { cards: %w[edit] } }
      format.html { redirect_to user_contact_forms_path }
    end
  end

  def index
    # (GET) list UserContactForms available in UserContactFormMarketplace
    # /user_contact_form_marketplaces
    # user_contact_form_marketplaces_path
    # user_contact_form_marketplaces_url
    @user_contact_forms = UserContactForm.by_tenant(I18n.t('tenant.id')).where(marketplace_ok: true).order(:form_name)
    @user_contact_forms_unapproved = UserContactForm.by_tenant(I18n.t('tenant.id')).where(marketplace: true, marketplace_ok: false).order(:form_name)

    respond_to do |format|
      format.js { render js: "window.location = '#{user_contact_form_marketplaces_path}'" }
      format.html { render 'user_contact_form_marketplaces/index' }
    end
  end

  def show
    # (GET) show a UserContactForm to get/buy
    # /user_contact_form_marketplaces/:id
    # user_contact_form_marketplace_path(:id)
    # user_contact_form_marketplace_url(:id)
    respond_to do |format|
      format.js { render partial: 'user_contact_form_marketplaces/js/show', locals: { cards: %w[show] } }
      format.html { redirect_to user_contact_forms_path }
    end
  end

  def update
    # (PUT/PATCH) save updated UserContactForm marketplace data
    # /user_contact_form_marketplaces/:id
    # user_contact_form_marketplace_path(:id)
    # user_contact_form_marketplace_url(:id)
    @user_contact_form.update(user_contact_form_params)

    if params.include?(:commit) && params[:commit].casecmp?('submit to marketplace')
      @user_contact_form.update(marketplace: true)
    elsif params.include?(:commit) && params[:commit].casecmp?('withdraw from marketplace')
      @user_contact_form.update(marketplace: false, marketplace_ok: false)
    end

    respond_to do |format|
      format.js { render partial: 'user_contact_form_marketplaces/js/show', locals: { cards: %w[edit] } }
      format.html { redirect_to user_contact_forms_path }
    end
  end

  private

  def set_user_contact_form
    @user_contact_form = if params.include?(:id) && params[:id].to_i.zero?
                           current_user.user_contact_forms.new
                         else
                           UserContactForm.find_by(id: params[:id].to_i)
                         end

    return if @user_contact_form

    sweetalert_error('Contact form NOT found!', 'We were not able to access the Contact form you requested.', '', { persistent: 'OK' })

    respond_to do |format|
      format.js { render js: "window.location = '#{user_contact_forms_path}'" and return false }
      format.html { redirect_to user_contact_forms_path and return false }
    end
  end

  def user_contact_form_params
    response = if params.include?(:user_contact_form)
                 params.require(:user_contact_form).permit(:description, :price, :marketplace_image)
               else
                 {}
               end

    response[:price] = response[:price].to_d if response.include?(:price)

    response
  end
end
