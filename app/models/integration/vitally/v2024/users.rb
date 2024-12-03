# frozen_string_literal: true

# app/models/Integration/vitally/v2024/users.rb
module Integration
  module Vitally
    module V2024
      module Users
        # get a Vitally User
        # vt_model.user()
        def user(**args)
          reset_attributes
          result = if args.dig(:email).present?
                     @vt_client.user(email: args[:email].to_s)
                   elsif args.dig(:user_id).to_i.positive?
                     @vt_client.user(external_id: args[:user_id].to_i)
                   else
                     {}
                   end

          update_attributes_from_client

          if result.dig(:results).present? && @vt_client.success?
            @result = @result.dig(:results)&.first
          else
            @result  = {}
            @success = false
          end

          @result
        end
        # example result when user is not found in Vitally:
        # {}
        # example result when user is found in Vitally:
        # {
        #   id: "92d3cd76-df0d-4a0c-86f5-c6e112201911",
        #   createdAt: "2024-05-11T14:24:54.646Z",
        #   updatedAt: "2024-05-11T14:24:54.646Z",
        #   externalId: "3",
        #   accounts: [
        #     {
        #       id: "9e085d43-5204-4eff-8813-749e289a2485",
        #       createdAt: "2024-05-10T15:37:51.762Z",
        #       updatedAt: "2024-05-11T14:24:54.646Z",
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
        #   email: "kevin@kevinneubert.com",
        #   avatar: "<img src=\"https://res.cloudinary.com/hcfhlrdjg/image/upload/czlvwxrrx11mrojw207z6w7gxosr.png\" />",
        #   traits: {},
        #   firstKnown: "2024-05-11T14:24:54.646Z",
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
        #   joinDate: "2024-05-11T14:24:54.646Z"
        # }

        # delete a Vitally User
        # vt_model.user_destroy()
        #   (req) user_id: (Integer)
        def user_destroy(user_id)
          reset_attributes

          unless user_id.present? && (user = User.find_by(id: user_id))
            @message = 'User ID is required.'
            return @success
          end

          if (vt_user = user(user_id: user.id)).blank?
            @message = 'Vitally user not found.'
            return @success
          end

          @vt_client.user_destroy(id: vt_user.dig(:id))

          @result
        end
        # example result after unsuccessful deletion:
        # {}
        # example result after successful deletion:
        # {
        #   id: "92d3cd76-df0d-4a0c-86f5-c6e112201911",
        #   createdAt: "2024-05-11T14:24:54.646Z",
        #   updatedAt: "2024-05-11T14:24:54.646Z",
        #   externalId: "3",
        #   accounts: [
        #     {
        #       id: "9e085d43-5204-4eff-8813-749e289a2485",
        #       createdAt: "2024-05-10T15:37:51.762Z",
        #       updatedAt: "2024-05-11T14:24:54.646Z",
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
        #   email: "kevin@kevinneubert.com",
        #   avatar: "<img src=\"https://res.cloudinary.com/hcfhlrdjg/image/upload/czlvwxrrx11mrojw207z6w7gxosr.png\" />",
        #   traits: {},
        #   firstKnown: "2024-05-11T14:24:54.646Z",
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
        #   joinDate: "2024-05-11T14:24:54.646Z"
        # }

        # vt_model.user_found?()
        #   (req) user_id: (Integer)
        def user_found?(user_id)
          reset_attributes
          user(user_id:)

          @success
        end
        # example result when not found:
        # {}
        # example result when found:
        # {
        #   id: "92d3cd76-df0d-4a0c-86f5-c6e112201911",
        #   createdAt: "2024-05-11T14:24:54.646Z",
        #   updatedAt: "2024-05-11T14:24:54.646Z",
        #   externalId: "3",
        #   accounts: [
        #     {
        #       id: "9e085d43-5204-4eff-8813-749e289a2485",
        #       createdAt: "2024-05-10T15:37:51.762Z",
        #       updatedAt: "2024-05-11T14:24:54.646Z",
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
        #   email: "kevin@kevinneubert.com",
        #   avatar: "<img src=\"https://res.cloudinary.com/hcfhlrdjg/image/upload/czlvwxrrx11mrojw207z6w7gxosr.png\" />",
        #   traits: {},
        #   firstKnown: "2024-05-11T14:24:54.646Z",
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
        #   joinDate: "2024-05-11T14:24:54.646Z"
        # }

        # push User data to Vitally
        # vt_model.user_push()
        #   (req) user_id: (Integer)
        def user_push(user_id)
          reset_attributes

          unless user_id.present? && (user = User.find_by(id: user_id))
            @message = 'User ID is required.'
            return @success
          end

          if (vt_account = @vt_client.account(user.client_id)).blank?
            @vt_client.account_new(client_id: user.client_id, name: user.client.name)

            if @vt_client.success?
              vt_account = @vt_client.result
            else
              @message = 'Vitally account not found.'
              return @success
            end
          end

          if (vt_user = user(user_id: user.id)).present?
            @vt_client.user_update(
              id:     vt_user.dig(:id),
              email:  user.email,
              name:   user.fullname,
              avatar: user.avatar.key ? ActionController::Base.helpers.image_tag(Cloudinary::Utils.cloudinary_url(user.avatar.key, { secure_distribution: I18n.t("tenant.#{Rails.env}.cloudinary_cname"), format: 'png' })) : ''
            )
          else
            @vt_client.user_new(
              account_id:  vt_account.dig(:id),
              email:       user.email,
              external_id: user.id,
              name:        user.fullname,
              avatar:      user.avatar.key ? ActionController::Base.helpers.image_tag(Cloudinary::Utils.cloudinary_url(user.avatar.key, { secure_distribution: I18n.t("tenant.#{Rails.env}.cloudinary_cname"), format: 'png' })) : ''
            )
          end

          update_attributes_from_client

          @success
        end
        # example result after unsuccessful push:
        # {}
        # example result after successful push:
        # {
        #   id: "6219f5a9-45d3-4888-91c9-e2af18eaea9c",
        #   createdAt: "2024-05-13T13:35:52.239Z",
        #   updatedAt: "2024-05-13T13:35:52.239Z",
        #   externalId: "3",
        #   accounts: [
        #     {
        #       id: "9e085d43-5204-4eff-8813-749e289a2485",
        #       createdAt: "2024-05-10T15:37:51.762Z",
        #       updatedAt: "2024-05-13T13:35:52.239Z",
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
        #   email: "kevin@kevinneubert.com",
        #   avatar: "<img src=\"https://res.cloudinary.com/hcfhlrdjg/image/upload/czlvwxrrx11mrojw207z6w7gxosr.png\" />",
        #   traits: {},
        #   firstKnown: "2024-05-13T13:35:52.240Z",
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
        #   joinDate: "2024-05-13T13:35:52.240Z"
        # }

        def users
          reset_attributes
          @result = []

          @vt_client.users

          @result = @vt_client.result.dig(:results) if @vt_client.success? && @vt_client.result.dig(:results).present?

          @result
        end
      end
    end
  end
end
