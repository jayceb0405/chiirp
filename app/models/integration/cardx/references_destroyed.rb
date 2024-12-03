# frozen_string_literal: true

# app/models/Integration/cardx/references_destroyed.rb
module Integration
  module Cardx
    module ReferencesDestroyed
      # remove reference to a Campaign/Group/Stage/Tag that was destroyed
      # cx_model.references_destroyed()
      #   (opt) campaign_id:    (Integer)
      #   (opt) group_id:       (Integer)
      #   (opt) stage_id:       (Integer)
      #   (opt) tag_id:         (Integer)
      def references_destroyed(**args)
        return false unless (Integer(args.dig(:campaign_id), exception: false) || 0).positive? || (Integer(args.dig(:group_id), exception: false) || 0).positive? ||
                            (Integer(args.dig(:stage_id), exception: false) || 0).positive? || (Integer(args.dig(:tag_id), exception: false) || 0).positive?

        campaign_id = args.dig(:campaign_id).to_i
        group_id    = args.dig(:group_id).to_i
        stage_id    = args.dig(:stage_id).to_i
        tag_id      = args.dig(:tag_id).to_i

        @client_api_integration.events&.each do |event|
          event['action']['campaign_id']        = 0 if event.dig('action', 'campaign_id').to_i == campaign_id
          event['action']['group_id']           = 0 if event.dig('action', 'group_id').to_i == group_id
          event['action']['stage_id']           = 0 if event.dig('action', 'stage_id').to_i == stage_id
          event['action']['tag_id']             = 0 if event.dig('action', 'tag_id').to_i == tag_id
          event['action']['stop_campaign_ids'] -= [campaign_id] if event.dig('action', 'stop_campaign_ids')&.map(&:to_i)&.include?(campaign_id)
        end

        @client_api_integration.save
      end
    end
  end
end
