# frozen_string_literal: true

# app/models/integration/dope/v1/references_destroyed.rb
module Integration
  module Dope
    module V1
      class ReferencesDestroyed
        # remove reference to a Tag that was destroyed
        # Integration::Dope::V1::ReferencesDestroyed.references_destroyed()
        #   (req) client_id: (Integer)
        #   (req) tag_id:    (Integer)
        def self.references_destroyed(**args)
          return false unless (Integer(args.dig(:client_id), exception: false) || 0).positive? && (Integer(args.dig(:tag_id), exception: false) || 0).positive? &&
                              (client_api_integration = ClientApiIntegration.find_by(client_id: args[:client_id], target: 'sendjim', name: ''))

          tag_id = args.dig(:tag_id).to_i

          client_api_integration.automations&.each do |automation|
            automation['tag_id'] = 0 if automation.dig('tag_id')&.to_i == tag_id
          end

          client_api_integration.save
        end
      end
    end
  end
end
