# frozen_string_literal: true

# app/controllers/clients/phone_numbers_controller.rb
module Clients
  # support for Client phone number endpoints
  class PhoneNumbersController < Clients::ClientController
    before_action :authenticate_user!
    before_action :client
    before_action :authorize_user!
    before_action :set_twnumber, only: %i[destroy edit update]

    # (DELETE)
    # /client/:client_id/phone_numbers/:id
    # client_phone_number_path(:client_id, :id)
    # client_phone_number_url(:client_id, :id)
    def destroy
      @twnumber.destroy
      @twnumber = nil

      respond_to do |format|
        format.js { render partial: 'clients/js/show', locals: { cards: %w[phone_numbers] } }
        format.html { redirect_to root_path }
      end
    end

    # (GET)
    # /client/:client_id/phone_numbers/:id/edit
    # edit_client_phone_number_path(:client_id, :id)
    # edit_client_phone_number_url(:client_id, :id)
    def edit
      respond_to do |format|
        format.js { render partial: 'clients/js/show', locals: { cards: %w[phone_numbers_edit] } }
        format.html { redirect_to root_path }
      end
    end

    # (GET)
    # /client/:client_id/phone_numbers
    # client_phone_numbers_path(:client_id)
    # client_phone_numbers_url(:client_id)
    def index
      respond_to do |format|
        format.js { render partial: 'clients/js/show', locals: { cards: %w[phone_numbers] } }
        format.html { render 'clients/show', locals: { client_page_section: 'phone_numbers' } }
      end
    end

    # (PUT/PATCH)
    # /client/:client_id/phone_numbers/:id
    # client_phone_number_path(:client_id, :id)
    # client_phone_number_url(:client_id, :id)
    def update
      @twnumber.update(params_phonenumber)

      user_ids = [params.dig(:user_ids) || []].flatten
      user_ids = user_ids.reject(&:empty?).map(&:to_i)

      # add selected Users not already assigned
      @client.users.where(id: (user_ids - @twnumber.twnumberusers.pluck(:user_id))).find_each do |user|
        @twnumber.twnumberusers.create(user_id: user.id, def_user: false)
      end

      # remove existing Users no longer assigned
      @twnumber.twnumberusers.where.not(user_id: user_ids).find_each(&:destroy)

      # rubocop:disable Rails/SkipsModelValidations
      @twnumber.twnumberusers.update_all(def_user: false)
      # rubocop:enable Rails/SkipsModelValidations

      if (twnumberuser = @twnumber.twnumberusers.find_by(user_id: params.dig(:def_user_id).to_i))
        twnumberuser.update(def_user: true)
      end

      respond_to do |format|
        format.js { render partial: 'clients/js/show', locals: { cards: %w[phone_numbers_edit td_twnumber_name td_twnumber_user] } }
        format.html { redirect_to root_path }
      end
    end

    private

    def authorize_user!
      super
      return if current_user.access_controller?('clients', 'phone_numbers', session)

      raise ExceptionHandlers::UserNotAuthorized.new('My Company Profile > Phone Numbers', root_path)
    end

    def set_twnumber
      twnumber_id = params.permit(:id).dig(:id).to_i

      return if twnumber_id.positive? && (@twnumber = @client.twnumbers.find_by(id: twnumber_id))

      sweetalert_error('Unathorized Access!', 'Your account could NOT be confirmed.', '', { persistent: 'OK' })

      respond_to do |format|
        format.js { render js: "window.location = '#{root_path}'" and return false }
        format.html { redirect_to root_path and return false }
      end
    end

    def params_phonenumber
      sanitized_params = params.require(:twnumber).permit(:announcement_recording_id, :hangup_detection_duration, :incoming_call_routing, :name, :pass_routing_method, :pass_routing_phone_number, :pass_routing_ring_duration, :vm_greeting_recording_id, sorted_routing: {})
      sanitized_params[:announcement_recording_id]  = sanitized_params.dig(:incoming_call_routing)&.include?('play') && sanitized_params.dig(:announcement_recording_id).to_i.positive? ? sanitized_params.dig(:announcement_recording_id).to_i : nil
      sanitized_params[:hangup_detection_duration]  = sanitized_params.dig(:hangup_detection_duration).to_i
      sanitized_params[:pass_routing]               = sanitized_params.dig(:incoming_call_routing)&.include?('pass') && sanitized_params.dig(:sorted_routing) ? sanitized_params[:sorted_routing].keys : []
      sanitized_params[:pass_routing_phone_number]  = sanitized_params.dig(:pass_routing)&.include?('phone_number') ? sanitized_params.dig(:pass_routing_phone_number) : ''
      sanitized_params[:pass_routing_ring_duration] = %w[play play_vm].include?(sanitized_params.dig(:incoming_call_routing)) ? 0 : (sanitized_params.dig(:pass_routing_ring_duration) || 0).to_i
      sanitized_params[:vm_greeting_recording_id]   = sanitized_params.dig(:incoming_call_routing)&.include?('pass') && sanitized_params.dig(:vm_greeting_recording_id).to_i.positive? ? sanitized_params.dig(:vm_greeting_recording_id).to_i : nil
      sanitized_params.delete(:sorted_routing)

      sanitized_params
    end
  end
end
