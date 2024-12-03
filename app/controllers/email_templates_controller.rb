# frozen_string_literal: true

# app/controllers/email_templates_controller.rb
class EmailTemplatesController < ApplicationController
  class EmailTemplatesControllerError < StandardError; end

  before_action :authenticate_user!
  before_action :authorize_user!
  before_action :set_email_template, only: %i[destroy edit update]

  # (POST) create a new email template
  # /email_templates
  # email_templates_path
  # email_templates_url
  def create
    @email_template = current_user.client.email_templates.create(email_template_params)
    @email_template.version = 2
    @email_templates = current_user.client.email_templates.order(:name)

    respond_to do |format|
      format.js { render partial: 'email_templates/js/show', locals: { cards: %w[edit dropdown] } }
      format.html { redirect_to email_templates_path }
    end
  end

  # (DELETE) destroy a email template
  # /email_templates/:id
  # email_template_path(:id)
  # email_template_url(:id)
  def destroy
    @email_template.destroy
    @email_template  = current_user.client.email_templates.new
    @email_templates = current_user.client.email_templates.order(:name)
    @admin_email_templates = EmailTemplate.global.order(:name) if current_user.team_member?

    respond_to do |format|
      format.js { render partial: 'email_templates/js/show', locals: { cards: %w[index dropdown] } }
      format.html { redirect_to email_templates_path }
    end
  end

  # (GET) show edit screen for email template
  # /email_templates/:id/edit
  # edit_email_template_path(:id)
  # edit_email_template_url(:id)
  def edit
    respond_to do |format|
      format.js { render partial: 'email_templates/js/show', locals: { cards: %w[edit] } }
      format.html { redirect_to email_templates_path }
    end
  end

  # (GET) set up for a new email template
  # /email_templates/new
  # new_email_template_path
  # new_email_template_url
  def new
    @email_template = current_user.client.email_templates.new(name: 'New Email Template', version: 2)

    respond_to do |format|
      format.js { render partial: 'email_templates/js/show', locals: { cards: %w[edit] } }
      format.html { redirect_to email_templates_path }
    end
  end

  # (GET) show Email Templates
  # /email_templates
  # email_templates_path
  # email_templates_url
  def show
    @email_template  = current_user.client.email_templates.new
    @email_templates = current_user.client.email_templates.order(:name)
    @admin_email_templates = EmailTemplate.global.order(:name) if current_user.team_member?

    respond_to do |format|
      format.js { render js: "window.location = '#{root_path}'" }
      format.html { render 'email_templates/show' }
    end
  end

  # (PUT/PATCH) update a email template
  # /email_templates/:id
  # email_template_path(:id)
  # email_template_url(:id)
  def update
    @email_template.update(email_template_params)
    @email_template.update(client_id: nil) if current_user.team_member? && params.dig(:email_template, 'make_template').to_bool
    @email_templates = current_user.client.email_templates.order(:name)

    respond_to do |format|
      format.js { render partial: 'email_templates/js/show', locals: { cards: %w[edit dropdown] } }
      format.html { redirect_to email_templates_path }
    end
  end

  # (PUT/PATCH) import an Email Template
  # /email_templates/import
  # email_templates_import_path
  # email_templates_import_url
  def import
    if params.permit(:share_code).dig(:share_code).present?
      if (email_template = EmailTemplate.find_by(share_code: params.permit(:share_code).dig(:share_code)))
        @email_template = email_template.copy(new_client_id: current_user.client.id)

        if @email_template
          sweetalert_success('Email Template Import Success!', "Hurray! '#{@email_template.name}' was imported successfully.", '', { persistent: 'OK' })
        else
          sweetalert_warning('Something went wrong!', '', "Sorry, we couldn't import that Email Template.", { persistent: 'OK' })

          error = EmailTemplatesControllerError.new("Email Template Import Error: Email Template #{email_template.id}")
          error.set_backtrace(BC.new.clean(caller))

          Appsignal.report_error(error) do |transaction|
            # Only needed if it needs to be different or there's no active transaction from which to inherit it
            Appsignal.set_action('EmailTemplatesController#import')

            # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
            Appsignal.add_params(params)

            Appsignal.set_tags(
              error_level: 'error',
              error_code:  0
            )
            Appsignal.add_custom_data(
              email_template:,
              new_email_template: @email_template,
              user:               {
                id:   current_user.id,
                name: current_user.fullname
              },
              file:               __FILE__,
              line:               __LINE__
            )
          end
        end
      else
        sweetalert_warning('Email Template Not Found!', 'Sorry, we couldn\'t find that share code. Please verify the code and try again.', '', { persistent: 'OK' })
      end
    else
      sweetalert_warning('Share Code Not Entered!', 'Sorry, a share code was NOT entered. Please enter the code and try again.', '', { persistent: 'OK' })
    end

    @email_templates = current_user.client.email_templates.order(:name)
    render partial: 'email_templates/js/show', locals: { cards: %w[index] }
  end

  # Images are now automated and this isn't needed. Keeping for now in case the automation doesn't work correctly.
  # (PATCH) add an image to an Email Template
  # /email_templates/:email_template_id/image
  # email_template_image_path(:id)
  # email_template_image_url(:id)
  # def image
  #   head :unauthorized and return unless current_user.team_member?

  #   @email_template   = EmailTemplate.find_by(id: params[:email_template_id])
  #   image_delete      = params.dig(:image_delete).to_bool
  #   thumbnail         = params.dig(:email_template, :thumbnail)

  #   if image_delete
  #     # deleting an image
  #     @email_template.thumbnail.purge
  #   elsif thumbnail
  #     @email_template.update(thumbnail:)
  #   end

  #   respond_to do |format|
  #     format.json { render json: { imageUrl: Cloudinary::Utils.cloudinary_url(@email_template.thumbnail.key, { secure_distribution: I18n.t("tenant.#{Rails.env}.cloudinary_cname"), transformation: [width: 200, height: 200, crop: 'fit'], format: 'png' }), status: :success } }
  #     format.js { render partial: 'email_templates/js/show', locals: { cards: %w[thumbnail] } }
  #     format.html { redirect_to email_templates_path }
  #   end
  # end

  private

  def authorize_user!
    super
    return if current_user&.access_controller?('email_templates', 'allowed', session)

    raise ExceptionHandlers::UserNotAuthorized.new('Email Templates', root_path)
  end

  def set_email_template
    if params.dig(:id).to_i.zero?
      @email_template = current_user.client.email_templates.new
    else
      @email_template = if current_user.team_member?
                          EmailTemplate.find_by(id: params[:id], client_id: [nil, current_user.client_id])
                        else
                          current_user.client.email_templates.find_by(id: params[:id])
                        end

      unless @email_template
        sweetalert_error('Email Template NOT found!', 'We were not able to access the Email Template you requested.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{email_templates_path}'" and return false }
          format.html { redirect_to email_templates_path and return false }
        end
      end
    end
  end

  def email_template_params
    if current_user.team_member?
      params.require(:email_template).permit(:name, :content, :subject, :html, :css, :category)
    else
      params.require(:email_template).permit(:name, :content, :subject, :html, :css)
    end
  end
end
