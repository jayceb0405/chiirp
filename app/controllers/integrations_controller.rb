# frozen_string_literal: true

# app/controllers/integrations_controller.rb
class IntegrationsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:maestro_endpoint]
  before_action :authenticate_user!, except: [:maestro_endpoint]
  before_action :authorize_user!, except: [:maestro_endpoint]
  before_action :client, except: %i[maestro_contact_edit maestro_contact_update maestro_endpoint maestro_new_contact_update maestro_checkin_contact_update maestro_checkout_contact_update maestro_custom_field_assignments_update maestro_roommove_contact_update]
  before_action :client_api_integration, except: %i[index maestro_contact_edit maestro_contact_update maestro_endpoint]
  before_action :set_contact, only: %i[maestro_contact_edit maestro_contact_update]

  # (GET) list integrations available
  # /integrations
  # integrations_path
  # integrations_url
  def index
    render 'integrations/index'
  end

  # (PATCH) update user settings for integrations sorting
  # /integrations/user_settings
  # update_user_settings_integrations_path
  # update_user_settings_integrations_url
  def update_user_settings
    current_user.update(integrations_order: params[:integration_buttons].map(&:to_i))
  end

  # (PUT) save checkin_contact_actions
  # /integrations/maestro/checkin_contact
  # integrations_maestro_checkin_contact_update_path
  # integrations_maestro_checkin_contact_update_url
  def maestro_checkin_contact_update
    @client_api_integration.update(checkin_contact_actions: maestro_checkin_contact_params)

    respond_to do |format|
      format.js { render partial: 'integrations/maestro/js/show', locals: { cards: [3] } }
      format.html { render 'integrations/maestro/edit' }
    end
  end

  # (PUT) save checkout_contact_actions
  # /integrations/maestro/checkout_contact
  # integrations_maestro_checkout_contact_update_path
  # integrations_maestro_checkout_contact_update_url
  def maestro_checkout_contact_update
    @client_api_integration.update(checkout_contact_actions: maestro_checkout_contact_params)

    respond_to do |format|
      format.js { render partial: 'integrations/maestro/js/show', locals: { cards: [4] } }
      format.html { render 'integrations/maestro/edit' }
    end
  end

  # (GET) edit Contact data from Maestro
  # /integrations/maestro/contact/:contact_id
  # integrations_maestro_contact_edit_path(:contact_id)
  # integrations_maestro_contact_edit_url(:contact_id)
  def maestro_contact_edit
    @contact_api_integration = @contact.contact_api_integrations.find_by(target: 'maestro')

    respond_to do |format|
      format.js { render partial: 'contacts/js/show', locals: { cards: [7] } }
      format.html { redirect_to central_path }
    end
  end

  # (PATCH) update a ContactApiIntegration
  # /integrations/maestro/contact/:contact_id
  # integrations_maestro_contact_path(:contact_id)
  # integrations_maestro_contact_url(:contact_id)
  def maestro_contact_update
    @contact_api_integration = @contact.contact_api_integrations.find_by(target: 'maestro')
    @contact_api_integration.update(maestro_contact_params)

    respond_to do |format|
      format.js { render partial: 'contacts/js/show', locals: { cards: [8] } }
      format.html { redirect_to central_path }
    end
  end

  # (PUT) save Custom Field assignments
  # /integrations/maestro/custom_field_assignments
  # integrations_maestro_custom_field_assignments_update_path
  # integrations_maestro_custom_field_assignments_update_url
  def maestro_custom_field_assignments_update
    @client_api_integration.update(custom_field_assignments: maestro_custom_field_assignments_params)

    respond_to do |format|
      format.js { render partial: 'integrations/maestro/js/show', locals: { cards: [4] } }
      format.html { render 'integrations/maestro/edit' }
    end
  end

  # (GET) show Maestro edit page
  # /integrations/maestro
  # integrations_maestro_edit_path
  # integrations_maestro_edit_url
  def maestro_edit
    render 'integrations/maestro/edit'
  end

  # (POST) data endpoint posted from Maestro server
  # /integrations/maestro/endpoint
  # integrations_maestro_endpoint_path
  # integrations_maestro_endpoint_url
  def maestro_endpoint
    xml_params = Hash.from_xml(request.body.read)['Request']
    logger.debug "Maestro Parameters Received: #{xml_params.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
    result = Maestro.new.process_post(xml_params:)

    render xml: result.to_xml(root: 'Response')
  end

  # (PUT) save a Maestro hotel id
  # /integrations/maestro/hotelid
  # integrations_maestro_hotelid_update_path
  # integrations_maestro_hotelid_update_url
  def maestro_hotelid_update
    @client_api_integration.update(maestro_hotel_id_params)

    respond_to do |format|
      format.js { render partial: 'integrations/maestro/js/show', locals: { cards: [1] } }
      format.html { render 'integrations/maestro/edit' }
    end
  end

  # (PUT) save new_contact_actions
  # /integrations/maestro/new_contact
  # integrations_maestro_new_contact_update_path
  # integrations_maestro_new_contact_update_url
  def maestro_new_contact_update
    @client_api_integration.update(new_contact_actions: maestro_new_contact_params)

    respond_to do |format|
      format.js { render partial: 'integrations/maestro/js/show', locals: { cards: [2] } }
      format.html { render 'integrations/maestro/edit' }
    end
  end

  # (PUT) save roommove_contact_actions
  # /integrations/maestro/roommove_contact
  # integrations_maestro_roommove_contact_update_path
  # integrations_maestro_roommove_contact_update_url
  def maestro_roommove_contact_update
    @client_api_integration.update(roommove_contact_actions: maestro_roommove_contact_params)

    respond_to do |format|
      format.js { render partial: 'integrations/maestro/js/show', locals: { cards: [5] } }
      format.html { render 'integrations/maestro/edit' }
    end
  end

  # (GET) shoe Maestro test page
  # /integrations/maestro/test
  # integrations_maestro_test_path
  # integrations_maestro_test_url
  def maestro_test
    Maestro.new.salt_request_send(hotel_id: '1234', tenant: I18n.t('tenant.id'))
    render 'integrations/maestro/test'
  end

  private

  def authorize_user!
    super
    return if current_user.access_controller?('integrations', 'client', session) || current_user.access_controller?('integrations', 'user', session)

    raise ExceptionHandlers::UserNotAuthorized.new('Integrations', root_path)
  end

  def maestro_checkin_contact_params
    maestro_actions_normalized_params(:checkin_contact_actions)
  end

  def maestro_checkout_contact_params
    maestro_actions_normalized_params(:checkout_contact_actions)
  end

  def maestro_contact_params
    response = params.require(:contact_api_integration).permit(:client_code, :arrival_date, :departure_date, :guest_type, :checked_in, :room_number, :status)

    response[:checked_in] = response.include?(:checked_in) ? response[:checked_in].to_i : 0

    stay_dates = params.include?(:contact_api_integration) && params[:contact_api_integration].include?(:stay_dates) ? params[:contact_api_integration][:stay_dates].to_s.split(' to ') : {}
    response[:arrival_date] = stay_dates.present? ? ActiveSupport::TimeZone[@contact_api_integration.contact.client.time_zone].strptime(stay_dates[0], '%m/%d/%Y %I:%M %p').utc.strftime('%FT%TZ') : ''
    response[:departure_date] = stay_dates.length > 1 ? ActiveSupport::TimeZone[@contact_api_integration.contact.client.time_zone].strptime(stay_dates[1], '%m/%d/%Y %I:%M %p').utc.strftime('%FT%TZ') : response[:arrival_date]

    response
  end

  def maestro_custom_field_assignments_params
    params.require(:custom_field_assignments).permit(:status, :checked_in, :guest_type, :client_code, :room_number, :arrival_date, :departure_date)
  end

  def maestro_hotel_id_params
    response = params.permit(:api_key, :api_pass)

    response[:api_key]  ||= ''
    response[:api_pass] ||= ''

    response
  end

  def maestro_new_contact_params
    maestro_actions_normalized_params(:new_contact_actions)
  end

  def maestro_actions_normalized_params(field)
    sanitized_params = params.require(field.to_sym).permit(:campaign_id, :group_id, :stage_id, :tag_id, stop_campaign_ids: [])
    sanitized_params[:stop_campaign_ids] = sanitized_params[:stop_campaign_ids]&.compact_blank
    sanitized_params[:stop_campaign_ids] = [0] if sanitized_params[:stop_campaign_ids]&.include?('0')
    sanitized_params
  end

  def maestro_roommove_contact_params
    maestro_actions_normalized_params(:roommove_contact_actions)
  end

  def client
    if defined?(current_user)
      @client = current_user.client

      unless @client
        # current User is NOT authorized
        sweetalert_error('Unathorized Access!', 'Your account could NOT be confirmed.', '', { persistent: 'OK' })
      end
    else
      # only logged in Users may access any PackagePage actions
      sweetalert_error('Unathorized Access!', 'Your account could NOT be confirmed.', '', { persistent: 'OK' })
    end

    return if @client

    # Package id NOT defined

    respond_to do |format|
      format.js { render js: "window.location = '#{root_path}'" and return false }
      format.html { redirect_to root_path and return false }
    end
  end

  def set_contact
    if defined?(current_user) && params.include?(:contact_id)
      @contact = current_user.client.contacts.find_by(id: params[:contact_id].to_i)

      unless @contact
        # Contact was NOT found
        sweetalert_error('Unknown Contact!', 'The Contact you requested could not be found.', '', { persistent: 'OK' })
      end
    else
      # only logged in Users may access any PackagePage actions
      sweetalert_error('Unknown Contact!', 'A Contact was NOT requested.', '', { persistent: 'OK' })
    end

    return if @contact

    respond_to do |format|
      format.js { render js: "window.location = '#{root_path}'" and return false }
      format.html { redirect_to root_path and return false }
    end
  end

  def client_api_integration
    target = action_name.split('_')[0]
    @client_api_integration = current_user.client.client_api_integrations.find_or_create_by(target:, name: '')
  end
end
