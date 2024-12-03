# frozen_string_literal: true

# app/models/Integration/vitally/v2024/notes.rb
module Integration
  module Vitally
    module V2024
      module Notes
        # get a Vitally Note
        # vt_model.note()
        #   (req) note_id: (Integer)
        def note(note_id)
          reset_attributes

          unless note_id.to_i.positive? && (note = Clients::Note.find_by(id: note_id))
            @message = 'Note ID is required.'
            return @success
          end

          @vt_client.note(external_id: note.id)

          update_attributes_from_client

          @result
        end
        # example result when note is not found in Vitally:
        # {}
        # example result when note is found in Vitally:
        # {
        #   id:             '186e3536-0bdc-424c-ac61-65e379d0687b',
        #   createdAt:      '2024-05-15T14:47:54.442Z',
        #   updatedAt:      '2024-05-15T14:47:54.442Z',
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
        #                     updatedAt:                    '2024-05-15T14:47:54.442Z',
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
        # vt_model.note_destroy()
        #   (req) note_id: (Integer)
        def note_destroy(note_id)
          reset_attributes

          unless note_id.present? && (note = Clients::Note.find_by(id: note_id))
            @message = 'Note ID is required.'
            return @success
          end

          if (vt_note = note(note.id)).blank?
            @message = 'Vitally user not found.'
            return @success
          end

          @vt_client.note_destroy(id: vt_note.dig(:id))

          @success
        end
        # example result after unsuccessful deletion:
        # {}
        # example result after successful deletion:
        # {
        #   id:             '186e3536-0bdc-424c-ac61-65e379d0687b',
        #   createdAt:      '2024-05-15T14:47:54.442Z',
        #   updatedAt:      '2024-05-15T15:10:53.878Z',
        #   externalId:     '7',
        #   organizationId: nil,
        #   categoryId:     nil,
        #   subject:        nil,
        #   note:           "Next up. Let's get going.",
        #   noteDate:       '2023-12-08T20:31:03.000Z',
        #   tags:           [],
        #   users:          [],
        #   account:        { id:                           '9e085d43-5204-4eff-8813-749e289a2485',
        #                     createdAt:                    '2024-05-10T15:37:51.762Z',
        #                     updatedAt:                    '2024-05-15T14:47:54.442Z',
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

        # vt_model.note_found?()
        #   (req) note_id: (Integer)
        def note_found?(note_id)
          reset_attributes
          note(note_id)

          @success
        end
        # example result when not found:
        # {}
        # example result when found:

        # push Note data to Vitally
        # vt_model.note_push()
        #   (req) note_id: (Integer)
        def note_push(note_id)
          reset_attributes

          unless note_id.present? && (note = Clients::Note.find_by(id: note_id))
            @message = 'Note ID is required.'
            return @success
          end

          if (vt_account = @vt_client.account(note.client_id)).blank?
            @vt_client.account_new(client_id: note.client_id, name: note.client.name)

            if @vt_client.success?
              vt_account = @vt_client.result
            else
              @message = 'Vitally account not found.'
              return @success
            end
          end

          if (vt_note = note(note.id)).present?
            @vt_client.note_update(
              id:          vt_note.dig(:id),
              account_id:  vt_account.dig(:id),
              external_id: note.id,
              note:        note.note,
              created_at:  note.created_at
            )
          else
            @vt_client.note_new(
              account_id:  vt_account.dig(:id),
              external_id: note.id,
              note:        note.note,
              created_at:  note.created_at
            )
          end

          update_attributes_from_client

          @success
        end
        # example result after unsuccessful push:
        # {}
        # example result after successful push:
        # {
        #   id:             '186e3536-0bdc-424c-ac61-65e379d0687b',
        #   createdAt:      '2024-05-15T14:47:54.442Z',
        #   updatedAt:      '2024-05-15T14:47:54.442Z',
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
        #                     updatedAt:                    '2024-05-15T14:47:54.442Z',
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

        def notes(client_id)
          reset_attributes
          @result = []

          @vt_client.account(client_id)

          if @vt_client.success? && @vt_client.result.dig(:id).present?
            @vt_client.notes(account_id: @vt_client.result[:id])

            update_attributes_from_client

            @result = @result.dig(:results) if @success && @result.dig(:results).present?
          end

          @result
        end
        # [
        #   {
        #     id:             '186e3536-0bdc-424c-ac61-65e379d0687b',
        #     createdAt:      '2024-05-15T14:47:54.442Z',
        #     updatedAt:      '2024-05-15T14:47:54.442Z',
        #     externalId:     '7',
        #     organizationId: nil,
        #     categoryId:     nil,
        #     subject:        nil,
        #     note:           'Next up.',
        #     noteDate:       '2023-12-08T20:31:03.000Z',
        #     tags:           [],
        #     users:          [],
        #     account:        { id:                           '9e085d43-5204-4eff-8813-749e289a2485',
        #                       createdAt:                    '2024-05-10T15:37:51.762Z',
        #                       updatedAt:                    '2024-05-15T14:47:54.442Z',
        #                       externalId:                   '1',
        #                       name:                         "Joe's Garage",
        #                       traits:                       {},
        #                       organizationId:               nil,
        #                       accountOwnerId:               nil,
        #                       mrr:                          nil,
        #                       nextRenewalDate:              nil,
        #                       churnedAt:                    nil,
        #                       firstSeenTimestamp:           nil,
        #                       lastSeenTimestamp:            nil,
        #                       lastInboundMessageTimestamp:  '2024-05-13T21:18:41.000Z',
        #                       lastOutboundMessageTimestamp: nil,
        #                       trialEndDate:                 nil,
        #                       usersCount:                   7,
        #                       npsDetractorCount:            0,
        #                       npsPassiveCount:              0,
        #                       npsPromoterCount:             0,
        #                       npsScore:                     nil,
        #                       healthScore:                  nil,
        #                       csmId:                        nil,
        #                       accountExecutiveId:           nil },
        #     organization:   nil,
        #     author:         nil,
        #     category:       nil,
        #     archivedAt:     nil,
        #     accountId:      '9e085d43-5204-4eff-8813-749e289a2485',
        #     authorId:       nil,
        #     traits:         {}
        #   },
        #   ...
        # ]
      end
    end
  end
end
