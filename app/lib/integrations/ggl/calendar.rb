# frozen_string_literal: true

# app/lib/integrations/ggl/calendar.rb
module Integrations
  module Ggl
    # process various API calls to Google Calendar
    class Calendar < Integrations::Ggl::Base
      class CalendarError < StandardError; end

      # ggl_client.calendar_list
      def calendar_list
        @error     = 0
        @message   = ''
        @new_token = nil
        @result    = []
        @success   = false

        return if @token.blank?

        begin
          retries ||= 0

          google_result = google_service.list_calendar_lists
          @result       = (google_result&.items || []).map(&:to_h)
          @success      = true
        rescue StandardError => e
          if e.status_code.to_i == 401 && (retries += 1) < 3
            @token     = refresh_access_token
            @new_token = @token
            retry if @token.present?
          elsif e.status_code.to_i == 403
            JsonLog.info 'Integrations::Ggl::Calendar.calendar_list', { token: @token, permissions: 'insufficient' }
          else
            @error   = e.status_code
            @message = "GoogleCalendar::CalendarList::StandardError: #{e.message}"

            e.set_backtrace(BC.new.clean(caller))

            Appsignal.report_error(e) do |transaction|
              # Only needed if it needs to be different or there's no active transaction from which to inherit it
              Appsignal.set_action('Integrations::Ggl::Calendar.calendar_list')

              Appsignal.set_tags(
                error_level: 'info',
                error_code:  @error
              )
              Appsignal.add_custom_data(
                e_full_message: e.full_message,
                e_methods:      e.public_methods.inspect,
                google_result:  defined?(google_result) ? google_result : 'Undefined',
                message:        @message,
                result:         @result,
                retries:,
                success:        @success,
                file:           __FILE__,
                line:           __LINE__
              )
            end
          end
        end

        @result
      end

      # ggl_client.event_add(calendar_id: String, title: String, start_utc: DateTime, end_utc: dateTime)
      def event_add(args = {})
        attendee_emails = [args.dig(:attendee_emails)].flatten
        calendar_id     = args.dig(:calendar_id).to_s
        description     = args.dig(:description).to_s
        location        = args.dig(:location).to_s
        recurrence      = args.dig(:recurrence).to_s
        title           = args.dig(:title).to_s
        start_utc       = args.dig(:start_utc)
        end_utc         = args.dig(:end_utc) || start_utc

        @error          = 0
        @message        = ''
        @new_token      = nil
        @result         = {}
        @success        = false

        return if @token.blank?

        if calendar_id.blank?
          @message = 'Calendar ID is required.'

          return @result
        elsif title.blank?
          @message = 'Event title is required.'

          return @result
        elsif !start_utc.respond_to?(:iso8601)
          @message = 'Event Start date is invalid.'

          return @result
        end

        end_utc = start_utc + 1.hour unless end_utc.respond_to?(:iso8601)

        event = ::Google::Apis::CalendarV3::Event.new(
          summary:     title,
          location:,
          description:
          # reminders: ::Google::Apis::CalendarV3::Event::Reminders.new(
          #   use_default: false,
          #   overrides: [
          #     ::Google::Apis::CalendarV3::EventReminder.new(
          #       reminder_method: 'email',
          #       minutes: 24 * 60
          #     ),
          #     ::Google::Apis::CalendarV3::EventReminder.new(
          #       reminder_method: 'popup',
          #       minutes: 10
          #     )
          #   ]
          # )
        )

        event.start      = start_utc.is_a?(Date) ? ::Google::Apis::CalendarV3::EventDateTime.new(date: start_utc.iso8601, time_zone: 'Etc/GMT') : ::Google::Apis::CalendarV3::EventDateTime.new(date_time: start_utc.iso8601, time_zone: 'Etc/GMT')
        event.end        = end_utc.is_a?(Date)   ? ::Google::Apis::CalendarV3::EventDateTime.new(date: end_utc.iso8601, time_zone: 'Etc/GMT')   : ::Google::Apis::CalendarV3::EventDateTime.new(date_time: end_utc.iso8601, time_zone: 'Etc/GMT')
        event.recurrence = ['RRULE:FREQ=YEARLY'] if recurrence == 'annually'

        if attendee_emails.present?
          event.attendees = []

          attendee_emails.each do |attendee_email|
            event.attendees << ::Google::Apis::CalendarV3::EventAttendee.new(email: attendee_email)
          end
        end

        begin
          retries ||= 0

          google_result = google_service.insert_event(calendar_id, event)
          @result       = {
            id:     google_result.id,
            link:   google_result.html_link,
            status: google_result.status
          }
          @success = @result[:status].casecmp?('confirmed')
        rescue StandardError => e
          if e.status_code.to_i == 401 && (retries += 1) < 3
            @token = refresh_access_token
            @new_token = @token
            retry if @token.present?
          else
            @error   = e.status_code
            @message = "GoogleCalendar::EventAdd::StandardError: #{e.message}"

            e.set_backtrace(BC.new.clean(caller))

            Appsignal.report_error(e) do |transaction|
              # Only needed if it needs to be different or there's no active transaction from which to inherit it
              Appsignal.set_action('Integrations::Ggl::Calendar.event_add')

              # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
              Appsignal.add_params(args)

              Appsignal.set_tags(
                error_level: 'info',
                error_code:  @error
              )
              Appsignal.add_custom_data(
                calendar_id:,
                description:,
                e_full_message: e.full_message,
                e_methods:      e.public_methods.inspect,
                end_utc:,
                google_result:  defined?(google_result) ? google_result : 'Undefined',
                location:,
                message:        @message,
                result:         @result,
                retries:,
                start_utc:,
                success:        @success,
                title:,
                file:           __FILE__,
                line:           __LINE__
              )
            end
          end
        end

        @result
      end

      # ggl_client.event_delete(calendar_id: String, event_id: String)
      def event_delete(args = {})
        calendar_id = args.dig(:calendar_id).to_s
        event_id    = args.dig(:event_id).to_s
        @error      = 0
        @message    = ''
        @new_token  = nil
        @result     = []
        @success    = false

        return if @token.blank?

        if calendar_id.blank?
          @message = 'Calendar ID is required.'

          return @result
        elsif event_id.blank?
          @message = 'Event ID is required.'

          return @result
        end

        begin
          retries ||= 0

          google_result = google_service.delete_event(calendar_id, event_id)

          if google_result.blank?
            @success = true
          else
            @message = 'GoogleCalendar::EventDelete::StandardError: Unable to delete!'

            error = CalendarError.new(@message)
            error.set_backtrace(BC.new.clean(caller))

            Appsignal.report_error(error) do |transaction|
              # Only needed if it needs to be different or there's no active transaction from which to inherit it
              Appsignal.set_action('Integrations::Ggl::Calendar.event_delete')

              # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
              Appsignal.add_params(args)

              Appsignal.set_tags(
                error_level: 'info',
                error_code:  @error
              )
              Appsignal.add_custom_data(
                calendar_id:,
                event_id:,
                google_result: defined?(google_result) ? google_result : 'Undefined',
                result:        @result,
                retries:,
                success:       @success,
                file:          __FILE__,
                line:          __LINE__
              )
            end
          end
        rescue StandardError => e
          if e.status_code.to_i == 401 && (retries += 1) < 3
            @token = refresh_access_token
            @new_token = @token
            retry if @token.present?
          else
            @error   = e.status_code
            @message = "GoogleCalendar::EventDelete::StandardError: #{e.message}"

            e.set_backtrace(BC.new.clean(caller))

            Appsignal.report_error(e) do |transaction|
              # Only needed if it needs to be different or there's no active transaction from which to inherit it
              Appsignal.set_action('Integrations::Ggl::Calendar.event_delete')

              # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
              Appsignal.add_params(args)

              Appsignal.set_tags(
                error_level: 'info',
                error_code:  @error
              )
              Appsignal.add_custom_data(
                calendar_id:,
                event_id:,
                e:,
                e_full_message: e.full_message,
                e_methods:      e.public_methods.inspect,
                google_result:  defined?(google_result) ? google_result : 'Undefined',
                message:        @message,
                result:         @result,
                retries:,
                success:        @success,
                file:           __FILE__,
                line:           __LINE__
              )
            end
          end
        end

        @success
      end

      # ggl_client.event_list(calendar_id: String, start_date: DateTime, end_date: DateTime)
      def event_list(args = {})
        calendar_id = args.dig(:calendar_id).to_s
        start_date  = args.dig(:start_date) || Time.current
        end_date    = args.dig(:end_date)

        @error      = 0
        @message    = ''
        @new_token  = nil
        @result     = []
        @success    = false

        if @token.blank?
          @message = 'Google token must be defined.'
          return @result
        elsif calendar_id.blank?
          @message = 'Google calendar ID must be defined.'
          return @result
        elsif !start_date.respond_to?(:iso8601)
          @message = 'Event Start date must be valid.'
          return @result
        elsif !end_date.respond_to?(:iso8601)
          end_date = start_date.end_of_month
        end

        begin
          retries         ||= 0
          next_page_token   = ''
          @result           = []

          loop do
            google_result   = google_service.list_events(calendar_id.to_s,
                                                         max_results:   50,
                                                         single_events: true,
                                                         order_by:      'startTime',
                                                         time_min:      start_date.iso8601,
                                                         time_max:      end_date.iso8601,
                                                         page_token:    next_page_token)
            @result        += (google_result&.items || []).map(&:to_h)
            next_page_token = google_result&.next_page_token.to_s

            break if next_page_token.blank?
          end

          @success = true
        rescue StandardError => e
          if e.status_code.to_i == 401 && (retries += 1) < 3
            @token     = refresh_access_token
            @new_token = @token
            retry if @token.present?
          elsif e.status_code.to_i == 403
            Rails.logger.info "Integrations::Ggl::Calendar.event_list: #{{ calendar_id:, token: @token, existing_calendar_ids: self.calendar_list.map { |c| c.dig(:id) }, message: e.message }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
          elsif e.status_code.to_i == 404
            Rails.logger.info "Integrations::Ggl::Calendar.event_list: #{{ calendar_id:, token: @token, existing_calendar_ids: self.calendar_list.map { |c| c.dig(:id) }, message: e.message }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
          else
            @error_code = e.status_code
            @message    = "GoogleCalendar::EventList::StandardError: #{e.message}"

            e.set_backtrace(BC.new.clean(caller))

            Appsignal.report_error(e) do |transaction|
              # Only needed if it needs to be different or there's no active transaction from which to inherit it
              Appsignal.set_action('Integrations::Ggl::Calendar.event_list')

              # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
              Appsignal.add_params(args)

              Appsignal.set_tags(
                error_level: 'info',
                error_code:  @error
              )
              Appsignal.add_custom_data(
                calendar_id:,
                e:,
                e_full_message: e.full_message,
                e_methods:      e.public_methods.inspect,
                end_date:,
                google_result:  defined?(google_result) ? google_result : 'Undefined',
                message:        @message,
                result:         @result,
                retries:,
                start_date:,
                success:        @success,
                file:           __FILE__,
                line:           __LINE__
              )
            end
          end
        end

        @result
      end

      # ggl_client.event_list_for_calendar(calendar_id: String, start_date: DateTime, end_date: DateTime)
      def event_list_for_calendar(args = {})
        self.event_list(args)

        @result = @result.map { |event| { id: event[:id], title: event[:summary], start: event.dig(:start, :date) || event.dig(:start, :date_time), end: event.dig(:end, :date) || event.dig(:end, :date_time) } } if @success

        @result
      end
    end
  end
end
