# frozen_string_literal: true

# app/controllers/twnumbers_controller.rb
class TwnumbersController < ApplicationController
  skip_before_action :verify_authenticity_token, only: %i[subscription_callback]
  before_action :authenticate_user!, only: %i[create]
  before_action :authorize_user!, only: %i[create]
  before_action :client, only: %i[create]

  # (POST) find phone numbers for Client
  # /clients/:client_id/twnumbers?referer=String
  # client_twnumbers_path(:client_id, referer: String)
  # client_twnumbers_url(:client_id, referer: String)
  def create
    sanitized_params = params.permit(:referer, :commit, :phone_number)

    case sanitized_params.dig(:commit).to_s.downcase
    when 'search'
      @available_phone_numbers = PhoneNumbers::Router.find(phone_vendor: @client.phone_vendor, contains: sanitized_params.dig(:phone_number), area_code: params.dig(:area_code).to_s, local: params.dig(:local).to_bool, toll_free: params.dig(:toll_free).to_bool)

      respond_to do |format|
        format.js { render partial: 'twnumbers/js/modal_form', locals: { referer: sanitized_params.dig(:referer) } }
        format.html { redirect_to edit_clients_overview_path(@client) }
      end

      return
    when 'buy'
      result = PhoneNumbers::Router.buy(phone_vendor: @client.phone_vendor, tenant: @client.tenant, client_id: @client.id, client_name: @client.name, phone_number: sanitized_params.dig(:phone_number))

      @twnumber = if result[:success]
                    @client.twnumbers.create(
                      phonenumber:     result[:phone_number],
                      name:            ActionController::Base.helpers.number_to_phone(result[:phone_number].clean_phone(@client.primary_area_code)),
                      vendor_id:       result[:phone_number_id],
                      phone_vendor:    result[:phone_vendor],
                      vendor_order_id: result[:vendor_order_id]
                    )
                  else
                    @client.twnumbers.new
                  end
    end

    @twnumbers = @client.twnumbers.order(:name, :phonenumber)

    respond_to do |format|
      if sanitized_params.dig(:referer).to_s.casecmp?('dashboard')
        # called from onboarding Dashboard
        format.js   { render js: "window.location = '#{root_path}'" }
        format.html { redirect_to root_path }
      elsif sanitized_params.dig(:referer).to_s.casecmp?('phone_numbers') && !sanitized_params.dig(:commit).to_s.casecmp?('buy')
        format.js   { render partial: 'twnumbers/js/modal_form' }
        format.html { redirect_to edit_clients_overview_path(@client) }
      elsif sanitized_params.dig(:referer).to_s.casecmp?('phone_numbers') && sanitized_params.dig(:commit).to_s.casecmp?('buy')
        format.js   { render partial: 'clients/js/show', locals: { cards: %w[dash_modal_hide phone_numbers] } }
        format.html { redirect_to root_path }
      end
    end
  end

  # (POST) Bandwidth subscription callback on phone number order
  # /twnumbers/subscription_callback
  # subscription_callback_twnumber_path
  # subscription_callback_twnumber_url
  def subscription_callback
    body   = request.body.read
    result = PhoneNumbers::Router.subscription_callback params.merge(body:)

    if result[:success] && result[:phone_number].present? && (twnumber = Twnumber.find_by(phonenumber: result[:phone_number]))

      if result[:completed] && twnumber.vendor_order_id == result[:vendor_order_id]
        twnumber.update(vendor_id: twnumber.vendor_order_id, vendor_order_id: '')
      elsif result[:failed] && twnumber.vendor_order_id == result[:vendor_order_id]
        twnumber.destroy
      end

      Rails.logger.info "TwnumbersController#subscription_callback: #{{ body:, result:, client_id: twnumber.client_id }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"

      cable = UserCable.new
      html  = ApplicationController.render partial: 'clients/phone_numbers/status', locals: { twnumber: }

      User.client_admins(twnumber.client_id).each do |user|
        cable.broadcast twnumber.client, user, { id: "twnumber_status_#{twnumber.id}", append: 'false', scrollup: 'false', html: }
      end
    else
      Rails.logger.info "TwnumbersController#subscription_callback: #{{ body: request.body.read, result: }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
    end

    render plain: 'Success', content_type: 'text/plain', layout: false, status: :ok
  end
  # body ex:
  # <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  # <Notification>
  #   <Status>COMPLETE</Status>
  #   <SubscriptionId>e73f1bf9-f300-4f72-9eea-e2f4ea32e024</SubscriptionId>
  #   <Message>Created a new number order for 1 number from BLACKSHEAR, GA</Message>
  #   <OrderId>49df4009-b183-4642-b989-8d78ed6bacb9</OrderId>
  #   <OrderType>orders</OrderType>
  #   <CompletedTelephoneNumbers>
  #     <TelephoneNumber>9122087804</TelephoneNumber>
  #   </CompletedTelephoneNumbers>
  #   <LastModifiedDate>2024-02-22T20:40:47.539Z</LastModifiedDate>
  # </Notification>

  private

  def authorize_user!
    super
    return if current_user.access_controller?('clients', 'phone_numbers', session)

    raise ExceptionHandlers::UserNotAuthorized.new('Phone Numbers', root_path)
  end

  def client
    return unless (@client = Client.find_by(id: params.dig(:client_id))).nil?

    sweetalert_error('Client NOT found!', 'We were not able to access the client you requested.', '', { persistent: 'OK' }) if current_user.team_member?

    respond_to do |format|
      format.js { render js: "window.location = '#{root_path}'" and return false }
      format.html { redirect_to root_path and return false }
    end
  end
end
