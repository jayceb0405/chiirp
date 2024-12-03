# frozen_string_literal: true

# app/controllers/integrations/servicetitan/imports_controller.rb
module Integrations
  module Servicetitan
    class ImportsController < Servicetitan::IntegrationsController
      # (GET) show ServiceTitan api key form
      # /integrations/servicetitan/import
      # integrations_servicetitan_import_path
      # integrations_servicetitan_import_url
      def show; end

      # (PUT) import Contacts from ServiceTitan
      # /integrations/servicetitan/import
      # integrations_servicetitan_import_path
      # integrations_servicetitan_import_url
      #   import_type = params.dig(:import_type)
      def update
        if params.dig(:commit).to_s.casecmp?('reset form')
          @client_api_integration.update(import: {})
        else
          sanitized_params        = params.require(:import_type).permit(:account_0, :account_above_0, :account_below_0, :active_only, :created_period, :ignore_emails)
          sanitized_import_params = import_params

          import_criteria = {
            account_0:       { import: sanitized_params.dig(:account_0).to_bool, campaign_id: sanitized_import_params[:campaign_id_0], group_id: sanitized_import_params[:group_id_0], stage_id: sanitized_import_params[:stage_id_0], stop_campaign_ids: sanitized_import_params[:stop_campaign_ids_0], tag_id: sanitized_import_params[:tag_id_0] },
            account_above_0: { import: sanitized_params.dig(:account_above_0).to_bool, campaign_id: sanitized_import_params[:campaign_id_above_0], group_id: sanitized_import_params[:group_id_above_0], stage_id: sanitized_import_params[:stage_id_above_0], stop_campaign_ids: sanitized_import_params[:stop_campaign_ids_above_0], tag_id: sanitized_import_params[:tag_id_above_0] },
            account_below_0: { import: sanitized_params.dig(:account_below_0).to_bool, campaign_id: sanitized_import_params[:campaign_id_below_0], group_id: sanitized_import_params[:group_id_below_0], stage_id: sanitized_import_params[:stage_id_below_0], stop_campaign_ids: sanitized_import_params[:stop_campaign_ids_below_0], tag_id: sanitized_import_params[:tag_id_below_0] },
            active_only:     sanitized_params.dig(:active_only).to_bool,
            ignore_emails:   sanitized_params.dig(:ignore_emails).to_bool
          }

          created_period = sanitized_params.dig(:created_period).to_s.split(' to ')

          import_criteria[:created_after]  = created_period[0].to_s.present? ? (Time.use_zone(@client_api_integration.client.time_zone) { Chronic.parse(created_period[0].to_s) }).beginning_of_day.utc : nil
          import_criteria[:created_before] = if created_period[1].to_s.present?
                                               Time.use_zone(@client_api_integration.client.time_zone) { Chronic.parse(created_period[1].to_s) }.end_of_day.utc
                                             else
                                               created_period[0].to_s.present? ? (Time.use_zone(@client_api_integration.client.time_zone) { Chronic.parse(created_period[0].to_s) }).end_of_day.utc : nil
                                             end

          Integrations::Servicetitan::V2::Customers::Imports::ByClientJob.perform_later(
            client_id:       @client_api_integration.client_id,
            import_criteria:,
            user_id:         current_user.id
          )

          Integration::Servicetitan::V2::Base.new(@client_api_integration).import_contacts_remaining_update(current_user.id)
        end
      end
      # example params
      # {
      #   "authenticity_token"=>"[FILTERED]",
      #   "button"=>"",
      #   "import_type"=>{
      #     "created_period"=>"01/01/2024 to 01/31/2024",
      #     "active_only"=>"1",
      #     "account_0"=>"1",
      #     "account_below_0"=>"1",
      #     "account_above_0"=>"1"
      #   },
      #   "import"=>{
      #     "campaign_id_0"=>"",
      #     "group_id_0"=>"",
      #     "tag_id_0"=>"354",
      #     "stage_id_0"=>"",
      #     "stop_campaign_ids_0"=>[""],
      #     "campaign_id_below_0"=>"",
      #     "group_id_below_0"=>"",
      #     "tag_id_below_0"=>"355",
      #     "stage_id_below_0"=>"",
      #     "stop_campaign_ids_below_0"=>[""],
      #     "campaign_id_above_0"=>"",
      #     "group_id_above_0"=>"",
      #     "tag_id_above_0"=>"356",
      #     "stage_id_above_0"=>"",
      #     "stop_campaign_ids_above_0"=>[""]},
      #     "group"=>{"import[group_id_0"=>{"][name]"=>""}, "import[group_id_below_0"=>{"][name]"=>""}, "import[group_id_above_0"=>{"][name]"=>""}},
      #     "tag"=>{"import[tag_id_0"=>{"][name]"=>""}, "import[tag_id_below_0"=>{"][name]"=>""}, "import[tag_id_above_0"=>{"][name]"=>""}},
      #     "commit"=>"Save Actions & Import"
      #   }

      private

      def import_params
        response = params.require(:import).permit(:campaign_id_0, :group_id_0, :stage_id_0, :tag_id_0, :campaign_id_above_0, :group_id_above_0, :stage_id_above_0, :tag_id_above_0, :campaign_id_below_0, :group_id_below_0, :stage_id_below_0, :tag_id_below_0, stop_campaign_ids_0: [], stop_campaign_ids_above_0: [], stop_campaign_ids_below_0: [])

        response[:campaign_id_0]             = response[:campaign_id_0].to_i if response.include?(:campaign_id_0)
        response[:group_id_0]                = response[:group_id_0].to_i if response.include?(:group_id_0)
        response[:stage_id_0]                = response[:stage_id_0].to_i if response.include?(:stage_id_0)
        response[:stop_campaign_ids_0]       = response[:stop_campaign_ids_0].compact_blank if response.include?(:stop_campaign_ids_0)
        response[:stop_campaign_ids_0]       = [0] if response[:stop_campaign_ids_0]&.include?('0')
        response[:tag_id_0]                  = response[:tag_id_0].to_i if response.include?(:tag_id_0)
        response[:campaign_id_above_0]       = response[:campaign_id_above_0].to_i if response.include?(:campaign_id_above_0)
        response[:group_id_above_0]          = response[:group_id_above_0].to_i if response.include?(:group_id_above_0)
        response[:stage_id_above_0]          = response[:stage_id_above_0].to_i if response.include?(:stage_id_above_0)
        response[:stop_campaign_ids_above_0] = response[:stop_campaign_ids_above_0].compact_blank if response.include?(:stop_campaign_ids_above_0)
        response[:stop_campaign_ids_above_0] = [0] if response[:stop_campaign_ids_above_0]&.include?('0')
        response[:tag_id_above_0]            = response[:tag_id_above_0].to_i if response.include?(:tag_id_above_0)
        response[:campaign_id_below_0]       = response[:campaign_id_below_0].to_i if response.include?(:campaign_id_below_0)
        response[:group_id_below_0]          = response[:group_id_below_0].to_i if response.include?(:group_id_below_0)
        response[:stage_id_below_0]          = response[:stage_id_below_0].to_i if response.include?(:stage_id_below_0)
        response[:stop_campaign_ids_below_0] = response[:stop_campaign_ids_below_0].compact_blank if response.include?(:stop_campaign_ids_below_0)
        response[:stop_campaign_ids_below_0] = [0] if response[:stop_campaign_ids_below_0]&.include?('0')
        response[:tag_id_below_0]            = response[:tag_id_below_0].to_i if response.include?(:tag_id_below_0)

        response
      end
    end
  end
end
