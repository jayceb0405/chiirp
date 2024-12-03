# frozen_string_literal: true

# app/controllers/aiagents_controller.rb
class AiagentsController < ApplicationController
  class AiagentsControllerError < StandardError; end

  before_action :authenticate_user!
  before_action :authorize_user!
  before_action :find_aiagent, only: %i[edit update destroy]
  before_action :find_aiagents, only: %i[new update destroy]
  before_action :find_service_titan_info, only: %i[new edit create update]
  before_action :load_service_titan_fields, only: %i[update]

  # (POST)
  # /aiagents/apply/:contact_id
  # aiagents_apply_path(:contact_id)
  # aiagents_apply_url(:contact_id)
  def apply_contact
    sanitized_params = params.permit(:aiagent_id, :run_at, :contact_id)
    @contact = current_user.contacts.find(sanitized_params[:contact_id])

    if sanitized_params.dig(:aiagent_id).to_i.positive?
      @aiagent = current_user.client.aiagents.find(sanitized_params[:aiagent_id])
      data = {
        aiagent_id: @aiagent.id
      }
      @contact.delay(
        run_at:              Time.use_zone(current_user.client.time_zone) { Chronic.parse(sanitized_params.dig(:run_at).presence || Time.current.to_s) },
        priority:            DelayedJob.job_priority('aiagent_start_session'),
        queue:               DelayedJob.job_queue('aiagent_start_session'),
        user_id:             current_user.id,
        contact_id:          @contact.id,
        triggeraction_id:    0,
        contact_campaign_id: 0,
        group_process:       0,
        process:             'aiagent_start_session',
        data:
      ).aiagent_stop_all_and_start_session(data)
    end

    render partial: 'aiagents/js/show', locals: { cards: %w[index_aiagent_sessions] }
  end

  # (GET) show AI Agents
  # /aiagents
  # aiagents_path
  # aiagents_url
  def show
    cards = params[:cards] || []
    @aiagent  = current_user.client.aiagents.new
    @aiagents = current_user.client.aiagents.order(:name)

    respond_to do |format|
      format.js { render partial: 'aiagents/js/show', locals: { cards: } }
      format.html { render 'aiagents/show' }
    end
  end

  # (PUT) accept AI Agents terms
  # /aiagents
  # aiagents_terms_path
  # aiagents_terms_url
  def terms
    current_user.client.transaction do
      current_user.client.update aiagent_terms_accepted_at: Time.current
      current_user.client.aiagent_free_trial_start! unless current_user.client.aiagent_trial_started_at
    end

    @aiagent  = current_user.client.aiagents.new
    @aiagents = current_user.client.aiagents.order(:name)

    respond_to do |format|
      format.js { render partial: 'aiagents/js/show', locals: { cards: %w[index toolbar] } }
    end
  end

  # (GET) AI Agent agent screen
  # /aiagents/:id/edit
  # new_aiagent_path
  # new_aiagent_url
  def new
    # ensure client has enough aiagent slots available
    cards = if current_user.client.aiagent_free_remaining?
              params[:cards] || %w[edit]
            else
              # need to purchase more aiagent slots
              %w[purchase]
            end

    @aiagent = current_user.client.aiagents.new(aiagent_default_attributes)

    respond_to do |format|
      format.js { render partial: 'aiagents/js/show', locals: { cards: } }
      format.html { redirect_to aiagents_path }
    end
  end

  # (POST) AI Agent agent screen
  # /aiagents/new/purchase
  # aiagents_purchase_path
  # aiagents_purchase_url
  def purchase
    cards = if params[:accept] == 'true'
              # charge card
              res = current_user.client.charge_card(
                charge_amount: current_user.client.aiagent_overage_prorated_charge,
                setting_key:   'aiagent_overage_charge'
              )

              if res[:success]
                # increase client aiagent_overage_paid_count
                current_user.client.with_lock do
                  current_user.client.aiagent_overage_paid_count = (current_user.client.aiagent_overage_paid_count || 0).to_i + 1
                  current_user.client.save
                end

                @aiagent  = current_user.client.aiagents.new(aiagent_default_attributes)
                @aiagents = current_user.client.aiagents.order(:name)

                sweetalert_success('Extra AI Agent Was Added', 'You card has been charged and a new AI Agent slot was added successfully.', '', { persistent: 'OK' })

                %w[edit close_modal]
              else
                sweetalert_warning('We could not process payment', 'Sorry, we couldn\'t process the payment. Please contact support for help.', '', { persistent: 'OK' })

                @aiagent  = current_user.client.aiagents.new
                @aiagents = current_user.client.aiagents.order(:name)

                %w[index close_modal]
              end
            else
              sweetalert_warning('Must accept overage charge to create new AI Agent!', 'Sorry, we couldn\'t create a new AI Agent without accepting the overage charge.', '', { persistent: 'OK' })

              %w[index close_modal]
            end

    respond_to do |format|
      format.js { render partial: 'aiagents/js/show', locals: { cards: } }
      format.html { redirect_to aiagents_path }
    end
  end

  # (POST) create a new ai agent
  # /aiagents
  # aiagents_path
  # aiagents_url
  def create
    @aiagent = current_user.client.aiagents.build(aiagent_params)
    load_service_titan_fields
    @aiagent.save

    @aiagents = current_user.client.aiagents.order(:name)

    respond_to do |format|
      format.js { render partial: 'aiagents/js/show', locals: { cards: %w[edit dropdown] } }
      format.html { redirect_to aiagents_path }
    end
  end

  # (GET) AI Agent agent screen
  # /aiagents/:id/edit
  # edit_aiagent_path
  # edit_aiagent_url
  def edit
    respond_to do |format|
      cards = params[:cards] || %w[edit]
      format.js { render partial: 'aiagents/js/show', locals: { cards: } }
      format.html { redirect_to aiagents_path }
    end
  end

  # (PUT/PATCH) AI Agent agent screen
  # /aiagents/:id
  # aiagent_path
  # aiagent_url
  def update
    @aiagent.update(aiagent_params)
    @aiagents = current_user.client.aiagents.order(:name)

    respond_to do |format|
      format.js { render partial: 'aiagents/js/show', locals: { cards: %w[edit dropdown] } }
      format.html { redirect_to aiagent_path }
    end
  end

  # (DELETE) AI Agent agent screen
  # /aiagents/:id
  # aiagent_path
  # aiagent_url
  def destroy
    @aiagent.destroy
    @aiagents = current_user.client.aiagents.order(:name)

    respond_to do |format|
      format.js { render partial: 'aiagents/js/show', locals: { cards: %w[index dropdown] } }
      format.html { redirect_to aiagents_path }
    end
  end

  # (PUT/PATCH) import an Aiagent
  # /aiagents/import
  # aiagents_import_path
  # aiagents_import_url
  def import
    if params.permit(:share_code).dig(:share_code).present?
      if (aiagent = Aiagent.find_by(share_code: params.permit(:share_code).dig(:share_code)))
        @aiagent = aiagent.copy(new_client_id: current_user.client.id)

        if @aiagent
          sweetalert_success('AI Agent Import Success!', "Hurray! '#{@aiagent.name}' was imported successfully.", '', { persistent: 'OK' })
        else
          sweetalert_warning('Something went wrong!', '', "Sorry, we couldn't import that AI Agent.", { persistent: 'OK' })

          error = AiagentsControllerError.new("AI Agent Import Error: AI Agent #{aiagent.id}")
          error.set_backtrace(BC.new.clean(caller))

          Appsignal.report_error(error) do |transaction|
            # Only needed if it needs to be different or there's no active transaction from which to inherit it
            Appsignal.set_action('AiagentsController#import')

            # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
            Appsignal.add_params(params)

            Appsignal.set_tags(
              error_level: 'error',
              error_code:  0
            )
            Appsignal.add_custom_data(
              aiagent:,
              new_aiagent:   @aiagent,
              client_id:     aiagent.client_id,
              new_client_id: current_user.client.id,
              user:          {
                id:   current_user.id,
                name: current_user.fullname
              },
              file:          __FILE__,
              line:          __LINE__
            )
          end
        end
      else
        sweetalert_warning('AI Agent Not Found!', 'Sorry, we couldn\'t find that share code. Please verify the code and try again.', '', { persistent: 'OK' })
      end
    else
      sweetalert_warning('Share Code Not Entered!', 'Sorry, a share code was NOT entered. Please enter the code and try again.', '', { persistent: 'OK' })
    end

    @aiagents = current_user.client.aiagents.order(:name)
    render partial: 'aiagents/js/show', locals: { cards: %w[index] }
  end

  private

  def aiagent_default_attributes
    {
      name:          'New AI Agent',
      max_messages:  20,
      lookback_days: 3
    }
  end

  def aiagent_params
    sanitized_params = params.require(:agent).permit(:name, :show_ai, :aiagent_type, :lookback_days, :session_length, :session_length_campaign_id, :session_length_group_id, :session_length_tag_id, :session_length_stage_id, :system_prompt, :initial_prompt, :ending_prompt, :action, :max_messages, :max_messages_prompt, :campaign_id, :stage_id, :tag_id, :group_id, :help_campaign_id, :help_stage_id, :help_tag_id, :help_group_id, custom_fields: {}, stop_campaign_ids: [], help_stop_campaign_ids: [], session_length_stop_campaign_ids: [])

    sanitized_params[:aiagent_type] = sanitized_params.dig(:aiagent_type).strip
    sanitized_params[:ending_prompt] = sanitized_params.dig(:ending_prompt)&.strip&.presence
    sanitized_params[:initial_prompt] = sanitized_params.dig(:initial_prompt)&.strip
    sanitized_params[:initial_prompt] = sanitized_params[:action] == 'quick_response' ? '' : sanitized_params[:initial_prompt]
    sanitized_params[:lookback_days] = sanitized_params.dig(:lookback_days).to_i
    sanitized_params[:max_messages_prompt] = sanitized_params.dig(:max_messages_prompt).strip
    sanitized_params[:name] = sanitized_params.dig(:name).strip
    sanitized_params[:system_prompt] = sanitized_params.dig(:system_prompt).strip

    # handle stop campaigns
    sanitized_params[:stop_campaign_ids] = sanitized_params.dig(:stop_campaign_ids)&.compact_blank
    sanitized_params[:stop_campaign_ids] = [0] if sanitized_params[:stop_campaign_ids].include?('0')
    sanitized_params[:help_stop_campaign_ids] = sanitized_params.dig(:help_stop_campaign_ids)&.compact_blank
    sanitized_params[:help_stop_campaign_ids] = [0] if sanitized_params[:help_stop_campaign_ids].include?('0')
    sanitized_params[:session_length_stop_campaign_ids] = sanitized_params.dig(:session_length_stop_campaign_ids)&.compact_blank
    sanitized_params[:session_length_stop_campaign_ids] = [0] if sanitized_params[:session_length_stop_campaign_ids].include?('0')

    allowed_names = ::Webhook.internal_key_hash(current_user.client, 'contact', %w[personal phones custom_fields])
    sanitized_params[:custom_fields]&.each do |name, _|
      unless allowed_names.include?(name)
        sanitized_params[:custom_fields].delete(name)
        next
      end

      sanitized_params[:custom_fields][name].keep_if { |data_name, _| %w[show required order].include?(data_name) }
    end

    sanitized_params
  end

  def authorize_user!
    super
    return if current_user&.access_controller?('aiagents', 'allowed', session)

    raise ExceptionHandlers::UserNotAuthorized.new('AI Agents', root_path)
  end

  def find_aiagent
    @aiagent = current_user.client.aiagents.find(params[:id])
  end

  def find_aiagents
    @aiagents = current_user.client.aiagents
  end

  def find_service_titan_info
    @client_api_integration = current_user.client.client_api_integrations.find_by(target: 'servicetitan', name: '')
    @contact = current_user.client.contacts.first
  end

  def load_service_titan_fields
    @aiagent.business_unit_id = params[:business_unit_id]
    @aiagent.job_type_id = params[:job_type_id]
    @aiagent.st_campaign_id = params[:st_campaign_id]
    @aiagent.description = params[:description]
    @aiagent.technician_ids = params[:ext_tech_id].is_a?(Array) ? params[:ext_tech_id].compact_blank : []
    @aiagent.tag_type_names = params[:tag_type_names].is_a?(Array) ? params[:tag_type_names].compact_blank : []
    @aiagent.client_custom_fields = params[:client_custom_fields].presence || {}
  end
end
