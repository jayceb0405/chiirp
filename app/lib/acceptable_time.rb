# frozen_string_literal: true

# app/lib/acceptable_time.rb
class AcceptableTime
  # determine a time in the future or past from a current date

  # vars used to advance time
  # vars not used to verify safe time period
  def initialize(args = {})
    @reverse       = args.dig(:reverse).to_bool
    @delay_months  = args.dig(:delay_months).to_i
    @delay_days    = args.dig(:delay_days).to_i
    @delay_hours   = args.dig(:delay_hours).to_i
    @delay_minutes = args.dig(:delay_minutes).to_i
    @ok2skip       = args.dig(:ok2skip).to_bool
    @holidays      = args.dig(:holidays).is_a?(Hash) ? args[:holidays] : {}

    # vars used to advance time
    # vars used to verify safe time period
    @time_zone     = args.dig(:time_zone).to_s
    @safe_start    = args.dig(:safe_start).to_i
    @safe_end      = args.dig(:safe_end).to_i
    @safe_days     = {
      0 => args.dig(:safe_sun).to_bool,
      1 => args.dig(:safe_mon).to_bool,
      2 => args.dig(:safe_tue).to_bool,
      3 => args.dig(:safe_wed).to_bool,
      4 => args.dig(:safe_thu).to_bool,
      5 => args.dig(:safe_fri).to_bool,
      6 => args.dig(:safe_sat).to_bool
    }

    # housekeeping variables
    @current_time      = args.dig(:current_time) || Time.current
    @schedule_advanced = false
    @time_direction    = @reverse ? -1 : 1
  end

  # advance action_time to the first available safe_day
  def adjust_for_safe_days(action_time)
    return nil if @safe_days.select { |_k, v| v == true }.keys.blank?

    unsafe_days    = @safe_days.select { |_k, v| v == false }.keys
    holiday_before = false

    while !action_time.nil? && (unsafe_days.include?(action_time.wday) || @holidays.key?(action_time.to_date))

      if unsafe_days.include?(action_time.wday) || @holidays.dig(action_time.to_date) == 'after'
        action_time = action_time.advance(days: holiday_before ? -1 : 1).change(hour: @safe_start.to_f / 60, min: @safe_start.to_f % 60)
      elsif @holidays.dig(action_time.to_date) == 'before'
        action_time = action_time.advance(days: -1).change(hour: @safe_start.to_f / 60, min: @safe_start.to_f % 60)
        holiday_before = true
      elsif @holidays.dig(action_time.to_date) == 'skip'
        action_time = nil
      else
        JsonLog.info 'AcceptableTime.adjust_for_safe_days-unexpected', { action_time:, unsafe_days:, holidays: @holidays }
        break
      end
    end

    action_time
  end

  # fit action_time within safe_start/safe_end window
  def adjust_for_safe_hours(action_time)
    window_min = action_time.change(hour: @safe_start.to_f / 60, min: @safe_start.to_f % 60)
    window_max = action_time.change(hour: @safe_end.to_f / 60, min: @safe_end.to_f % 60)

    if action_time < window_min
      action_time = window_min
    elsif action_time > window_max
      action_time = window_min.change(hour: window_min.strftime('%H').to_i, min: window_min.strftime('%M').to_i) + 1.day
    end

    action_time
  end

  def adjust_for_safe_range(action_time)
    self.adjust_for_safe_days(self.adjust_for_safe_hours(action_time))
  end

  def advance_days(action_time)
    if @delay_days.positive?
      action_time = action_time.advance(days: (@delay_days * @time_direction))
      @schedule_advanced = true
    end

    action_time
  end

  def advance_hours(action_time)
    if @delay_hours.positive?
      action_time = action_time.advance(hours: (@delay_hours * @time_direction))
      @schedule_advanced = true
    end

    action_time
  end

  def advance_minutes(action_time)
    if @delay_minutes.to_i.positive?
      action_time = action_time.advance(minutes: (@delay_minutes * @time_direction))
      @schedule_advanced = true
    end

    action_time
  end

  def advance_months(action_time)
    if @delay_months.positive?
      action_time = action_time.advance(months: (@delay_months * @time_direction))
      @schedule_advanced = true
    end

    action_time
  end

  def new_time(start_time)
    action_time = self.localize_action_time(self.new_time_advance(start_time))

    # rubocop:disable Lint/DuplicateBranch
    if @reverse && action_time.advance(seconds: 1) < @current_time.in_time_zone(@time_zone)
      # do not process action for the past if in reverse (added 1 second to action_time to compensate for processing time)
      action_time = nil
    elsif action_time < (@current_time.in_time_zone(@time_zone) - 1.hour)
      # do not process action if in the past by more than 1 hour
      action_time = nil
    else
      # ensure action_time is not in the past
      action_time = @current_time.in_time_zone(@time_zone) if action_time < @current_time.in_time_zone(@time_zone)

      # if appointment Campaign and no schedule was found set time to now (NOT target date)
      action_time = @current_time.in_time_zone(@time_zone) if @reverse && !@schedule_advanced

      orig_action_time = action_time
      action_time      = self.safe_time(action_time)

      # stop all actions scheduled for after the target time if in reverse
      action_time = nil if @reverse && action_time.present? && action_time > start_time

      if orig_action_time != action_time && @ok2skip
        # the action time had to be changed to fit within acceptable days/times
        # ok 2 skip Triggeraction if not within acceptable days/times
        action_time = nil
      end
      # rubocop:enable Lint/DuplicateBranch
    end

    action_time&.utc
  end

  def new_time_advance(action_time)
    @schedule_advanced = false

    action_time = self.localize_action_time(action_time)
    action_time = self.advance_months(action_time)
    action_time = self.advance_days(action_time)
    action_time = self.advance_hours(action_time)
    action_time = self.advance_minutes(action_time)

    action_time.utc
  end

  def safe_time(action_time)
    self.adjust_for_safe_range(self.localize_action_time(action_time))&.utc
  end

  def safe_time?(action_time)
    action_time = self.localize_action_time(action_time)
    (action_time == self.safe_time(action_time))
  end

  private

  def localize_action_time(action_time)
    action_time = @current_time unless action_time.is_a?(Time)
    action_time.in_time_zone(@time_zone)
  end
end
