# frozen_string_literal: true

# app/models/Integration/vitally/v2024/accounts.rb
module Integration
  module Vitally
    module V2024
      module Accounts
        # get a Vitally Account
        # vt_model.client()
        #   (req) client_id: (Integer)
        def client(client_id)
          reset_attributes
          @result = {}

          unless client_id.to_i.positive? && (client = Client.find_by(id: client_id.to_i))
            @message = 'Client ID is required.'
            return @result
          end

          @vt_client.account(client.id)

          update_attributes_from_client

          @result
        end
        # example unsuccessful result
        # {}
        # example successful result
        # {
        #   id: "9e085d43-5204-4eff-8813-749e289a2485",
        #   createdAt: "2024-05-10T15:37:51.762Z",
        #   updatedAt: "2024-05-13T15:35:28.703Z",
        #   externalId: "1",
        #   name: "Joe's Garage",
        #   traits: {},
        #   organizationId: nil,
        #   accountOwnerId: nil,
        #   mrr: nil,
        #   nextRenewalDate: nil,
        #   churnedAt: nil,
        #   firstSeenTimestamp: nil,
        #   lastSeenTimestamp: nil,
        #   lastInboundMessageTimestamp: nil,
        #   lastOutboundMessageTimestamp: nil,
        #   trialEndDate: nil,
        #   usersCount: 7,
        #   npsDetractorCount: 0,
        #   npsPassiveCount: 0,
        #   npsPromoterCount: 0,
        #   npsScore: nil,
        #   healthScore: nil,
        #   csmId: nil,
        #   accountExecutiveId: nil,
        #   segments: [],
        #   keyRoles: []
        # }

        # vt_model.client_found?()
        #   (req) client_id: (Integer)
        def client_found?(client_id)
          reset_attributes
          client(client_id)

          @success
        end
        # example unsuccessful result
        # false
        # example successful result
        # true

        # vt_model.client_push()
        #   (req) client_id: (Integer)
        #   (req) name:      (String)
        def client_push(client_id)
          reset_attributes

          unless client_id.to_i.positive? && (client = Client.find_by(id: client_id.to_i))
            @message = 'Client ID is required.'
            return @success
          end

          if client_found?(client.id)
            @vt_client.account_update(id: @result.dig(:id), name: client.name)
          else
            @vt_client.account_new(client_id: client.id, name: client.name)
          end

          update_attributes_from_client

          @success
        end
        # example unsuccessful result
        # false
        # example successful result
        # true

        def clients
          reset_attributes
          @result = []

          @vt_client.accounts

          @result = @vt_client.result.dig(:results) if @vt_client.success? && @vt_client.result.dig(:results).present?

          @result
        end
        # example result
        # [
        #   { id:                           'a062cd88-4107-49c8-9533-997ace2eb770',
        #     createdAt:                    '2024-05-20T18:58:14.113Z',
        #     updatedAt:                    '2024-05-20T19:08:14.759Z',
        #     externalId:                   '3461',
        #     name:                         'Art Plumbing, Air Conditioning & Electric',
        #     traits:                       {},
        #     organizationId:               nil,
        #     accountOwnerId:               nil,
        #     mrr:                          nil,
        #     nextRenewalDate:              nil,
        #     churnedAt:                    nil,
        #     firstSeenTimestamp:           nil,
        #     lastSeenTimestamp:            nil,
        #     lastInboundMessageTimestamp:  nil,
        #     lastOutboundMessageTimestamp: nil,
        #     trialEndDate:                 nil,
        #     usersCount:                   1,
        #     npsDetractorCount:            0,
        #     npsPassiveCount:              0,
        #     npsPromoterCount:             0,
        #     npsScore:                     nil,
        #     healthScore:                  nil,
        #     csmId:                        nil,
        #     accountExecutiveId:           nil,
        #     segments:                     [],
        #     keyRoles:                     [] },
        #   { id:                           '50f71db5-e6de-48d4-8cd3-647a19b219d9',
        #     createdAt:                    '2024-05-20T18:57:51.818Z',
        #     updatedAt:                    '2024-05-20T19:07:52.326Z',
        #     externalId:                   '4242',
        #     name:                         'Universe Home Services',
        #     traits:                       {},
        #     organizationId:               nil,
        #     accountOwnerId:               nil,
        #     mrr:                          nil,
        #     nextRenewalDate:              nil,
        #     churnedAt:                    nil,
        #     firstSeenTimestamp:           nil,
        #     lastSeenTimestamp:            nil,
        #     lastInboundMessageTimestamp:  nil,
        #     lastOutboundMessageTimestamp: nil,
        #     trialEndDate:                 nil,
        #     usersCount:                   1,
        #     npsDetractorCount:            0,
        #     npsPassiveCount:              0,
        #     npsPromoterCount:             0,
        #     npsScore:                     nil,
        #     healthScore:                  nil,
        #     csmId:                        nil,
        #     accountExecutiveId:           nil,
        #     segments:                     [],
        #     keyRoles:                     []
        #   },
        #   ...
        # ]
      end
    end
  end
end
