# frozen_string_literal: true

# app/lib/phone_number_reservations.rb
class PhoneNumberReservations
  attr_reader :phone_number

  # reserve a time slot in REDIS for the specified phone number
  # all times are in UTC

  # initialize RedisPool
  # PhoneNumberReservations.new(phone_number)
  def initialize(phone_number = '')
    @phone_number = phone_number.presence || 'undefined'
    @phone_number_reservations = default_phone_number_reservations
  end

  # normalize the seconds of a time to a number divisible by the interval
  def normalize_time(action_time, interval)
    action_time - action_time.sec + (interval * ((action_time.sec + interval - 1) / interval).seconds)
  end

  # release a reserved time
  def release(action_time, interval)
    normalized_time = normalize_time(action_time, interval)
    trimmed_reservations(normalized_time)
    @phone_number_reservations[:reservations] -= [normalized_time.strftime('%H:%M:%S')]
    update_reservations
  end

  # reserve a time slot for a phone number
  # PhoneNumberReservations.new(phone_number).reserve(Hash)
  # (req) action_time: (DateTime)
  # (opt) interval:    (Integer) seconds between actions (10)
  # (opt) time_zone:   (String) ('')
  # (opt) safe_start:  (Integer) seconds from midnight (0)
  # (opt) safe_end:    (Integer) seconds from midnight (1440)
  # (opt) safe_sun:    (Boolean) safe to send on Sunday (false)
  # (opt) safe_mon:    (Boolean) safe to send on Monday (true)
  # (opt) safe_tue:    (Boolean) safe to send on Tuesday (true)
  # (opt) safe_wed:    (Boolean) safe to send on Wednesday (true)
  # (opt) safe_thu:    (Boolean) safe to send on Thursday (true)
  # (opt) safe_fri:    (Boolean) safe to send on Friday (true)
  # (opt) safe_sat:    (Boolean) safe to send on Saturday (false)
  def reserve(args = {})
    acceptable_time = AcceptableTime.new(
      time_zone:  (args.dig(:time_zone) || 'Etc/UTC').to_s,
      safe_start: (args.dig(:safe_start) || 480).to_i,
      safe_end:   (args.dig(:safe_end) || 1200).to_i,
      safe_sun:   args.dig(:safe_sun).to_bool,
      safe_mon:   args.include?(:safe_mon) ? args[:safe_mon].to_bool : true,
      safe_tue:   args.include?(:safe_tue) ? args[:safe_tue].to_bool : true,
      safe_wed:   args.include?(:safe_wed) ? args[:safe_wed].to_bool : true,
      safe_thu:   args.include?(:safe_thu) ? args[:safe_thu].to_bool : true,
      safe_fri:   args.include?(:safe_fri) ? args[:safe_fri].to_bool : true,
      safe_sat:   args.dig(:safe_sat).to_bool,
      holidays:   args.dig(:holidays).is_a?(Hash) ? args[:holidays] : {}
    )

    next_reservation = next_available_reservation(args.dig(:action_time), (args.dig(:interval) || 10).to_i, acceptable_time)

    return nil if next_reservation.nil?

    trimmed_reservations(next_reservation)
    @phone_number_reservations[:reservations] << next_reservation.strftime('%H:%M:%S')
    update_reservations

    next_reservation
  end

  private

  def default_phone_number_reservations
    { reservation_date: '', reservations: [] }
  end

  def next_available_reservation(action_time, interval, acceptable_time)
    next_reservation = normalize_time(action_time, interval)
    next_reservation = acceptable_time.safe_time(next_reservation)

    return nil if next_reservation.nil?

    while reservation_taken?(next_reservation)
      next_reservation += interval.seconds
      next_reservation = acceptable_time.safe_time(next_reservation)
    end

    next_reservation
  end

  def reservation_lookup(action_time)
    action_date = action_time.strftime('%Y-%m-%d')

    if action_date.length == 10 && action_date == @phone_number_reservations[:reservation_date]
      # don't change @phone_number_reservations
    elsif action_date.length == 10
      @phone_number_reservations = { reservation_date: action_date, reservations: JSON.parse(RedisCloud.redis.get("phone_number_reservations:#{@phone_number}:#{action_date}").presence || '[]') }
    else
      @phone_number_reservations = default_phone_number_reservations
    end

    @phone_number_reservations[:reservations]
  end

  def reservation_taken?(action_time)
    reservation_lookup(action_time).include?(action_time.strftime('%H:%M:%S'))
  end

  def trimmed_reservations(action_time)
    reservation_lookup(action_time).delete_if { |x| action_time.change(hour: x.split(':').first.to_i, min: x.split(':').second.to_i, sec: x.split(':').last.to_i) < 10.seconds.ago }.sort
  end

  def time_to_live
    # 1 day beyond the reservation date
    (@phone_number_reservations[:reservation_date].to_time - Time.current).round + (24 * 60 * 60)
  end

  def update_reservations
    RedisCloud.redis.setex("phone_number_reservations:#{@phone_number}:#{@phone_number_reservations[:reservation_date]}", time_to_live, @phone_number_reservations[:reservations].to_json)
  end
end
