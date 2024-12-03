# frozen_string_literal: true

# app/controllers/trackable_links_controller.rb
class TrackableLinksController < ApplicationController
  before_action :authenticate_user!, except: %i[redirect]
  before_action :authorize_user!, except: %i[redirect]
  before_action :set_trackable_link, only: %i[destroy edit update]

  # (POST) create a new TrackableLink
  # /trackable_links
  # trackable_links_path
  # trackable_links_url
  def create
    @trackable_link  = current_user.client.trackable_links.create(trackable_link_params)
    @trackable_links = current_user.client.trackable_links.order(:name)

    respond_to do |format|
      format.js { render partial: 'trackable_links/js/show', locals: { cards: %w[edit dropdown] } }
      format.html { redirect_to trackablelinks_path }
    end
  end

  # (DELETE) destroy a TrackableLink
  # /trackable_links/:id
  # trackable_link_path(:id)
  # trackable_link_url(:id)
  def destroy
    @trackable_link.destroy
    @trackable_link  = current_user.client.trackable_links.new
    @trackable_links = current_user.client.trackable_links.order(:name)

    respond_to do |format|
      format.js { render partial: 'trackable_links/js/show', locals: { cards: %w[index dropdown] } }
      format.html { redirect_to trackablelinks_path }
    end
  end

  def edit
    # (GET) show edit screen for TrackableLink
    # /trackable_links/:id/edit
    # edit_trackable_link_path(:id)
    # edit_trackable_link_url(:id)
    respond_to do |format|
      format.js { render partial: 'trackable_links/js/show', locals: { cards: %w[edit] } }
      format.html { redirect_to trackablelinks_path }
    end
  end

  # (GET) set up for a new TrackableLink
  # /trackable_links/new
  # new_trackable_link_path
  # new_trackable_link_url
  def new
    @trackable_link = current_user.client.trackable_links.new(name: 'New Trackable Link')

    respond_to do |format|
      format.js { render partial: 'trackable_links/js/show', locals: { cards: %w[edit] } }
      format.html { redirect_to trackablelinks_path }
    end
  end

  # (GET) receive a TrackableShortLink and process
  # /tl/:short_code
  # trackable_links_redirect_path(:short_code)
  # trackable_links_redirect_url(:short_code)
  # http://domain.com/tl/xxxxxx (xxxxxx = short_code)
  def redirect
    if (trackable_short_link = TrackableShortLink.find_by(short_code: params.dig(:short_code).to_s))

      unless browser.bot?
        # create TrackableLinksHit
        trackable_short_link.trackable_links_hits.create(referer: request.referer, remote_ip: request.remote_ip)

        if trackable_short_link.contact.present?
          data = {
            campaign_id:       trackable_short_link.trackable_link.campaign_id,
            group_id:          trackable_short_link.trackable_link.group_id,
            stage_id:          trackable_short_link.trackable_link.stage_id,
            tag_id:            trackable_short_link.trackable_link.tag_id,
            stop_campaign_ids: trackable_short_link.trackable_link.stop_campaign_ids
          }
          trackable_short_link.contact.delay(
            priority:            DelayedJob.job_priority('trackable_link'),
            queue:               DelayedJob.job_queue('trackable_link'),
            contact_id:          trackable_short_link.contact.id,
            triggeraction_id:    0,
            contact_campaign_id: 0,
            group_process:       0,
            process:             'trackable_link',
            data:
          ).process_actions(data)
        end
      end

      if trackable_short_link.trackable_link.original_url.blank?
        # original url was not entered by User
        # create alert and redirect to failed link page
        flash[:alert] = request.original_url
        redirect_to welcome_failed_link_url
      else
        # redirect to TrackableLink
        redirect_to "#{trackable_short_link.trackable_link.original_url.include?('http') ? '' : 'http://'}#{trackable_short_link.contact.message_tag_replace(trackable_short_link.trackable_link.original_url)}", allow_other_host: true
      end
    else
      # TrackableShortLink was NOT found
      # create alert and redirect to failed link page
      flash[:alert] = request.original_url
      redirect_to welcome_failed_link_url
    end
  end

  # (GET) show Trackable Links
  # /trackablelinks
  # trackablelinks_path
  # trackablelinks_url
  def show
    @trackable_link  = current_user.client.trackable_links.new
    @trackable_links = current_user.client.trackable_links.order(:name)

    respond_to do |format|
      format.js { render js: "window.location = '#{root_path}'" }
      format.html { render 'trackable_links/show' }
    end
  end

  # (PUT/PATCH) update a TrackableLink
  # /trackable_links/:id
  # trackable_link_path(:id)
  # trackable_link_url(:id)
  def update
    @trackable_link.update(trackable_link_params)
    @trackable_links = current_user.client.trackable_links.order(:name)

    respond_to do |format|
      format.js { render partial: 'trackable_links/js/show', locals: { cards: %w[edit dropdown] } }
      format.html { redirect_to trackablelinks_path }
    end
  end

  private

  def authorize_user!
    super
    return if current_user.access_controller?('trackable_links', 'allowed', session)

    raise ExceptionHandlers::UserNotAuthorized.new('Trackable Links', root_path)
  end

  def set_trackable_link
    if params.dig(:id).to_i.zero?
      @trackable_link = current_user.client.trackable_links.new
    else
      @trackable_link = current_user.client.trackable_links.find_by(id: params[:id])

      unless @trackable_link
        sweetalert_error('Trackable Link NOT found!', 'We were not able to access the Trackable Link you requested.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{trackablelinks_path}'" and return false }
          format.html { redirect_to trackablelinks_path and return false }
        end
      end
    end
  end

  def trackable_link_params
    response = params.require(:trackable_link).permit(:name, :original_url, :campaign_id, :tag_id, :group_id, :stage_id, stop_campaign_ids: [])

    response[:campaign_id]       = response[:campaign_id].to_i if response.include?(:campaign_id)
    response[:tag_id]            = response[:tag_id].to_i if response.include?(:tag_id)
    response[:group_id]          = response[:group_id].to_i if response.include?(:group_id)
    response[:stage_id]          = response[:stage_id].to_i if response.include?(:stage_id)
    response[:stop_campaign_ids] = response[:stop_campaign_ids].compact_blank if response.include?(:stop_campaign_ids)
    response[:stop_campaign_ids] = [0] if response[:stop_campaign_ids]&.include?('0')

    response
  end
end
