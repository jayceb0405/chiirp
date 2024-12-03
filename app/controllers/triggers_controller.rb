# frozen_string_literal: true

# app/controllers/triggers_controller.rb
class TriggersController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_user!
  before_action :campaign
  before_action :trigger, only: %w[destroy edit update]

  # (POST) create a new Trigger
  # /campaigns/:campaign_id/triggers
  # campaign_triggers_path(:campaign_id)
  # campaign_triggers_url(:campaign_id)
  def create
    update_type  = params.permit(:update_type).dig(:update_type).to_bool
    trigger_type = params.permit(:trigger_type).dig(:trigger_type).to_i
    cards        = %w[triggers_list]

    if update_type && trigger_type.positive?
      @trigger = @campaign.triggers.find_by(id: params.permit(:id).dig(:id).to_i)
      @trigger.update(trigger_type:)
      cards << 'show_trigger_form'
    else
      @trigger = @campaign.triggers.create(trigger_type: @campaign.triggers.any? ? 100 : 115)
    end

    @campaign.update(analyzed: @campaign.analyze!.empty?)
    @campaigns = current_user.client.campaigns.with_trigger_type

    render partial: 'triggers/js/show', locals: { cards: }
  end

  # (DELETE) destroy a Trigger
  # /campaigns/:campaign_id/triggers/:id
  # campaign_trigger_path(:campaign_id, :id)
  # campaign_trigger_url(:campaign_id, :id)
  def destroy
    @trigger.destroy

    @campaign.update(analyzed: @campaign.analyze!.empty?)

    @trigger   = @campaign.triggers.new
    @campaigns = current_user.client.campaigns.with_trigger_type

    render partial: 'triggers/js/show', locals: { cards: %w[triggers_list] }
  end

  # (GET) move Trigger step_num up/down
  # /campaigns/:campaign_id/triggers/:id/edit
  # edit_campaign_trigger_path(:campaign_id, :id)
  # edit_campaign_trigger_url(:campaign_id, :id)
  def edit
    @campaign.triggers.where(step_numb: [@trigger.step_numb, (params[:d] == 'u' ? @trigger.step_numb - 1 : @trigger.step_numb + 1)]).find_each do |t|
      t.update(step_numb: (if t.step_numb == @trigger.step_numb
                             params[:d] == 'u' ? t.step_numb - 1 : t.step_numb + 1
                           else
                             (params[:d] == 'u' ? t.step_numb + 1 : t.step_numb - 1)
                           end))
    end

    @campaign.reload

    render partial: 'triggers/js/show', locals: { cards: %w[triggers_list] }
  end

  # (GET) set up a new Triggeraction
  # /campaigns/:campaign_id/triggers/new
  # new_campaign_trigger_path(:campaign_id)
  # new_campaign_trigger_url(:campaign_id)
  def new
    @trigger = if @campaign.triggers.any?
                 @campaign.triggers.create(trigger_type: 100)
               else
                 @campaign.triggers.new(trigger_type: 115)
               end

    render partial: 'triggers/js/show', locals: { cards: %w[triggers_new show_trigger_form] }
  end

  # (PUT/PATCH) update a Trigger
  # /campaigns/:campaign_id/triggers/:id
  # campaign_trigger_path(:campaign_id, :id)
  # campaign_trigger_url(:campaign_id, :id)
  def update
    cards = %w[triggers_list]
    @trigger.update(params_trigger)
    @campaign.update(analyzed: @campaign.analyze!.empty?)

    if @trigger.triggeractions.any?
      @triggeraction = @trigger.triggeractions.order(:sequence).first
    else
      @triggeraction = @trigger.triggeractions.new
      cards << 'triggeractions_new'
      cards << 'show_triggeraction_form'
    end

    render partial: 'triggers/js/show', locals: { cards: }
  end

  private

  def authorize_user!
    super
    return if current_user.access_controller?('campaigns', 'allowed', session)

    raise ExceptionHandlers::UserNotAuthorized.new('Campaign Builder', root_path)
  end

  def params_trigger
    sanitized_params = if params.include?(:data)
                         params.require(:data).permit(:name, :keyword, :keyword_location, :start_campaign_specific_date, :target_time, :repeat, :client_custom_field_id, :new_contacts_only, :phone_number, :process_times_a, :process_times_b, :process_sat, :process_sun, :process_mon, :process_tue, :process_wed, :process_thu, :process_fri, :repeat, :repeat_interval, :repeat_period)
                       else
                         {}
                       end

    sanitized_params = { data: @trigger.data.to_h.symbolize_keys.merge(sanitized_params.to_h.symbolize_keys) }
    sanitized_params[:name] = sanitized_params[:data].dig(:name).to_s.strip.presence || @trigger.name

    if sanitized_params[:data].dig(:start_campaign_specific_date).to_s.present?
      Time.zone = current_user.client.time_zone
      Chronic.time_class = Time.zone
      sanitized_params[:data][:start_campaign_specific_date] = Chronic.parse(sanitized_params[:data][:start_campaign_specific_date]).utc.strftime('%FT%TZ')
    end

    if sanitized_params[:data].dig(:target_time).to_s.present?
      Time.zone = current_user.client.time_zone
      Chronic.time_class = Time.zone
      sanitized_params[:data][:target_time] = Chronic.parse(sanitized_params[:data][:target_time]).utc.strftime('%FT%TZ')
    end

    sanitized_params
  end

  def campaign
    campaign_id = params.permit(:campaign_id).dig(:campaign_id).to_i

    return if campaign_id.positive? && (@campaign = Campaign.find_by(id: campaign_id))

    sweetalert_error('Campaign NOT found!', 'We were not able to access the Campaign you requested.', '', { persistent: 'OK' })

    respond_to do |format|
      format.js { render js: "window.location = '#{root_path}'" and return false }
      format.html { redirect_to root_path and return false }
    end
  end

  def trigger
    trigger_id = params.permit(:id).dig(:id).to_i

    return if trigger_id.positive? && (@trigger = @campaign.triggers.find_by(id: trigger_id))

    sweetalert_error('Trigger NOT found!', 'We were not able to access the Trigger you requested.', '', { persistent: 'OK' })

    respond_to do |format|
      format.js { render js: "window.location = '#{root_path}'" and return false }
      format.html { redirect_to root_path and return false }
    end
  end
end
