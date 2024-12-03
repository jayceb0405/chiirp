# frozen_string_literal: true

# app/lib/integrations/vital_ly/v2024/notes.rb
module Integrations
  module VitalLy
    module V2024
      module Notes
        # get a Vitally Note
        # vt_client.note()
        #   (req) external_id: (Integer)
        #     ~ or ~
        #   (req) id:          (Integer)
        def note(**args)
          reset_attributes
          @result = []

          if args.dig(:external_id).blank? && args.dig(:id).blank?
            @message = 'Vitally ID or external ID is required.'
            return @result
          end

          vitally_request(
            body:                  nil,
            error_message_prepend: 'Integrations::VitalLy::Notes.note',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "resources/notes/#{args.dig(:id) || args.dig(:external_id)}"
          )

          @result
        end
        # example result
        # {
        #   id:             'c2d78fc6-64b5-4071-ae06-4031cd8cedf6',
        #   createdAt:      '2024-05-14T21:25:09.491Z',
        #   updatedAt:      '2024-05-14T21:25:09.491Z',
        #   externalId:     '',
        #   organizationId: nil,
        #   categoryId:     nil,
        #   subject:        nil,
        #   note:           'Next up.',
        #   noteDate:       '2023-12-08T20:31:03.000Z',
        #   tags:           [],
        #   users:          [],
        #   account:        { id:                           '9e085d43-5204-4eff-8813-749e289a2485',
        #                     createdAt:                    '2024-05-10T15:37:51.762Z',
        #                     updatedAt:                    '2024-05-14T21:25:09.491Z',
        #                     externalId:                   '1',
        #                     name:                         "Joe's Garage",
        #                     traits:                       {},
        #                     organizationId:               nil,
        #                     accountOwnerId:               nil,
        #                     mrr:                          nil,
        #                     nextRenewalDate:              nil,
        #                     churnedAt:                    nil,
        #                     firstSeenTimestamp:           nil,
        #                     lastSeenTimestamp:            nil,
        #                     lastInboundMessageTimestamp:  '2024-05-13T21:18:41.000Z',
        #                     lastOutboundMessageTimestamp: nil,
        #                     trialEndDate:                 nil,
        #                     usersCount:                   7,
        #                     npsDetractorCount:            0,
        #                     npsPassiveCount:              0,
        #                     npsPromoterCount:             0,
        #                     npsScore:                     nil,
        #                     healthScore:                  nil,
        #                     csmId:                        nil,
        #                     accountExecutiveId:           nil },
        #   organization:   nil,
        #   author:         nil,
        #   category:       nil,
        #   archivedAt:     nil,
        #   accountId:      '9e085d43-5204-4eff-8813-749e289a2485',
        #   authorId:       nil,
        #   traits:         {}
        # }

        # delete a Vitally Note
        # vt_client.note_destroy()
        #   (opt) id: (Integer)
        def note_destroy(**args)
          reset_attributes
          @result = {}

          if args.dig(:id).blank?
            @message = 'Vitally note ID is required.'
            return @result
          end

          vitally_request(
            body:                  nil,
            error_message_prepend: 'Integrations::VitalLy::Notes.note_destroy',
            method:                'delete',
            params:                nil,
            default_result:        @result,
            url:                   "resources/notes/#{args[:id]}"
          )

          @success
        end
        # example result
        # true

        # create a new Vitally Note
        # vt_client.note_new()
        #   (req) account_id:  (String)
        #   (req) external_id: (Integer)
        #   (req) note:        (String)
        #   (req) created_at:  (DateTime)
        def note_new(**args)
          reset_attributes
          @result = []

          if args.dig(:account_id).blank?
            @message = 'Vitally account ID is required.'
            return @result
          elsif args.dig(:external_id).blank?
            @message = 'Vitally note external ID is required.'
            return @result
          elsif args.dig(:note).blank?
            @message = 'Note is required.'
            return @result
          elsif args.dig(:created_at).blank? || !args.dig(:created_at).respond_to?(:strftime)
            @message = 'Date note created is required.'
            return @result
          end

          body = {
            accountId:  args[:account_id].to_s,
            externalId: args[:external_id].to_s,
            note:       args[:note].to_s,
            noteDate:   args[:created_at].iso8601
          }

          vitally_request(
            body:,
            error_message_prepend: 'Integrations::VitalLy::Notes.note_new',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   'resources/notes'
          )

          @result
        end
        # example result
        # {
        #   id:             'c2d78fc6-64b5-4071-ae06-4031cd8cedf6',
        #   createdAt:      '2024-05-14T21:25:09.491Z',
        #   updatedAt:      '2024-05-14T21:25:09.491Z',
        #   externalId:     '',
        #   organizationId: nil,
        #   categoryId:     nil,
        #   subject:        nil,
        #   note:           'Next up.',
        #   noteDate:       '2023-12-08T20:31:03.000Z',
        #   tags:           [],
        #   users:          [],
        #   account:        { id:                           '9e085d43-5204-4eff-8813-749e289a2485',
        #                     createdAt:                    '2024-05-10T15:37:51.762Z',
        #                     updatedAt:                    '2024-05-14T21:25:09.491Z',
        #                     externalId:                   '1',
        #                     name:                         "Joe's Garage",
        #                     traits:                       {},
        #                     organizationId:               nil,
        #                     accountOwnerId:               nil,
        #                     mrr:                          nil,
        #                     nextRenewalDate:              nil,
        #                     churnedAt:                    nil,
        #                     firstSeenTimestamp:           nil,
        #                     lastSeenTimestamp:            nil,
        #                     lastInboundMessageTimestamp:  '2024-05-13T21:18:41.000Z',
        #                     lastOutboundMessageTimestamp: nil,
        #                     trialEndDate:                 nil,
        #                     usersCount:                   7,
        #                     npsDetractorCount:            0,
        #                     npsPassiveCount:              0,
        #                     npsPromoterCount:             0,
        #                     npsScore:                     nil,
        #                     healthScore:                  nil,
        #                     csmId:                        nil,
        #                     accountExecutiveId:           nil },
        #   organization:   nil,
        #   author:         nil,
        #   category:       nil,
        #   archivedAt:     nil,
        #   accountId:      '9e085d43-5204-4eff-8813-749e289a2485',
        #   authorId:       nil,
        #   traits:         {}
        # }

        # update an existing Vitally Note
        # vt_client.note_update()
        #   (req) external_id: (Integer)
        #     ~ or ~
        #   (req) id:          (Integer)
        #
        #   (opt) account_id:  (String)
        #   (opt) note:        (String)
        #   (opt) created_at:  (DateTime)
        def note_update(**args)
          reset_attributes
          @result = []

          if args.dig(:external_id).blank? && args.dig(:id).blank?
            @message = 'Vitally ID or external ID is required.'
            return @result
          end

          body = {}
          body[:accountId]  = args[:account_id].to_s if args.dig(:account_id).present?
          body[:externalId] = args[:external_id].to_s if args.dig(:external_id).present?
          body[:note]       = args[:note].to_s if args.dig(:note).present?
          body[:noteDate]   = args[:created_at].iso8601 if args.dig(:created_at).present?

          vitally_request(
            body:,
            error_message_prepend: 'Integrations::VitalLy::Notes.note_update',
            method:                'put',
            params:                nil,
            default_result:        @result,
            url:                   "resources/notes/#{args.dig(:id) || args.dig(:external_id)}"
          )

          @result
        end
        # example result
        # {
        #   id:             'c2d78fc6-64b5-4071-ae06-4031cd8cedf6',
        #   createdAt:      '2024-05-14T21:25:09.491Z',
        #   updatedAt:      '2024-05-14T21:36:51.196Z',
        #   externalId:     '7',
        #   organizationId: nil,
        #   categoryId:     nil,
        #   subject:        nil,
        #   note:           'Next up.',
        #   noteDate:       '2023-12-08T20:31:03.000Z',
        #   tags:           [],
        #   users:          [],
        #   account:        { id:                           '9e085d43-5204-4eff-8813-749e289a2485',
        #                     createdAt:                    '2024-05-10T15:37:51.762Z',
        #                     updatedAt:                    '2024-05-14T21:25:09.491Z',
        #                     externalId:                   '1',
        #                     name:                         "Joe's Garage",
        #                     traits:                       {},
        #                     organizationId:               nil,
        #                     accountOwnerId:               nil,
        #                     mrr:                          nil,
        #                     nextRenewalDate:              nil,
        #                     churnedAt:                    nil,
        #                     firstSeenTimestamp:           nil,
        #                     lastSeenTimestamp:            nil,
        #                     lastInboundMessageTimestamp:  '2024-05-13T21:18:41.000Z',
        #                     lastOutboundMessageTimestamp: nil,
        #                     trialEndDate:                 nil,
        #                     usersCount:                   7,
        #                     npsDetractorCount:            0,
        #                     npsPassiveCount:              0,
        #                     npsPromoterCount:             0,
        #                     npsScore:                     nil,
        #                     healthScore:                  nil,
        #                     csmId:                        nil,
        #                     accountExecutiveId:           nil },
        #   organization:   nil,
        #   author:         nil,
        #   category:       nil,
        #   archivedAt:     nil,
        #   accountId:      '9e085d43-5204-4eff-8813-749e289a2485',
        #   authorId:       nil,
        #   traits:         {}
        # }

        # get Vitally Notes for a specific Account
        # vt_client.notes()
        #   (req) account_id: (String)
        def notes(**args)
          reset_attributes

          if args.dig(:account_id).blank?
            @message = 'Vitally account ID is required.'
            return @result
          end

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
              error_message_prepend: 'Integrations::VitalLy::Notes.notes',
              method:                'get',
              params:,
              default_result:,
              url:                   "resources/accounts/#{args[:account_id]}/notes"
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
        # example result when no Notes exist in Vitally
        # {
        #   results: [],
        #   next:    null
        # }
        # example result when Notes exist in Vitally
        # {
        #   results: [
        #     {
        #       id:             'c2d78fc6-64b5-4071-ae06-4031cd8cedf6',
        #       createdAt:      '2024-05-14T21:25:09.491Z',
        #       updatedAt:      '2024-05-14T21:36:51.196Z',
        #       externalId:     '7',
        #       organizationId: nil,
        #       categoryId:     nil,
        #       subject:        nil,
        #       note:           'Next up.',
        #       noteDate:       '2023-12-08T20:31:03.000Z',
        #       tags:           [],
        #       users:          [],
        #       account:        { id:                           '9e085d43-5204-4eff-8813-749e289a2485',
        #                         createdAt:                    '2024-05-10T15:37:51.762Z',
        #                         updatedAt:                    '2024-05-14T21:25:09.491Z',
        #                         externalId:                   '1',
        #                         name:                         "Joe's Garage",
        #                         traits:                       {},
        #                         organizationId:               nil,
        #                         accountOwnerId:               nil,
        #                         mrr:                          nil,
        #                         nextRenewalDate:              nil,
        #                         churnedAt:                    nil,
        #                         firstSeenTimestamp:           nil,
        #                         lastSeenTimestamp:            nil,
        #                         lastInboundMessageTimestamp:  '2024-05-13T21:18:41.000Z',
        #                         lastOutboundMessageTimestamp: nil,
        #                         trialEndDate:                 nil,
        #                         usersCount:                   7,
        #                         npsDetractorCount:            0,
        #                         npsPassiveCount:              0,
        #                         npsPromoterCount:             0,
        #                         npsScore:                     nil,
        #                         healthScore:                  nil,
        #                         csmId:                        nil,
        #                         accountExecutiveId:           nil },
        #       organization:   nil,
        #       author:         nil,
        #       category:       nil,
        #       archivedAt:     nil,
        #       accountId:      '9e085d43-5204-4eff-8813-749e289a2485',
        #       authorId:       nil,
        #       traits:         {}
        #     },
        #     ...
        #   ]
        # }
      end
    end
  end
end
