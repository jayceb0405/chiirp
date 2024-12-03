# frozen_string_literal: true

# app/lib/integrations/vital_ly/v2024/accounts.rb
module Integrations
  module VitalLy
    module V2024
      module Accounts
        # get a Vitally Account
        # vt_client.account(1234)
        #   (req) external_id: (Integer) client_id
        def account(external_id)
          reset_attributes
          default_result = {}

          if external_id.to_i.zero?
            @message = 'Client id is required.'
            return @result
          end

          vitally_request(
            body:                  nil,
            error_message_prepend: 'Integrations::VitalLy::Accounts.account',
            method:                'get',
            params:                nil,
            default_result:,
            url:                   "resources/accounts/#{external_id}"
          )

          @result
        end
        # example result
        # {
        #   id:                           '287b4a09-7da8-44a7-a018-554f89fac7c4',
        #   createdAt:                    '2024-04-12T21:54:31.881Z',
        #   updatedAt:                    '2024-05-07T06:40:54.337Z',
        #   externalId:                   '3763',
        #   name:                         'Dalton Plumbing Heating Cooling Electric & Fireplaces',
        #   traits:                       {
        #     'hspot.name':                     'Dalton Plumbing Heating Cooling Electric & Fireplaces',
        #     'csv.csmEmail':                   'garen@chiirp.com',
        #     'hspot.domain':                   'daltonphc.com',
        #     'hspot.client_id':                '3763',
        #     'hspot.notes_last_contacted':     nil,
        #     'hspot.hs_date_entered_85614227': nil
        #   },
        #   organizationId:               nil,
        #   accountOwnerId:               nil,
        #   mrr:                          nil,
        #   nextRenewalDate:              nil,
        #   churnedAt:                    nil,
        #   firstSeenTimestamp:           nil,
        #   lastSeenTimestamp:            nil,
        #   lastInboundMessageTimestamp:  nil,
        #   lastOutboundMessageTimestamp: nil,
        #   trialEndDate:                 nil,
        #   usersCount:                   2,
        #   npsDetractorCount:            0,
        #   npsPassiveCount:              0,
        #   npsPromoterCount:             0,
        #   npsScore:                     nil,
        #   healthScore:                  nil,
        #   csmId:                        'bbab97d8-72de-44b0-90d2-a5e7212fdc3d',
        #   accountExecutiveId:           nil,
        #   segments:                     [],
        #   keyRoles:                     [
        #     {
        #       id:          '7a127e94-6dfc-47a4-b4b5-5576f6cb197a',
        #       createdAt:   '2024-04-22T15:40:08.230Z',
        #       assignedAt:  '2024-04-22T15:40:08.230Z',
        #       vitallyUser: { id: 'bbab97d8-72de-44b0-90d2-a5e7212fdc3d', name: 'Garen Holmes', email: 'garen@chiirp.com', licenseStatus: 'active' },
        #       keyRole:     { id: 'a996067e-93f6-430b-b888-75f954bef0b0', createdAt: '2024-03-26T23:39:57.673Z', label: 'CSM' }
        #     }
        #   ]
        # }

        # delete a Vitally Account
        # vt_client.account_destroy()
        #   (req) external_id: (Integer) client_id
        def account_destroy(external_id)
          reset_attributes
          @result = []

          if external_id.to_i.zero?
            @message = 'Client id is required.'
            return @result
          end

          vitally_request(
            body:                  nil,
            error_message_prepend: 'Integrations::VitalLy::Accounts.account_destroy',
            method:                'delete',
            params:                nil,
            default_result:        @result,
            url:                   "resources/accounts/#{external_id}"
          )

          @success
        end
        # example result
        # true

        # create a new Vitally Account
        # vt_client.account_new()
        #   (req) client_id: (Integer)
        #   (req) name:      (String)
        def account_new(**args)
          reset_attributes
          external_id = args.dig(:client_id)
          @result     = []

          if external_id.to_i.zero?
            @message = 'Client id is required.'
            return @result
          elsif args.dig(:name).blank?
            @message = 'Client name is required.'
            return @result
          end

          body = {
            externalId: external_id.to_s,
            name:       args[:name].to_s
          }

          vitally_request(
            body:,
            error_message_prepend: 'Integrations::VitalLy::Accounts.account_new',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   'resources/accounts'
          )

          @result
        end
        # example successful result
        # {
        #   id:                           '16654646-2f31-42c8-a5e9-af4aa63dcec7',
        #   createdAt:                    '2024-05-07T21:26:26.079Z',
        #   updatedAt:                    '2024-05-07T21:26:26.079Z',
        #   externalId:                   '9234',
        #   name:                         'Test Account',
        #   traits:                       {},
        #   organizationId:               nil,
        #   accountOwnerId:               nil,
        #   mrr:                          nil,
        #   nextRenewalDate:              nil,
        #   churnedAt:                    nil,
        #   firstSeenTimestamp:           nil,
        #   lastSeenTimestamp:            nil,
        #   lastInboundMessageTimestamp:  nil,
        #   lastOutboundMessageTimestamp: nil,
        #   trialEndDate:                 nil,
        #   usersCount:                   0,
        #   npsDetractorCount:            0,
        #   npsPassiveCount:              0,
        #   npsPromoterCount:             0,
        #   npsScore:                     nil,
        #   healthScore:                  nil,
        #   csmId:                        nil,
        #   accountExecutiveId:           nil,
        #   segments:                     [],
        #   keyRoles:                     []
        # }
        # example failed result
        # {
        #   error: {
        #     message: 'validation failed',
        #     errors:  [
        #       {
        #         instancePath: '/externalId',
        #         schemaPath:   '#/properties/externalId/type',
        #         keyword:      'type',
        #         params:       {
        #           type: 'string'
        #         },
        #         message:      'must be string'
        #       }
        #     ]
        #   }
        # }

        # update an existing Vitally Account
        # vt_client.account_update()
        #   (req) id:   (String)
        #   (req) name: (String)
        def account_update(**args)
          reset_attributes
          @result = []

          if args.dig(:id).blank?
            @message = 'Vitally account ID is required.'
            return @result
          elsif args.dig(:name).blank?
            @message = 'Account name is required.'
            return @result
          end

          body = {
            name: args[:name].to_s
          }

          vitally_request(
            body:,
            error_message_prepend: 'Integrations::VitalLy::Accounts.account_update',
            method:                'put',
            params:                nil,
            default_result:        @result,
            url:                   "resources/accounts/#{args[:id]}"
          )

          @result
        end
        # example result
        # {
        #   id:                           '9e085d43-5204-4eff-8813-749e289a2485',
        #   createdAt:                    '2024-05-10T15:37:51.762Z',
        #   updatedAt:                    '2024-05-15T17:12:54.884Z',
        #   externalId:                   '1',
        #   name:                         "Joe's Garage",
        #   traits:                       {},
        #   organizationId:               nil,
        #   accountOwnerId:               nil,
        #   mrr:                          nil,
        #   nextRenewalDate:              nil,
        #   churnedAt:                    nil,
        #   firstSeenTimestamp:           nil,
        #   lastSeenTimestamp:            nil,
        #   lastInboundMessageTimestamp:  '2024-05-13T21:18:41.000Z',
        #   lastOutboundMessageTimestamp: nil,
        #   trialEndDate:                 nil,
        #   usersCount:                   7,
        #   npsDetractorCount:            0,
        #   npsPassiveCount:              0,
        #   npsPromoterCount:             0,
        #   npsScore:                     nil,
        #   healthScore:                  nil,
        #   csmId:                        nil,
        #   accountExecutiveId:           nil,
        #   segments:                     [],
        #   keyRoles:                     []
        # }

        # get Vitally Accounts
        # vt_client.accounts
        def accounts
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
              error_message_prepend: 'Integrations::VitalLy::Accounts.accounts',
              method:                'get',
              params:,
              default_result:,
              url:                   'resources/accounts'
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
        # example results
        # [
        #   {
        #     id:                           '287b4a09-7da8-44a7-a018-554f89fac7c4',
        #     createdAt:                    '2024-04-12T21:54:31.881Z',
        #     updatedAt:                    '2024-05-07T06:40:54.337Z',
        #     externalId:                   '3763',
        #     name:                         'Dalton Plumbing Heating Cooling Electric & Fireplaces',
        #     traits:                       {
        #       'hspot.name':                     'Dalton Plumbing Heating Cooling Electric & Fireplaces',
        #       'csv.csmEmail':                   'garen@chiirp.com',
        #       'hspot.domain':                   'daltonphc.com',
        #       'hspot.client_id':                '3763',
        #       'hspot.notes_last_contacted':     nil,
        #       'hspot.hs_date_entered_85614227': nil
        #     },
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
        #     usersCount:                   2,
        #     npsDetractorCount:            0,
        #     npsPassiveCount:              0,
        #     npsPromoterCount:             0,
        #     npsScore:                     nil,
        #     healthScore:                  nil,
        #     csmId:                        'bbab97d8-72de-44b0-90d2-a5e7212fdc3d',
        #     accountExecutiveId:           nil,
        #     segments:                     [],
        #     keyRoles:                     [
        #       {
        #         id:          '7a127e94-6dfc-47a4-b4b5-5576f6cb197a',
        #         createdAt:   '2024-04-22T15:40:08.230Z',
        #         assignedAt:  '2024-04-22T15:40:08.230Z',
        #         vitallyUser: { id: 'bbab97d8-72de-44b0-90d2-a5e7212fdc3d', name: 'Garen Holmes', email: 'garen@chiirp.com', licenseStatus: 'active' },
        #         keyRole:     { id: 'a996067e-93f6-430b-b888-75f954bef0b0', createdAt: '2024-03-26T23:39:57.673Z', label: 'CSM' }
        #       }
        #     ]
        #   },
        #   ...
        # ]
      end
    end
  end
end
