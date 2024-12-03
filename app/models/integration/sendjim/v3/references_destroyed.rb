# frozen_string_literal: true

# app/models/integration/sendjim/v3/references_destroyed.rb
module Integration
  module Sendjim
    module V3
      class ReferencesDestroyed
        # remove reference to a Tag that was destroyed
        # Integration::Sendjim::V3::ReferencesDestroyed.references_destroyed()
        #   (req) client_id: (Integer)
        #   (req) tag_id:    (Integer)
        def self.references_destroyed(**args)
          return false unless (Integer(args.dig(:client_id), exception: false) || 0).positive? && (Integer(args.dig(:tag_id), exception: false) || 0).positive? &&
                              (client_api_integration = ClientApiIntegration.find_by(client_id: args[:client_id], target: 'sendjim', name: ''))

          tag_id = args.dig(:tag_id).to_i

          client_api_integration.push_contacts&.each do |push_contact|
            push_contact['tag_id'] = 0 if push_contact.dig('tag_id')&.to_i == tag_id
          end

          client_api_integration.save
        end
      end
    end
  end
end
