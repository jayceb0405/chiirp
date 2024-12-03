# frozen_string_literal: true

# app/controllers/clients/custom_fields_controller.rb
module Clients
  class CustomFieldsController < Clients::ClientController
    before_action :authenticate_user!
    before_action :client
    before_action :authorize_user!
    before_action :set_custom_field, only: %i[destroy edit important update]

    # (POST)
    # /client/:client_id/custom_fields
    # client_custom_fields_path(:client_id)
    # client_custom_fields_url(:client_id)
    def create
      @custom_field = current_user.client.client_custom_fields.create(params_custom_field)
      @custom_field.var_options = update_var_options(var_type: @custom_field.var_type, params:)
      @custom_field.var_important = true
      @custom_field.save

      respond_to do |format|
        format.js   { render partial: 'clients/js/show', locals: { cards: %w[custom_fields] } }
        format.html { redirect_to root_path }
      end
    end

    # (DELETE)
    # /client/:client_id/custom_fields/:id
    # client_custom_field_path(:client_id, :id)
    # client_custom_field_url(:client_id, :id)
    def destroy
      @custom_field.destroy
      @custom_field = nil

      respond_to do |format|
        format.js   { render partial: 'clients/js/show', locals: { cards: %w[custom_fields] } }
        format.html { redirect_to root_path }
      end
    end

    # (GET)
    # /client/:client_id/custom_fields/:id/edit
    # edit_client_custom_field_path(:client_id, :id)
    # edit_client_custom_field_url(:client_id, :id)
    def edit
      respond_to do |format|
        format.js   { render partial: 'clients/js/show', locals: { cards: %w[custom_fields_edit] } }
        format.html { redirect_to root_path }
      end
    end

    # (PATCH) mark a ClientCustomField as important
    # /client/:client_id/custom_fields/:id/important
    # important_client_custom_field_path(:client_id, :id)
    # important_client_custom_field_url(:client_id, :id)
    def important
      @custom_field.update(var_important: !@custom_field.var_important)

      respond_to do |format|
        format.js   { render partial: 'clients/js/show', locals: { cards: %w[custom_fields] } }
        format.html { redirect_to root_path }
      end
    end

    # (GET)
    # /client/:client_id/custom_fields
    # client_custom_fields_path(:client_id)
    # client_custom_fields_url(:client_id)
    def index
      respond_to do |format|
        format.js   { render partial: 'clients/js/show', locals: { cards: %w[custom_fields] } }
        format.html { render 'clients/show', locals: { client_page_section: 'custom_fields' } }
      end
    end

    # (GET)
    # /client/:client_id/custom_fields/new
    # new_client_custom_field_path(:client_id)
    # new_client_custom_field_url(:client_id)
    def new
      @custom_field = current_user.client.client_custom_fields.new

      respond_to do |format|
        format.js   { render partial: 'clients/js/show', locals: { cards: %w[custom_fields] } }
        format.html { redirect_to root_path }
      end
    end

    # (PUT/PATCH)
    # /client/:client_id/custom_fields/:id
    # client_custom_field_path(:client_id, :id)
    # client_custom_field_url(:client_id, :id)
    def update
      @custom_field.var_options = update_var_options(var_type: @custom_field.var_type, params:)
      @custom_field.update(params_custom_field)
      # @custom_field.save

      respond_to do |format|
        format.js   { render partial: 'clients/js/show', locals: { cards: %w[custom_fields] } }
        format.html { redirect_to root_path }
      end
    end

    private

    def authorize_user!
      super

      return if current_user.access_controller?('clients', 'custom_fields', session)

      raise ExceptionHandlers::UserNotAuthorized.new('My Company Profile > Custom Fields', root_path)
    end

    def params_custom_field
      params.require(:client_custom_field).permit(:var_name, :var_placeholder, :var_type, :image_is_valid, :var_important)
    end

    def set_custom_field
      custom_field_id = params.dig(:id).to_i

      return if custom_field_id.positive? && (@custom_field = @client.client_custom_fields.find_by(id: custom_field_id))

      sweetalert_error('Unathorized Access!', 'Your account could NOT be confirmed.', '', { persistent: 'OK' })

      respond_to do |format|
        format.js { render js: "window.location = '#{root_path}'" and return false }
        format.html { redirect_to root_path and return false }
      end
    end

    def update_var_options(args)
      var_type = args.dig(:var_type).to_s
      response = {}

      if var_type.present?
        var_options = args.dig(:params).require(:client_custom_field).permit(var_options: %i[string_options numeric_min numeric_max stars_max currency_min currency_max]).dig(:var_options) || {}

        case var_type
        when 'string'
          response[:string_options] = var_options.dig(:string_options).to_s
        when 'numeric'
          response[:numeric_min] = var_options.dig(:numeric_min).to_f
          response[:numeric_max] = var_options.dig(:numeric_max).to_f
        when 'stars'
          response[:stars_max] = var_options.dig(:stars_max).to_i
        when 'currency'
          response[:currency_min] = var_options.dig(:currency_min).to_f
          response[:currency_max] = var_options.dig(:currency_max).to_f
        end
      end

      response
    end
  end
end
