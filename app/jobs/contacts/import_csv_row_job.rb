# frozen_string_literal: true

module Contacts
  class ImportCsvRowJob < ApplicationJob
    # import a Contact row from a CSV file
    # Contacts::ImportCsvRowJob.set(wait_until: 1.day.from_now).perform_later()
    # Contacts::ImportCsvRowJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()
    #  (req) batch_rows
    #  (req) overwrite
    #  (req) user_id
    #  (req) group_id
    #  (req) tag_id
    #  (req) current_user_id
    #  (req) header_fields
    def initialize(**args)
      super

      @process          = (args.dig(:process).presence || 'csv_import').to_s
      @reschedule_secs  = 0
    end

    def perform(**args)
      super

      current_user = User.find_by(id: args.dig(:current_user_id).to_i)
      return unless current_user

      current_user.client.csv_row_process(
        batch_rows:      args.dig(:batch_rows),
        overwrite:       args.dig(:overwrite),
        user_id:         args.dig(:user_id),
        group_id:        args.dig(:group_id),
        tag_id:          args.dig(:tag_id),
        current_user_id: current_user.id,
        header_fields:   args.dig(:header_fields)
      )
    end
  end
end
