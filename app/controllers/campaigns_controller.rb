# frozen_string_literal: true

# app/controllers/campaigns_controller.rb
class CampaignsController < ApplicationController
  class CampaignsControllerError < StandardError; end

  before_action :authenticate_user!
  before_action :authorize_user!, except: %i[apply_campaign index_contact_campaign_actions stop_campaign]
  before_action :set_contact, only: %i[apply_campaign]
  before_action :set_campaign, only: %i[destroy edit show update]

  # (POST)
  # /campaigns/apply/:contact_id
  # apply_campaign_path(:contact_id)
  # apply_campaign_url(:contact_id)
  def apply_campaign
    sanitized_params = params.permit(:campaign_id, :run_at)

    if sanitized_params.dig(:campaign_id).to_i.positive?
      Contacts::Campaigns::StartJob.set(wait_until: Time.use_zone(current_user.client.time_zone) { Chronic.parse(sanitized_params.dig(:run_at).presence || Time.current.to_s) }).perform_later(
        campaign_id: sanitized_params[:campaign_id],
        client_id:   current_user.client_id,
        contact_id:  @contact.id,
        user_id:     current_user.id
      )
    end

    render partial: 'campaigns/js/show', locals: { cards: %w[index_contact_campaigns] }
  end

  # (POST) create a new Campaign
  # /campaigns
  # campaigns_path
  # campaigns_url
  def create
    @campaign          = current_user.client.campaigns.new(campaign_params)
    @campaign.analyzed = @campaign.analyze!.empty?
    @campaign.save

    render partial: 'campaigns/js/show', locals: { cards: %w[campaign campaign_general_settings show_campaign_general_settings select_campaign_dropdown] }
  end

  # (DELETE) destroy a Campaign
  # /campaigns/:id?confirm=String
  # campaign_path(:id, confirm: String)
  # campaign_url(:id, confirm: String)
  def destroy
    Campaigns::DestroyJob.perform_later(campaign_id: @campaign.id, client_id: @campaign.client_id)

    render partial: 'campaigns/js/show', locals: { cards: %w[index select_campaign_dropdown] }
  end

  # (GET)
  # /campaigns/:id/edit
  # edit_campaign_path(:id)
  # edit_campaign_url(:id)
  def edit
    render partial: 'campaigns/js/show', locals: { cards: %w[campaign_general_settings] }
  end

  # (POST) import a shared Campaign
  # /campaigns/import
  # import_campaign_path
  # import_campaign_url
  def import
    referrer      = Rails.application.routes.recognize_path(request.referer)
    redirect_path = referrer[:controller] == 'campaigns' ? campaigns_path : show_campaign_packages_path

    if params.include?(:share_code) && params[:share_code].to_s.present?

      campaign_share_code = CampaignShareCode.find_by(share_code: params[:share_code].to_s)

      if campaign_share_code

        if campaign_share_code.campaign
          new_campaign = campaign_share_code.campaign.copy(new_client_id: current_user.client.id)

          if new_campaign
            sweetalert_success('Campaign Import Success!', "Hurray! '#{new_campaign.name}' was imported successfully.", '', { persistent: 'OK' })

          else
            sweetalert_warning('Something went wrong!', '', 'Sorry, we couldn\'t import that Campaign.', { persistent: 'OK' })

            error = CampaignsControllerError.new("Campaign Import Error: Campaign #{campaign_share_code.campaign.id}")
            error.set_backtrace(BC.new.clean(caller))

            Appsignal.report_error(error) do |transaction|
              # Only needed if it needs to be different or there's no active transaction from which to inherit it
              Appsignal.set_action('CampaignsController#import')

              # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
              Appsignal.add_params(params)

              Appsignal.set_tags(
                error_level: 'error',
                error_code:  0
              )
              Appsignal.add_custom_data(
                campaign_share_code: campaign_share_code.inspect,
                campaign:            campaign_share_code.campaign.inspect,
                new_campaign:        new_campaign.inspect,
                user:                {
                  id:   current_user.id,
                  name: current_user.fullname
                },
                file:                __FILE__,
                line:                __LINE__
              )
            end
          end
        elsif campaign_share_code.campaign_group
          new_campaign_group = campaign_share_code.campaign_group.copy(new_client_id: current_user.client.id)

          if new_campaign_group
            sweetalert_success('Campaign Package Import Success!', "Hurray! '#{new_campaign_group.name}' was imported successfully.", '', { persistent: 'OK' })

          else
            sweetalert_warning('Something went wrong!', '', 'Sorry, we couldn\'t import that Campaign Package.', { persistent: 'OK' })

          end
        else
          sweetalert_warning('Campaign or Package Not Found!', 'Sorry, we couldn\'t find that share code. Please verify the code and try again.', '', { persistent: 'OK' })

        end
      else
        sweetalert_warning('Share Code Not Found!', 'Sorry, we couldn\'t find that share code. Please verify the code and try again.', '', { persistent: 'OK' })

      end
    else
      sweetalert_warning('Share Code Not Entered!', 'Sorry, a share code was NOT entered. Please enter the code and try again.', '', { persistent: 'OK' })
    end

    render js: "window.location = '#{redirect_path}'" and return

    @campaign  = current_user.client.campaigns.new
    @campaigns = campaigns

    render partial: 'campaigns/js/show', locals: { cards: (referrer[:controller] == 'campaigns' ? %w[select_campaign_dropdown] : [3, 4, 11]) }
  end

  # (GET) list Campaigns
  # /campaigns
  # campaigns_path
  # campaigns_url
  def index
    respond_to do |format|
      format.js { render js: "window.location = '#{root_path}'" }
      format.html { render 'campaigns/index' }
    end
  end

  # (GET)
  # /campaigns/contact/:contact_campaign_id
  # index_contact_campaign_actions_path(:contact_campaign_id)
  # index_contact_campaign_actions_url(:contact_campaign_id)
  def index_contact_campaign_actions
    @contact_campaign = Contacts::Campaign.find_by(id: params.dig(:contact_campaign_id).to_i)

    render partial: 'campaigns/js/show', locals: { cards: %w[index_contact_campaign] }
  end

  # (GET)
  # /campaigns/import/index
  # index_import_campaign_path
  # index_import_campaign_url
  def index_import
    render js: "window.location = '#{root_path}'" and return false unless current_user.client.campaigns.length < current_user.client.campaigns_count && current_user.client.share_funnels_allowed

    render partial: 'campaigns/js/show', locals: { cards: %w[import] }
  end

  # (GET)
  # /campaigns/new
  # new_campaign_path
  # new_campaign_url
  def new
    @campaign = current_user.client.campaigns.new(name: 'New Campaign')

    render partial: 'campaigns/js/show', locals: { cards: %w[campaign] }
  end

  # (GET) show a Campaign
  # /campaigns/:id
  # campaign_path(:id)
  # campaign_url(:id)
  def show
    render partial: 'campaigns/js/show', locals: { cards: %w[campaign] }
  end

  # (DELETE)
  # /campaigns/stop/:contact_campaign_id
  # stop_campaign_path(:contact_campaign_id)
  # stop_campaign_url(:contact_campaign_id)
  def stop_campaign
    sanitized_params = params.permit(:contact_campaign_id, :contact_id)

    if sanitized_params.dig(:contact_campaign_id).present? && sanitized_params.dig(:contact_id).present? && (@contact = Contact.find_by(id: sanitized_params[:contact_id]))

      if sanitized_params[:contact_campaign_id][...2] == 'dj' && (delayed_job = @contact.delayed_jobs.find_by(id: sanitized_params[:contact_campaign_id].sub('dj', '').to_i))
        delayed_job.destroy
      elsif (contact_campaign = Contacts::Campaign.find_by(id: sanitized_params[:contact_campaign_id].to_i))
        Contacts::Campaigns::StopJob.perform_now(
          campaign_id:         'this',
          contact_campaign_id: contact_campaign.id,
          contact_id:          contact_campaign.contact_id
        )
      end
    end

    render partial: 'campaigns/js/show', locals: { cards: %w[index_contact_campaigns] }
  end

  # (PUT/PATCH) update a Campaign
  # /campaigns/:id
  # campaign_path(:id)
  # campaign_url(:id)
  def update
    sanitized_params = params.permit(:confirm, :lock_phone, :return_to, :stop_all)

    if sanitized_params.dig(:lock_phone)
      @campaign.update(lock_phone: sanitized_params.dig(:lock_phone).to_bool)
      cards = %w[campaign_general_settings]

      if @campaign.lock_phone
        Triggeraction.for_campaign(@campaign.id).where(action_type: [100, 150, 750]).find_each do |triggeraction|
          if triggeraction.action_type == 100
            triggeraction.update(from_phone: [@campaign.default_phone])
          else
            triggeraction.update(from_phone: @campaign.default_phone)
          end
        end
      end
    elsif sanitized_params.dig(:confirm).to_s == 'activate'
      @campaign.update(active: true)
      cards = [(sanitized_params.dig(:return_to) || 'campaign_general_settings_active').to_s].flatten
    elsif sanitized_params.dig(:confirm).to_s == 'deactivate'
      @campaign.update(active: false)

      if sanitized_params.dig(:stop_all).to_bool

        Contacts::Campaign.joins(:delayed_jobs).where(campaign_id: @campaign.id).includes(:contact).group(:id, :campaign_id).find_each do |contact_campaign|
          Contacts::Campaigns::StopJob.perform_later(
            campaign_id:            @campaign.id,
            contact_campaign_id:    contact_campaign.id,
            contact_id:             contact_campaign.contact_id,
            keep_triggeraction_ids: 0,
            multi_stop:             'all',
            user_id:                contact_campaign.contact.user_id
          )
        end
      end

      cards = [(sanitized_params.dig(:return_to) || 'campaign_general_settings_active').to_s].flatten
    else
      # remember current default_phone
      previous_default_phone = @campaign.default_phone
      cards = %w[campaign_general_name campaign_general_settings hide_campaign_general_settings triggers_list select_campaign_dropdown]

      @campaign.update(campaign_params)

      unless @campaign.triggers.any?
        @trigger = @campaign.triggers.create(trigger_type: 115)
        @campaign.update(analyzed: @campaign.analyze!.empty?)
        cards += %w[show_trigger_form show_new_campaign_trigger_button]
      end

      # update all Triggeractions using default_phone
      unless @campaign.default_phone == previous_default_phone

        Triggeraction.for_campaign(@campaign.id).where(action_type: [100, 150, 750]).find_each do |triggeraction|
          if triggeraction.action_type == 100

            if triggeraction.from_phone.include?(previous_default_phone)
              triggeraction.from_phone.delete(previous_default_phone)
              triggeraction.update(from_phone: triggeraction.from_phone << @campaign.default_phone)
            end
          elsif triggeraction.from_phone == previous_default_phone
            triggeraction.update(from_phone: @campaign.default_phone)
          end
        end
      end
    end

    render partial: 'campaigns/js/show', locals: { cards: }
  end

  private

  def authorize_user!
    super
    return if current_user.access_controller?('campaigns', 'allowed', session)

    raise ExceptionHandlers::UserNotAuthorized.new('Campaign Builder', root_path)
  end

  def campaign_params
    sanitized_params = params.require(:campaign).permit(:allow_repeat, :allow_repeat_interval, :allow_repeat_period, :campaign_group_id, :default_phone, :name)

    sanitized_params[:allow_repeat]          = sanitized_params.dig(:allow_repeat).to_bool
    sanitized_params[:allow_repeat_interval] = sanitized_params.dig(:allow_repeat_period) == 'immediately' ? 0 : sanitized_params.dig(:allow_repeat_interval).to_i
    sanitized_params[:campaign_group_id]     = sanitized_params.dig(:campaign_group_id).to_i.to_s

    sanitized_params
  end

  def set_campaign
    campaign_id = params.permit(:id).dig(:id).to_i

    return if campaign_id.positive? && (@campaign = Campaign.find_by(id: campaign_id))

    sweetalert_error('Unknown Campaign!', 'Campaign cound NOT be found.', '', { persistent: 'OK' })

    respond_to do |format|
      format.js   { render js: "window.location = '#{root_path}'" and return false }
      format.json { render json: [] and return false }
      format.html { redirect_to root_path and return false }
    end
  end

  def set_contact
    contact_id = params.permit(:contact_id).dig(:contact_id).to_i

    return if contact_id.positive? && current_user && (@contact = current_user.client.contacts.find_by(id: contact_id))

    respond_to do |format|
      format.js { render js: "window.location = '#{root_path}'" and return false }
      format.html { redirect_to root_path and return false }
    end
  end
end
