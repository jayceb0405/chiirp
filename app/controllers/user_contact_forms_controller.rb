# frozen_string_literal: true

# app/controllers/user_contact_forms_controller.rb
class UserContactFormsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user!
  before_action :set_user_contact_form, only: %i[destroy]

  # (DELETE) destroy a UserContactForm
  # /user_contact_forms/:id
  # user_contact_form_path(:id)
  # user_contact_form_url(:id)
  def destroy
    @user_contact_form.destroy unless @user_contact_form.new_record?
    @user_contact_forms = current_user.user_contact_forms.order(:form_name)

    respond_to do |format|
      format.js { render partial: 'user_contact_forms/js/show', locals: { cards: %w[index user_contact_forms_dropdown] } }
      format.html { redirect_to quicklead_path }
    end
  end

  # (POST) import a shared UserContactForm
  # /user_contact_forms/import
  # import_user_contact_form_path
  # import_user_contact_form_url
  def import
    share_code = params.dig(:share_code).to_s

    if share_code.present? && (user_contact_form = UserContactForm.find_by(share_code:))
      # create new UserContactForm

      if (@user_contact_form = user_contact_form.copy(new_user_id: current_user.id))
        # new UserContactForm was saved successfully
        sweetalert_success('QuickPage Import Success!', "Hurray! '#{@user_contact_form.form_name}' was imported successfully.", '', { persistent: 'OK' })
      else
        # new Campaign was NOT saved successfully
        sweetalert_warning('Something went wrong!', '', "Sorry, we couldn't import that QuickPage. <ul>#{@user_contact_form.errors.full_messages.collect { |m| "#{m} & " }}.", { persistent: 'OK' })
        @user_contact_form = current_user.user_contact_forms.new
      end
    else
      # shared Campaign was NOT found
      sweetalert_warning('QuickPage Not Found!', 'Sorry, we couldn\'t find that share code. Please verify the code and try again.', '', { persistent: 'OK' })
      @user_contact_form = current_user.user_contact_forms.new
    end

    @user_contact_forms = current_user.user_contact_forms.order(:form_name)

    respond_to do |format|
      format.js   { render partial: 'user_contact_forms/js/show', locals: { cards: %w[index user_contact_forms_dropdown hide_dash_modal] } }
      format.html { redirect_to quicklead_path }
    end
  end

  # (GET) list all UserCustomForm
  # /user_contact_forms
  # user_contact_forms_path
  # user_contact_forms_url
  def index
    @user_contact_forms = current_user.user_contact_forms.order(:form_name)

    respond_to do |format|
      format.js   { render partial: 'user_contact_forms/js/show', locals: { cards: %w[index] } }
      format.html { render 'user_contact_forms/index' }
    end
  end

  # (GET)
  # /user_contact_form/import/index
  # index_import_user_contact_form_path
  # index_import_user_contact_form_url
  def index_import
    respond_to do |format|
      if current_user.user_contact_forms.length < current_user.client.quick_leads_count && current_user.client.share_quick_leads_allowed
        format.js   { render partial: 'user_contact_forms/js/show', locals: { cards: %w[import] } }
        format.html { redirect_to user_contact_forms_path }
      else
        format.js   { render js: "window.location = '#{user_contact_forms_path}'" and return false }
        format.html { redirect_to user_contact_forms_path and return false }
      end
    end
  end

  private

  def authorize_user!
    super
    return if current_user.access_controller?('user_contact_forms', 'allowed', session)

    raise ExceptionHandlers::UserNotAuthorized.new('QuickPages', root_path)
  end

  def set_user_contact_form
    @user_contact_form = current_user.user_contact_forms.find_by(id: params.dig(:id).to_i) || current_user.user_contact_forms.new
  end
end
