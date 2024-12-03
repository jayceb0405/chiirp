# frozen_string_literal: true

# app/controllers/clients/features_controller.rb
module Clients
  # support for editing Client features
  class FeaturesController < Clients::ClientController
    before_action :authenticate_user!
    before_action :client
    before_action :authorize_user!

    # (GET)
    # /clients/features/:id/edit
    # edit_clients_feature_path(:id)
    # edit_clients_feature_url(:id)
    def edit
      respond_to do |format|
        format.js { render partial: 'clients/js/show', locals: { cards: %w[features] } }
        format.html { render 'clients/show', locals: { client_page_section: 'features' } }
      end
    end

    # (PUT/PATCH)
    # /clients/features/:id
    # clients_feature_path(:id)
    # clients_feature_url(:id)
    def update
      @client.update(client_params)

      respond_to do |format|
        format.js { render partial: 'clients/js/show', locals: { cards: %w[features] } }
        format.html { redirect_to edit_clients_feature_path(@client) }
      end
    end

    private

    def authorize_user!
      super

      return if current_user.access_controller?('clients', 'features', session)

      raise ExceptionHandlers::UserNotAuthorized.new('My Company Profile > Profile', root_path)
    end

    def client_params
      response = params.require(:client).permit(
        :aiagent_base_charge,
        :aiagent_included_count,
        :aiagent_overage_charge,
        :aiagent_message_credits,
        # :aiagent_trial_started_at,
        # :aiagent_trial_ended_at,
        # :aiagent_terms_accepted_at,
        :campaigns_count,
        :custom_fields_count,
        :dlc10_required,
        :folders_count,
        :groups_count,
        :import_contacts_count,
        :max_contacts_count,
        :max_email_templates,
        :max_kpis_count,
        :max_users_count,
        :max_voice_recordings,
        :message_central_allowed,
        :my_contacts_allowed,
        :my_contacts_group_actions_all_allowed,
        :phone_call_credits,
        :phone_calls_allowed,
        :quick_leads_count,
        :rvm_allowed,
        :rvm_credits,
        :share_aiagents_allowed,
        :share_email_templates_allowed,
        :share_funnels_allowed,
        :share_quick_leads_allowed,
        :share_surveys_allowed,
        :share_widgets_allowed,
        :share_stages_allowed,
        :stages_count,
        :surveys_count,
        :text_image_credits,
        :text_message_credits,
        :text_message_images_allowed,
        :text_segment_charge_type,
        :trackable_links_count,
        :user_chat_allowed,
        :video_call_credits,
        :video_calls_allowed,
        :widgets_count,
        :tasks_allowed,
        integrations_allowed: [],
        training:             []
      )

      response[:aiagent_base_charge]         = response[:aiagent_base_charge].to_f if response.include?(:aiagent_base_charge)
      response[:aiagent_included_count]      = response[:aiagent_included_count].to_i if response.include?(:aiagent_included_count)
      response[:aiagent_message_credits]     = response[:aiagent_message_credits].to_f if response.include?(:aiagent_message_credits)
      response[:aiagent_overage_charge]      = response[:aiagent_overage_charge].to_f if response.include?(:aiagent_overage_charge)
      # response[:aiagent_trial_started_at]     = Chronic.parse([:aiagent_trial_started_at]) if response.include?(:aiagent_trial_started_at)
      # response[:aiagent_trial_ended_at]       = Chronic.parse([:aiagent_trial_ended_at]) if response.include?(:aiagent_trial_ended_at)
      # response[:aiagent_terms_accepted_at]   = Chronic.parse([:aiagent_terms_accepted_at]) if response.include?(:aiagent_terms_accepted_at)
      response[:campaigns_count]             = response[:campaigns_count].to_i if response.include?(:campaigns_count)
      response[:custom_fields_count]         = response[:custom_fields_count].to_i if response.include?(:custom_fields_count)
      response[:dlc10_required] = response[:dlc10_required].to_bool if response.include?(:dlc10_required)
      response[:folders_count]               = response[:folders_count].to_i if response.include?(:folders_count)
      response[:groups_count]                = response[:groups_count].to_i if response.include?(:groups_count)
      response[:import_contacts_count]       = response[:import_contacts_count].to_i if response.include?(:import_contacts_count)
      response[:integrations_allowed]        = response[:integrations_allowed].reject(&:empty?) if response.include?(:integrations_allowed)
      response[:max_contacts_count]          = response[:max_contacts_count].to_i if response.include?(:max_contacts_count)
      response[:max_email_templates]         = response[:max_email_templates].to_i if response.include?(:max_email_templates)
      response[:max_kpis_count]              = response[:max_kpis_count].to_i if response.include?(:max_kpis_count)
      response[:max_users_count]             = response[:max_users_count].to_i if response.include?(:max_users_count)
      response[:max_voice_recordings]        = response[:max_voice_recordings].to_i if response.include?(:max_voice_recordings)
      response[:message_central_allowed]     = response[:message_central_allowed].to_bool if response.include?(:message_central_allowed)
      response[:my_contacts_allowed]         = response[:my_contacts_allowed].to_bool if response.include?(:my_contacts_allowed)
      response[:my_contacts_group_actions_all_allowed] = response[:my_contacts_group_actions_all_allowed].to_bool if response.include?(:my_contacts_group_actions_all_allowed)
      response[:phone_call_credits]          = response[:phone_call_credits].to_d if response.include?(:phone_call_credits)
      response[:phone_calls_allowed]         = response[:phone_calls_allowed].to_bool if response.include?(:phone_calls_allowed)
      response[:quick_leads_count]           = response[:quick_leads_count].to_i if response.include?(:quick_leads_count)
      response[:rvm_allowed]                 = response[:rvm_allowed].to_bool if response.include?(:rvm_allowed)
      response[:rvm_credits]                 = response[:rvm_credits].to_d if response.include?(:rvm_credits)
      response[:share_aiagents_allowed]      = response[:share_aiagents_allowed].to_bool if response.include?(:share_aiagents_allowed)
      response[:share_email_templates_allowed] = response[:share_email_templates_allowed].to_bool if response.include?(:share_email_templates_allowed)
      response[:share_funnels_allowed]       = response[:share_funnels_allowed].to_bool if response.include?(:share_funnels_allowed)
      response[:share_quick_leads_allowed]   = response[:share_quick_leads_allowed].to_bool if response.include?(:share_quick_leads_allowed)
      response[:share_surveys_allowed]       = response[:share_surveys_allowed].to_s if response.include?(:share_surveys_allowed)
      response[:share_widgets_allowed]       = response[:share_widgets_allowed].to_bool if response.include?(:share_widgets_allowed)
      response[:share_stages_allowed]        = response[:share_stages_allowed].to_bool if response.include?(:share_stages_allowed)
      response[:stages_count]                = response[:stages_count].to_i if response.include?(:stages_count)
      response[:surveys_count]               = response[:surveys_count].to_i if response.include?(:surveys_count)
      response[:tasks_allowed]               = response[:tasks_allowed].to_bool if response.include?(:tasks_allowed)
      response[:text_image_credits]          = response[:text_image_credits].to_d if response.include?(:text_image_credits)
      response[:text_message_credits]        = response[:text_message_credits].to_d if response.include?(:text_message_credits)
      response[:text_message_images_allowed] = response[:text_message_images_allowed].to_bool if response.include?(:text_message_images_allowed)
      response[:text_segment_charge_type]    = response[:text_segment_charge_type].to_i if response.include?(:text_segment_charge_type)
      response[:trackable_links_count]       = response[:trackable_links_count].to_i if response.include?(:trackable_links_count)
      response[:training]                    = response[:training].reject(&:empty?) if response.include?(:training)
      response[:video_call_credits]          = response[:video_call_credits].to_d if response.include?(:video_call_credits)
      response[:video_calls_allowed]         = response[:video_calls_allowed].to_bool if response.include?(:video_calls_allowed)
      response[:user_chat_allowed]           = response[:user_chat_allowed].to_bool if response.include?(:user_chat_allowed)
      response[:widgets_count]               = response[:widgets_count].to_i if response.include?(:widgets_count)

      response
    end
  end
end
