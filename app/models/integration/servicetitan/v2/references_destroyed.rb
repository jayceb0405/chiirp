# frozen_string_literal: true

# app/models/Integration/servicetitan/v2/estimates.rb
module Integration
  module Servicetitan
    module V2
      module ReferencesDestroyed
        # remove reference to a Campaign/Group/Stage/Tag that was destroyed
        # st_model.references_destroyed()
        #   (opt) campaign_id:    (Integer)
        #   (opt) group_id:       (Integer)
        #   (opt) tag_id:         (Integer)
        #   (opt) stage_id:       (Integer)
        def references_destroyed(**args)
          return false unless (Integer(args.dig(:campaign_id), exception: false) || 0).positive? || (Integer(args.dig(:group_id), exception: false) || 0).positive? ||
                              (Integer(args.dig(:stage_id), exception: false) || 0).positive? || (Integer(args.dig(:tag_id), exception: false) || 0).positive?

          campaign_id = args.dig(:campaign_id).to_i
          group_id    = args.dig(:group_id).to_i
          stage_id    = args.dig(:stage_id).to_i
          tag_id      = args.dig(:tag_id).to_i

          @client_api_integration.events.each_value do |event|
            event['campaign_id'] = 0 if event.dig('campaign_id').to_i == campaign_id
            event['group_id']    = 0 if event.dig('group_id').to_i == group_id
            event['stage_id']    = 0 if event.dig('stage_id').to_i == stage_id
            event['tag_id']      = 0 if event.dig('tag_id').to_i == tag_id
          end

          @client_api_integration.import['campaign_id'] = 0 if @client_api_integration.import.dig('campaign_id').to_i == campaign_id
          @client_api_integration.import['group_id']    = 0 if @client_api_integration.import.dig('group_id').to_i == group_id
          @client_api_integration.import['stage_id']    = 0 if @client_api_integration.import.dig('stage_id').to_i == stage_id
          @client_api_integration.import['tag_id']      = 0 if @client_api_integration.import.dig('tag_id').to_i == tag_id

          @client_api_integration.update_balance_actions['campaign_id_0']        = 0 if @client_api_integration.update_balance_actions.dig('campaign_id_0').to_i == campaign_id
          @client_api_integration.update_balance_actions['group_id_0']           = 0 if @client_api_integration.update_balance_actions.dig('group_id_0').to_i == group_id
          @client_api_integration.update_balance_actions['stage_id_0']           = 0 if @client_api_integration.update_balance_actions.dig('stage_id_0').to_i == stage_id
          @client_api_integration.update_balance_actions['tag_id_0']             = 0 if @client_api_integration.update_balance_actions.dig('tag_id_0').to_i == tag_id
          @client_api_integration.update_balance_actions['stop_campaign_ids_0'] -= [campaign_id] if @client_api_integration.update_balance_actions.dig('stop_campaign_ids_0')&.include?(campaign_id)

          @client_api_integration.update_balance_actions['campaign_id_increase']        = 0 if @client_api_integration.update_balance_actions.dig('campaign_id_increase').to_i == campaign_id
          @client_api_integration.update_balance_actions['group_id_increase']           = 0 if @client_api_integration.update_balance_actions.dig('group_id_increase').to_i == group_id
          @client_api_integration.update_balance_actions['stage_id_increase']           = 0 if @client_api_integration.update_balance_actions.dig('stage_id_increase').to_i == stage_id
          @client_api_integration.update_balance_actions['tag_id_increase']             = 0 if @client_api_integration.update_balance_actions.dig('tag_id_increase').to_i == tag_id
          @client_api_integration.update_balance_actions['stop_campaign_ids_increase'] -= [campaign_id] if @client_api_integration.update_balance_actions.dig('stop_campaign_ids_increase')&.include?(campaign_id)

          @client_api_integration.update_balance_actions['campaign_id_increase']        = 0 if @client_api_integration.update_balance_actions.dig('campaign_id_increase').to_i == campaign_id
          @client_api_integration.update_balance_actions['group_id_increase']           = 0 if @client_api_integration.update_balance_actions.dig('group_id_increase').to_i == group_id
          @client_api_integration.update_balance_actions['stage_id_increase']           = 0 if @client_api_integration.update_balance_actions.dig('stage_id_increase').to_i == stage_id
          @client_api_integration.update_balance_actions['tag_id_increase']             = 0 if @client_api_integration.update_balance_actions.dig('tag_id_decrease').to_i == tag_id
          @client_api_integration.update_balance_actions['stop_campaign_ids_decrease'] -= [campaign_id] if @client_api_integration.update_balance_actions.dig('stop_campaign_ids_decrease')&.include?(campaign_id)

          @client_api_integration.save
        end
      end
    end
  end
end
