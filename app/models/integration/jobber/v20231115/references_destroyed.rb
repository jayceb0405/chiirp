# frozen_string_literal: true

# app/models/integration/jobber/v20231115/references_destroyed.rb
module Integration
  module Jobber
    module V20231115
      module ReferencesDestroyed
        # remove reference to a Campaign/Group/Stage/Tag that was destroyed
        # jb_model.references_destroyed()
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

          @client_api_integration.webhooks&.each_value do |webhook|
            webhook.each do |event|
              event['actions']['campaign_id'] = 0 if event.dig('actions', 'campaign_id').to_i == campaign_id
              event['actions']['group_id']    = 0 if event.dig('actions', 'group_id').to_i == group_id
              event['actions']['stage_id']    = 0 if event.dig('actions', 'stage_id').to_i == stage_id
              event['actions']['tag_id']      = 0 if event.dig('actions', 'tag_id').to_i == tag_id
            end
          end

          @client_api_integration.push_contacts_tag_id = 0 if @client_api_integration.push_contacts_tag_id.to_i == tag_id

          @client_api_integration.save
        end
      end
    end
  end
end
