# frozen_string_literal: true

# app/lib/integrations/vital_ly/v2024/users.rb
module Integrations
  module VitalLy
    module V2024
      module Users
        # get a Vitally User
        # vt_client.user()
        #   (opt) external_id: (Integer)
        #   (opt) email:       (String)
        def user(**args)
          reset_attributes
          @result = []

          if args.dig(:external_id).blank? && args.dig(:email).blank?
            @message = 'Vitally external ID or user email is required.'
            return @result
          end

          params = {}
          params[:externalId] = args.dig(:external_id).to_s if args.dig(:external_id).present?
          params[:email]      = args.dig(:email).to_s if args.dig(:email).present?

          vitally_request(
            body:                  nil,
            error_message_prepend: 'Integrations::VitalLy::Users.user',
            method:                'get',
            params:,
            default_result:        @result,
            url:                   'resources/users/search'
          )

          @result
        end
        # example result
        # {
        #   :results=> [
        #     {
        #       id: "fc173be5-e4fe-4e6c-a0b3-c7d9d72db90c",
        #       createdAt: "2024-04-12T21:56:33.380Z",
        #       updatedAt: "2024-05-08T09:41:51.533Z",
        #       externalId: "nancy@ydcteam.com",
        #       accounts:
        #       [
        #         {
        #           id: "465f9d11-f5c8-4c70-b6ca-5cbc9d352257",
        #           createdAt: "2024-04-12T21:54:31.881Z",
        #           updatedAt: "2024-05-08T06:38:15.082Z",
        #           externalId: "3721",
        #           name: "Maynard Plumbing, Heating, Cooling",
        #           traits: {
        #             "hspot.name": "Maynard Plumbing, Heating, Cooling",
        #             "csv.csmEmail": "garen@chiirp.com",
        #             "hspot.domain": "ydcteam.com",
        #             "hspot.client_id": "3721",
        #             "hspot.notes_last_contacted": 1712349466167,
        #             "hspot.hs_date_entered_85614227": nil
        #           },
        #           organizationId: nil,
        #           accountOwnerId: nil,
        #           mrr: nil,
        #           nextRenewalDate: nil,
        #           churnedAt: nil,
        #           firstSeenTimestamp: nil,
        #           lastSeenTimestamp: nil,
        #           lastInboundMessageTimestamp: nil,
        #           lastOutboundMessageTimestamp: nil,
        #           trialEndDate: nil,
        #           usersCount: 3,
        #           npsDetractorCount: 0,
        #           npsPassiveCount: 0,
        #           npsPromoterCount: 0,
        #           npsScore: nil,
        #           healthScore: nil,
        #           csmId: "bbab97d8-72de-44b0-90d2-a5e7212fdc3d",
        #           accountExecutiveId: nil,
        #           segments: []
        #         }
        #       ],
        #       organizations: [],
        #       name: nil,
        #       email: "nancy@ydcteam.com",
        #       avatar: nil,
        #       traits: {},
        #       firstKnown: "2024-04-12T21:56:33.389Z",
        #       lastSeenTimestamp: nil,
        #       lastInboundMessageTimestamp: nil,
        #       lastOutboundMessageTimestamp: nil,
        #       npsLastScore: nil,
        #       npsLastFeedback: nil,
        #       npsLastRespondedAt: nil,
        #       unsubscribedFromConversations: false,
        #       unsubscribedFromConversationsAt: nil,
        #       deactivatedAt: nil,
        #       segments: [],
        #       joinDate: "2024-04-12T21:56:33.389Z"
        #     }
        #   ]
        # }

        # delete a Vitally User
        # vt_client.user_destroy()
        #   (opt) id: (Integer)
        def user_destroy(**args)
          reset_attributes
          @result = {}

          if args.dig(:id).blank?
            @message = 'Vitally user ID is required.'
            return @result
          end

          vitally_request(
            body:                  nil,
            error_message_prepend: 'Integrations::VitalLy::Users.user_destroy',
            method:                'delete',
            params:                nil,
            default_result:        @result,
            url:                   "resources/users/#{args[:id]}"
          )

          @success
        end
        # example result
        # true

        # create a new Vitally User
        # vt_client.user_new()
        #   (req) account_id:     (String)
        #   (req) email:          (String)
        #   (req) external_id:    (Integer)
        #   (req) name:           (String)
        #
        #   (opt) avatar:         (String)
        def user_new(**args)
          reset_attributes
          @result = []

          if args.dig(:account_id).blank?
            @message = 'Vitally account ID is required.'
            return @result
          elsif args.dig(:email).blank?
            @message = 'User email is required.'
            return @result
          elsif args.dig(:external_id).blank?
            @message = 'Vitally user external ID is required.'
            return @result
          elsif args.dig(:name).blank?
            @message = 'User name is required.'
            return @result
          end

          body = {
            accountIds: [args[:account_id].to_s],
            email:      args[:email].to_s,
            externalId: args.dig(:external_id).to_s,
            name:       args[:name].to_s
          }
          body[:avatar] = args.dig(:avatar).to_s if args.dig(:avatar).present?

          vitally_request(
            body:,
            error_message_prepend: 'Integrations::VitalLy::Users.user_new',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   'resources/users'
          )

          @result
        end
        # example result
        # {
        #   id: "32e17794-b317-4428-82c4-0aabc18f1f35",
        #   createdAt: "2024-05-10T21:16:42.383Z",
        #   updatedAt: "2024-05-10T21:16:42.383Z",
        #   externalId: "4",
        #   accounts: [
        #     {
        #       id: "9e085d43-5204-4eff-8813-749e289a2485",
        #       createdAt: "2024-05-10T15:37:51.762Z",
        #       updatedAt: "2024-05-10T21:16:42.383Z",
        #       externalId: "1",
        #       name: "Joe's Garage",
        #       traits: {},
        #       organizationId: nil,
        #       accountOwnerId: nil,
        #       mrr: nil,
        #       nextRenewalDate: nil,
        #       churnedAt: nil,
        #       firstSeenTimestamp: nil,
        #       lastSeenTimestamp: nil,
        #       lastInboundMessageTimestamp: nil,
        #       lastOutboundMessageTimestamp: nil,
        #       trialEndDate: nil,
        #       usersCount: 2,
        #       npsDetractorCount: 0,
        #       npsPassiveCount: 0,
        #       npsPromoterCount: 0,
        #       npsScore: nil,
        #       healthScore: nil,
        #       csmId: nil,
        #       accountExecutiveId: nil,
        #       segments: []
        #     }
        #   ],
        #   organizations: [],
        #   name: "Kevin Neubert",
        #   email: "kevin@chiirp.com",
        #   avatar: nil,
        #   traits: {},
        #   firstKnown: "2024-05-10T21:16:42.383Z",
        #   lastSeenTimestamp: nil,
        #   lastInboundMessageTimestamp: nil,
        #   lastOutboundMessageTimestamp: nil,
        #   npsLastScore: nil,
        #   npsLastFeedback: nil,
        #   npsLastRespondedAt: nil,
        #   unsubscribedFromConversations: false,
        #   unsubscribedFromConversationsAt: nil,
        #   deactivatedAt: nil,
        #   segments: [],
        #   joinDate: "2024-05-10T21:16:42.383Z"
        # }

        # update an existing Vitally User
        # vt_client.user_update()
        #   (req) id:         (String)
        #   (req) email:      (String)
        #   (req) name:       (String)
        #
        #   (opt) avatar:     (String)
        def user_update(**args)
          reset_attributes
          @result = []

          if args.dig(:id).blank?
            @message = 'Vitally user ID is required.'
            return @result
          elsif args.dig(:email).blank?
            @message = 'User email is required.'
            return @result
          elsif args.dig(:name).blank?
            @message = 'User name is required.'
            return @result
          end

          body = {
            email: args[:email].to_s,
            name:  args[:name].to_s
          }
          body[:avatar] = args.dig(:avatar).to_s if args.dig(:avatar).present?

          vitally_request(
            body:,
            error_message_prepend: 'Integrations::VitalLy::Users.user_update',
            method:                'put',
            params:                nil,
            default_result:        @result,
            url:                   "resources/users/#{args[:id]}"
          )

          @result
        end
        # example result
        # {
        #   id: "e4ee3be4-d1f2-4dfe-896f-56df412658d7",
        #   createdAt: "2024-05-10T15:52:48.546Z",
        #   updatedAt: "2024-05-10T20:47:50.871Z",
        #   externalId: "3",
        #   accounts: [
        #     {
        #       id: "9e085d43-5204-4eff-8813-749e289a2485",
        #       createdAt: "2024-05-10T15:37:51.762Z",
        #       updatedAt: "2024-05-10T15:52:48.546Z",
        #       externalId: "1",
        #       name: "Joe's Garage",
        #       traits: {},
        #       organizationId: nil,
        #       accountOwnerId: nil,
        #       mrr: nil,
        #       nextRenewalDate: nil,
        #       churnedAt: nil,
        #       firstSeenTimestamp: nil,
        #       lastSeenTimestamp: nil,
        #       lastInboundMessageTimestamp: nil,
        #       lastOutboundMessageTimestamp: nil,
        #       trialEndDate: nil,
        #       usersCount: 1,
        #       npsDetractorCount: 0,
        #       npsPassiveCount: 0,
        #       npsPromoterCount: 0,
        #       npsScore: nil,
        #       healthScore: nil,
        #       csmId: nil,
        #       accountExecutiveId: nil,
        #       segments: []
        #     }
        #   ],
        #   organizations: [],
        #   name: "Kevin Neubert",
        #   email: "kevin@chiirp.com",
        #   avatar: "<img src=\"https://res.cloudinary.com/hcfhlrdjg/image/upload/czlvwxrrx11mrojw207z6w7gxosr.png\" />",
        #   traits: {},
        #   firstKnown: "2024-05-10T15:52:48.546Z",
        #   lastSeenTimestamp: nil,
        #   lastInboundMessageTimestamp: nil,
        #   lastOutboundMessageTimestamp: nil,
        #   npsLastScore: nil,
        #   npsLastFeedback: nil,
        #   npsLastRespondedAt: nil,
        #   unsubscribedFromConversations: false,
        #   unsubscribedFromConversationsAt: nil,
        #   deactivatedAt: nil,
        #   segments: [],
        #   joinDate: "2024-05-10T15:52:48.546Z"
        # }

        # get Vitally Users
        # vt_client.users
        def users
          reset_attributes
          default_result = {}
          response = {
            results: []
          }
          params = {
            limit: 100
          }

          loop do
            vitally_request(
              body:                  nil,
              error_message_prepend: 'Integrations::VitalLy::Users.users',
              method:                'get',
              params:,
              default_result:,
              url:                   'resources/users'
            )

            if @result.is_a?(Hash) && @result.dig(:next).present? && @result.dig(:results).present?
              response[:results] += @result.dig(:results)
              params[:from]       = @result.dig(:next)
            elsif @result.is_a?(Hash) && @result.dig(:results).present?
              response[:results] += @result.dig(:results)
              @result = response
              break
            else
              @result = default_result
              break
            end
          end

          @result
        end
        # example result
        # {
        #   :results=>[
        #     {
        #       id: "bc8f0039-2952-42a6-ad4f-2053a564b20b",
        #       createdAt: "2024-04-12T21:55:30.573Z",
        #       updatedAt: "2024-05-08T18:41:39.893Z",
        #       externalId: "acplus@acplushvac.com",
        #       accounts: [
        #         {
        #           id: "54d3c138-e7ce-4b3a-9cf5-cd129b339b9c",
        #           createdAt: "2024-04-12T21:53:28.798Z",
        #           updatedAt: "2024-05-08T09:39:47.816Z",
        #           externalId: "4094",
        #           name: "AC Plus Heating and Air Conditioning",
        #           traits:
        #             {
        #               "hspot.name": "AC Plus Heating and Air Conditioning",
        #               "csv.csmEmail": "garen@chiirp.com",
        #               "hspot.domain": "acplushvac.com",
        #               "hspot.client_id": "4094",
        #               "hspot.notes_last_contacted": nil,
        #               "hspot.hs_date_entered_85614227": nil
        #             },
        #           organizationId: nil,
        #           accountOwnerId: nil,
        #           mrr: nil,
        #           nextRenewalDate: nil,
        #           churnedAt: nil,
        #           firstSeenTimestamp: nil,
        #           lastSeenTimestamp: nil,
        #           lastInboundMessageTimestamp: nil,
        #           lastOutboundMessageTimestamp: nil,
        #           trialEndDate: nil,
        #           usersCount: 3,
        #           npsDetractorCount: 0,
        #           npsPassiveCount: 0,
        #           npsPromoterCount: 0,
        #           npsScore: nil,
        #           healthScore: nil,
        #           csmId: "bbab97d8-72de-44b0-90d2-a5e7212fdc3d",
        #           accountExecutiveId: nil,
        #           segments: []
        #         }
        #       ],
        #       :organizations=>[],
        #       :name=>"Matt Postoian",
        #       :email=>"acplus@acplushvac.com",
        #       :avatar=>nil,
        #       :traits=>{},
        #       :firstKnown=>"2024-04-12T21:55:30.574Z",
        #       :lastSeenTimestamp=>nil,
        #       :lastInboundMessageTimestamp=>nil,
        #       :lastOutboundMessageTimestamp=>nil,
        #       :npsLastScore=>nil,
        #       :npsLastFeedback=>nil,
        #       :npsLastRespondedAt=>nil,
        #       :unsubscribedFromConversations=>false,
        #       :unsubscribedFromConversationsAt=>nil,
        #       :deactivatedAt=>nil,
        #       :segments=>[],
        #       :joinDate=>"2024-04-12T21:55:30.574Z"
        #     },
        #     ...
        #   ]
        # }
      end
    end
  end
end
