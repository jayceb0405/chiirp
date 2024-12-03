# frozen_string_literal: true

# app/lib/friendly.rb
class Friendly
  # create a friendly date
  # Example: Friendly.new.date(Time.current, @client.time_zone, true)
  # Parameters:
  #   (req) time:         (Time) time to work from
  #   (req) time_zone:    (String) time zone to format date to
  #   (req) include_time: (Boolean) true - include the time
  #
  # rubocop:disable Style/OptionalBooleanParameter
  def date(time, time_zone, include_time = true, to_words = false)
    # rubocop:enable Style/OptionalBooleanParameter
    time         = (time.is_a?(Date) || time.is_a?(DateTime) || time.is_a?(Time) || time.is_a?(ActiveSupport::TimeWithZone) ? time : nil)
    time_zone    = (ActiveSupport::TimeZone.country_zones(:us).collect(&:name).include?(time_zone) ? time_zone : nil)
    day_string   = ''

    if time && time_zone
      # valid data was received

      Time.use_zone(time_zone) do
        time = time.in_time_zone(time_zone)
        current_days = ((Time.current.year - 1) * 365) + Time.current.yday
        created_days = ((time.year - 1) * 365) + time.yday

        day_string = case (current_days - created_days)
                     when -1
                       'Tomorrow'
                     when 0
                       'Today'
                     when 1
                       'Yesterday'
                     when 2..6
                       time.strftime('%A')
                     else
                       if to_words.to_bool
                         time.strftime('%A, %B %e, %Y')
                       else
                         time.strftime('%D')
                       end
                     end

        day_string += " (#{time.strftime('%l:%M %P').strip})" if include_time.to_bool
      end
    end

    day_string
  end

  # output a friendly duration
  def duration(duration, include_seconds = true)
    duration = duration.to_i
    hours    = (duration / 3600).to_i
    minutes  = ((duration % 3600) / 60).to_i
    seconds  = (duration % 60).to_i

    if include_seconds.to_bool
      hours > 0 ? "#{hours}h #{minutes}m #{seconds}s" : "#{minutes}m #{seconds}s"
    else
      hours > 0 ? "#{hours}h #{minutes}m" : "#{minutes}m"
    end
  end

  def fullname(firstname = '', lastname = '')
    "#{firstname || ''} #{lastname || ''}".strip
  end
end
