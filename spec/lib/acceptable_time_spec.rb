# frozen_string_literal: true

# spec/lib/acceptable_time_spec.rb
# foreman run bundle exec rspec spec/lib/acceptable_time_spec.rb
require 'rails_helper'

describe AcceptableTime, :special do
  describe 'Library: AcceptableTime (begin on date/NO constraints/NO holidays)' do
    # no constraints
    let(:action_time) { Time.current.round(0).advance(days: 1) }
    let(:acceptable_time) do
      AcceptableTime.new(
        time_zone:     'Eastern Time (US & Canada)',
        reverse:       false,
        delay_months:  0,
        delay_days:    0,
        delay_hours:   0,
        delay_minutes: 0,
        safe_start:    0,
        safe_end:      1440,
        safe_sun:      true,
        safe_mon:      true,
        safe_tue:      true,
        safe_wed:      true,
        safe_thu:      true,
        safe_fri:      true,
        safe_sat:      true,
        holidays:      {},
        ok2skip:       false
      )
    end

    it 'Test AcceptableTime.advance_months' do
      expect(acceptable_time.advance_months(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_days' do
      expect(acceptable_time.advance_days(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_hours' do
      expect(acceptable_time.advance_hours(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_minutes' do
      expect(acceptable_time.advance_minutes(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.new_time' do
      expect(acceptable_time.new_time(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.new_time_advance' do
      expect(acceptable_time.new_time_advance(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.safe_time' do
      expect(acceptable_time.safe_time(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.safe_time?' do
      expect(acceptable_time.safe_time?(action_time)).to eq(true)
    end
  end

  describe 'Library: AcceptableTime (begin on date/NO constraints/holidays forward)' do
    around do |example|
      Timecop.freeze(Time.zone.parse('2022-01-02 00:00:00 AM EST')) { example.run }
    end

    # no constraints
    let(:action_time) { Time.current.round(0).advance(days: 1) }
    let(:action_time_advanced) { action_time.advance(days: 1).change(hour: 5) }
    let(:acceptable_time) do
      AcceptableTime.new(
        time_zone:     'Eastern Time (US & Canada)',
        reverse:       false,
        delay_months:  0,
        delay_days:    0,
        delay_hours:   0,
        delay_minutes: 0,
        safe_start:    0,
        safe_end:      1440,
        safe_sun:      true,
        safe_mon:      true,
        safe_tue:      true,
        safe_wed:      true,
        safe_thu:      true,
        safe_fri:      true,
        safe_sat:      true,
        holidays:      { action_time.to_date => 'forward' },
        ok2skip:       false
      )
    end

    it 'Test AcceptableTime.advance_months' do
      expect(acceptable_time.advance_months(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_days' do
      expect(acceptable_time.advance_days(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_hours' do
      expect(acceptable_time.advance_hours(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_minutes' do
      expect(acceptable_time.advance_minutes(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.new_time' do
      expect(acceptable_time.new_time(action_time)).to eq(action_time_advanced)
    end

    it 'Test AcceptableTime.new_time_advance' do
      expect(acceptable_time.new_time_advance(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.safe_time' do
      expect(acceptable_time.safe_time(action_time)).to eq(action_time_advanced)
    end

    it 'Test AcceptableTime.safe_time?' do
      expect(acceptable_time.safe_time?(action_time)).to eq(false)
    end
  end

  describe 'Library: AcceptableTime (begin on date/NO constraints/holidays backward)' do
    # no constraints
    action_time = Time.current.round(0).advance(days: 1)
    action_time_advanced = action_time.advance(days: -1).change(hour: 5)
    acceptable_time = AcceptableTime.new(
      time_zone:     'Eastern Time (US & Canada)',
      reverse:       false,
      delay_months:  0,
      delay_days:    0,
      delay_hours:   0,
      delay_minutes: 0,
      safe_start:    0,
      safe_end:      1440,
      safe_sun:      true,
      safe_mon:      true,
      safe_tue:      true,
      safe_wed:      true,
      safe_thu:      true,
      safe_fri:      true,
      safe_sat:      true,
      holidays:      { action_time.to_date => 'backward' },
      ok2skip:       false
    )

    it 'Test AcceptableTime.advance_months' do
      expect(acceptable_time.advance_months(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_days' do
      expect(acceptable_time.advance_days(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_hours' do
      expect(acceptable_time.advance_hours(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_minutes' do
      expect(acceptable_time.advance_minutes(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.new_time' do
      expect(acceptable_time.new_time(action_time)).to eq(action_time_advanced)
    end

    it 'Test AcceptableTime.new_time_advance' do
      expect(acceptable_time.new_time_advance(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.safe_time' do
      expect(acceptable_time.safe_time(action_time)).to eq(action_time_advanced)
    end

    it 'Test AcceptableTime.safe_time?' do
      expect(acceptable_time.safe_time?(action_time)).to eq(false)
    end
  end

  describe 'Library: AcceptableTime (begin on date/target time: 8:00am, safe times: 8:00am - 8:00pm/NO holidays)' do
    # target time: 8:00am
    # safe times:  8:00am to 8:00pm
    action_time = Time.current.round(0).in_time_zone('Eastern Time (US & Canada)').advance(days: 1).change(hour: 8).utc
    acceptable_time = AcceptableTime.new(
      time_zone:     'Eastern Time (US & Canada)',
      reverse:       false,
      delay_months:  0,
      delay_days:    0,
      delay_hours:   0,
      delay_minutes: 0,
      safe_start:    480,
      safe_end:      1200,
      safe_sun:      true,
      safe_mon:      true,
      safe_tue:      true,
      safe_wed:      true,
      safe_thu:      true,
      safe_fri:      true,
      safe_sat:      true,
      holidays:      {},
      ok2skip:       false
    )

    it 'Test AcceptableTime.advance_months' do
      expect(acceptable_time.advance_months(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_days' do
      expect(acceptable_time.advance_days(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_hours' do
      expect(acceptable_time.advance_hours(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_minutes' do
      expect(acceptable_time.advance_minutes(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.new_time' do
      expect(acceptable_time.new_time(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.new_time_advance' do
      expect(acceptable_time.new_time_advance(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.safe_time' do
      expect(acceptable_time.safe_time(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.safe_time?' do
      expect(acceptable_time.safe_time?(action_time)).to eq(true)
    end
  end

  describe 'Library: AcceptableTime (begin on date/target time: 8:00am, safe times: 8:00am - 8:00pm/holidays forward)' do
    # target time: 8:00am
    # safe times:  8:00am to 8:00pm
    action_time = Time.current.round(0).in_time_zone('Eastern Time (US & Canada)').advance(days: 1).change(hour: 8).utc
    action_time_advanced = action_time.advance(days: 1)
    acceptable_time = AcceptableTime.new(
      time_zone:     'Eastern Time (US & Canada)',
      reverse:       false,
      delay_months:  0,
      delay_days:    0,
      delay_hours:   0,
      delay_minutes: 0,
      safe_start:    480,
      safe_end:      1200,
      safe_sun:      true,
      safe_mon:      true,
      safe_tue:      true,
      safe_wed:      true,
      safe_thu:      true,
      safe_fri:      true,
      safe_sat:      true,
      holidays:      { action_time.to_date => 'forward' },
      ok2skip:       false
    )

    it 'Test AcceptableTime.advance_months' do
      expect(acceptable_time.advance_months(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_days' do
      expect(acceptable_time.advance_days(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_hours' do
      expect(acceptable_time.advance_hours(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_minutes' do
      expect(acceptable_time.advance_minutes(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.new_time' do
      expect(acceptable_time.new_time(action_time)).to eq(action_time_advanced)
    end

    it 'Test AcceptableTime.new_time_advance' do
      expect(acceptable_time.new_time_advance(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.safe_time' do
      expect(acceptable_time.safe_time(action_time)).to eq(action_time_advanced)
    end

    it 'Test AcceptableTime.safe_time?' do
      expect(acceptable_time.safe_time?(action_time)).to eq(false)
    end
  end

  describe 'Library: AcceptableTime (begin on date/target time: 8:00am, safe times: 8:00am - 8:00pm/holidays backward)' do
    # target time: 8:00am
    # safe times:  8:00am to 8:00pm
    action_time = Time.current.round(0).in_time_zone('Eastern Time (US & Canada)').advance(days: 1).change(hour: 8).utc
    action_time_advanced = action_time.in_time_zone('Eastern Time (US & Canada)').advance(days: -1).change(hour: 8).utc
    acceptable_time = AcceptableTime.new(
      time_zone:     'Eastern Time (US & Canada)',
      reverse:       false,
      delay_months:  0,
      delay_days:    0,
      delay_hours:   0,
      delay_minutes: 0,
      safe_start:    480,
      safe_end:      1200,
      safe_sun:      true,
      safe_mon:      true,
      safe_tue:      true,
      safe_wed:      true,
      safe_thu:      true,
      safe_fri:      true,
      safe_sat:      true,
      holidays:      { action_time.to_date => 'backward' },
      ok2skip:       false
    )

    it 'Test AcceptableTime.advance_months' do
      expect(acceptable_time.advance_months(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_days' do
      expect(acceptable_time.advance_days(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_hours' do
      expect(acceptable_time.advance_hours(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_minutes' do
      expect(acceptable_time.advance_minutes(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.new_time' do
      expect(acceptable_time.new_time(action_time)).to eq(action_time_advanced)
    end

    it 'Test AcceptableTime.new_time_advance' do
      expect(acceptable_time.new_time_advance(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.safe_time' do
      expect(acceptable_time.safe_time(action_time)).to eq(action_time_advanced)
    end

    it 'Test AcceptableTime.safe_time?' do
      expect(acceptable_time.safe_time?(action_time)).to eq(false)
    end
  end

  describe 'Library: AcceptableTime (begin on date/target time: 3:00am, safe times: 8:00am - 8:00pm/NO holidays)' do
    # target time: 3:00am
    # safe times:  8:00am to 8:00pm
    action_time = Time.current.round(0).in_time_zone('Eastern Time (US & Canada)').advance(days: 1).change(hour: 3).utc
    action_time_advanced = action_time.in_time_zone('Eastern Time (US & Canada)').advance(hours: 5).utc
    acceptable_time = AcceptableTime.new(
      time_zone:     'Eastern Time (US & Canada)',
      reverse:       false,
      delay_months:  0,
      delay_days:    0,
      delay_hours:   0,
      delay_minutes: 0,
      safe_start:    480,
      safe_end:      1200,
      safe_sun:      true,
      safe_mon:      true,
      safe_tue:      true,
      safe_wed:      true,
      safe_thu:      true,
      safe_fri:      true,
      safe_sat:      true,
      holidays:      {},
      ok2skip:       false
    )

    it 'Test AcceptableTime.advance_months' do
      expect(acceptable_time.advance_months(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_days' do
      expect(acceptable_time.advance_days(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_hours' do
      expect(acceptable_time.advance_hours(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_minutes' do
      expect(acceptable_time.advance_minutes(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.new_time' do
      expect(acceptable_time.new_time(action_time)).to eq(action_time_advanced)
    end

    it 'Test AcceptableTime.new_time_advance' do
      expect(acceptable_time.new_time_advance(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.safe_time' do
      expect(acceptable_time.safe_time(action_time)).to eq(action_time_advanced)
    end

    it 'Test AcceptableTime.safe_time?' do
      expect(acceptable_time.safe_time?(action_time)).to eq(false)
    end
  end

  describe 'Library: AcceptableTime (begin on date/target time: 3:00am, safe times: 8:00am - 8:00pm/holidays forward)' do
    # target time: 3:00am
    # safe times:  8:00am to 8:00pm
    action_time = Time.current.round(0).in_time_zone('Eastern Time (US & Canada)').advance(days: 1).change(hour: 3).utc
    action_time_advanced = action_time.in_time_zone('Eastern Time (US & Canada)').advance(hours: 5).advance(days: 1).utc
    acceptable_time = AcceptableTime.new(
      time_zone:     'Eastern Time (US & Canada)',
      reverse:       false,
      delay_months:  0,
      delay_days:    0,
      delay_hours:   0,
      delay_minutes: 0,
      safe_start:    480,
      safe_end:      1200,
      safe_sun:      true,
      safe_mon:      true,
      safe_tue:      true,
      safe_wed:      true,
      safe_thu:      true,
      safe_fri:      true,
      safe_sat:      true,
      holidays:      { action_time.to_date => 'forward' },
      ok2skip:       false
    )

    it 'Test AcceptableTime.advance_months' do
      expect(acceptable_time.advance_months(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_days' do
      expect(acceptable_time.advance_days(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_hours' do
      expect(acceptable_time.advance_hours(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_minutes' do
      expect(acceptable_time.advance_minutes(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.new_time' do
      expect(acceptable_time.new_time(action_time)).to eq(action_time_advanced)
    end

    it 'Test AcceptableTime.new_time_advance' do
      expect(acceptable_time.new_time_advance(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.safe_time' do
      expect(acceptable_time.safe_time(action_time)).to eq(action_time_advanced)
    end

    it 'Test AcceptableTime.safe_time?' do
      expect(acceptable_time.safe_time?(action_time)).to eq(false)
    end
  end

  describe 'Library: AcceptableTime (begin on date/target time: 3:00am, safe times: 8:00am - 8:00pm/holidays backward)' do
    # target time: 3:00am
    # safe times:  8:00am to 8:00pm
    action_time = Time.current.round(0).in_time_zone('Eastern Time (US & Canada)').advance(days: 1).change(hour: 3).utc
    action_time_advanced = action_time.in_time_zone('Eastern Time (US & Canada)').advance(hours: 5).advance(days: -1).utc
    acceptable_time = AcceptableTime.new(
      time_zone:     'Eastern Time (US & Canada)',
      reverse:       false,
      delay_months:  0,
      delay_days:    0,
      delay_hours:   0,
      delay_minutes: 0,
      safe_start:    480,
      safe_end:      1200,
      safe_sun:      true,
      safe_mon:      true,
      safe_tue:      true,
      safe_wed:      true,
      safe_thu:      true,
      safe_fri:      true,
      safe_sat:      true,
      holidays:      { action_time.to_date => 'backward' },
      ok2skip:       false
    )

    it 'Test AcceptableTime.advance_months' do
      expect(acceptable_time.advance_months(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_days' do
      expect(acceptable_time.advance_days(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_hours' do
      expect(acceptable_time.advance_hours(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_minutes' do
      expect(acceptable_time.advance_minutes(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.new_time' do
      expect(acceptable_time.new_time(action_time)).to eq(action_time_advanced)
    end

    it 'Test AcceptableTime.new_time_advance' do
      expect(acceptable_time.new_time_advance(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.safe_time' do
      expect(acceptable_time.safe_time(action_time)).to eq(action_time_advanced)
    end

    it 'Test AcceptableTime.safe_time?' do
      expect(acceptable_time.safe_time?(action_time)).to eq(false)
    end
  end

  describe 'Library: AcceptableTime (begin on date/target time: 11:00pm, safe times: 8:00am - 8:00pm/NO holidays)' do
    # target time: 3:00am
    # safe times:  8:00am to 8:00pm
    action_time = Time.current.round(0).in_time_zone('Eastern Time (US & Canada)').advance(days: 1).change(hour: 23).utc
    action_time_advanced = action_time.in_time_zone('Eastern Time (US & Canada)').advance(hours: 9).utc
    acceptable_time = AcceptableTime.new(
      time_zone:     'Eastern Time (US & Canada)',
      reverse:       false,
      delay_months:  0,
      delay_days:    0,
      delay_hours:   0,
      delay_minutes: 0,
      safe_start:    480,
      safe_end:      1200,
      safe_sun:      true,
      safe_mon:      true,
      safe_tue:      true,
      safe_wed:      true,
      safe_thu:      true,
      safe_fri:      true,
      safe_sat:      true,
      holidays:      {},
      ok2skip:       false
    )

    it 'Test AcceptableTime.advance_months' do
      expect(acceptable_time.advance_months(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_days' do
      expect(acceptable_time.advance_days(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_hours' do
      expect(acceptable_time.advance_hours(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_minutes' do
      expect(acceptable_time.advance_minutes(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.new_time' do
      expect(acceptable_time.new_time(action_time)).to eq(action_time_advanced)
    end

    it 'Test AcceptableTime.new_time_advance' do
      expect(acceptable_time.new_time_advance(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.safe_time' do
      expect(acceptable_time.safe_time(action_time)).to eq(action_time_advanced)
    end

    it 'Test AcceptableTime.safe_time?' do
      expect(acceptable_time.safe_time?(action_time)).to eq(false)
    end
  end

  describe 'Library: AcceptableTime (begin on date/NO constraints, advance: 3 months, 1 day, 4 hours, 10 minutes/NO holidays)' do
    # no constraints
    action_time = Time.current.round(0)
    action_time_advanced = action_time.in_time_zone('Eastern Time (US & Canada)').advance(months: 3, days: 1, hours: 4, minutes: 10).utc
    acceptable_time = AcceptableTime.new(
      time_zone:     'Eastern Time (US & Canada)',
      reverse:       false,
      delay_months:  3,
      delay_days:    1,
      delay_hours:   4,
      delay_minutes: 10,
      safe_start:    0,
      safe_end:      1440,
      safe_sun:      true,
      safe_mon:      true,
      safe_tue:      true,
      safe_wed:      true,
      safe_thu:      true,
      safe_fri:      true,
      safe_sat:      true,
      holidays:      {},
      ok2skip:       false
    )

    it 'Test AcceptableTime.advance_months' do
      expect(acceptable_time.advance_months(action_time)).to eq(action_time.advance(months: 3))
    end

    it 'Test AcceptableTime.advance_days' do
      expect(acceptable_time.advance_days(action_time)).to eq(action_time.advance(days: 1))
    end

    it 'Test AcceptableTime.advance_hours' do
      expect(acceptable_time.advance_hours(action_time)).to eq(action_time.advance(hours: 4))
    end

    it 'Test AcceptableTime.advance_minutes' do
      expect(acceptable_time.advance_minutes(action_time)).to eq(action_time.advance(minutes: 10))
    end

    it 'Test AcceptableTime.new_time' do
      expect(acceptable_time.new_time(action_time)).to eq(action_time_advanced)
    end

    it 'Test AcceptableTime.new_time_advance' do
      expect(acceptable_time.new_time_advance(action_time)).to eq(action_time_advanced)
    end

    it 'Test AcceptableTime.safe_time' do
      expect(acceptable_time.safe_time(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.safe_time?' do
      expect(acceptable_time.safe_time?(action_time)).to eq(true)
    end
  end

  describe 'Library: AcceptableTime (begin on date/NO constraints, advance: 3 months, 1 day, 4 hours, 10 minutes/holidays forward)' do
    # no constraints
    action_time = Time.current.round(0)
    action_time_advanced = action_time.in_time_zone('Eastern Time (US & Canada)').advance(months: 3, days: 1, hours: 4, minutes: 10).utc
    acceptable_time = AcceptableTime.new(
      time_zone:     'Eastern Time (US & Canada)',
      reverse:       false,
      delay_months:  3,
      delay_days:    1,
      delay_hours:   4,
      delay_minutes: 10,
      safe_start:    0,
      safe_end:      1440,
      safe_sun:      true,
      safe_mon:      true,
      safe_tue:      true,
      safe_wed:      true,
      safe_thu:      true,
      safe_fri:      true,
      safe_sat:      true,
      holidays:      { action_time_advanced.to_date => 'forward' },
      ok2skip:       false
    )

    it 'Test AcceptableTime.advance_months' do
      expect(acceptable_time.advance_months(action_time)).to eq(action_time.advance(months: 3))
    end

    it 'Test AcceptableTime.advance_days' do
      expect(acceptable_time.advance_days(action_time)).to eq(action_time.advance(days: 1))
    end

    it 'Test AcceptableTime.advance_hours' do
      expect(acceptable_time.advance_hours(action_time)).to eq(action_time.advance(hours: 4))
    end

    it 'Test AcceptableTime.advance_minutes' do
      expect(acceptable_time.advance_minutes(action_time)).to eq(action_time.advance(minutes: 10))
    end

    it 'Test AcceptableTime.new_time' do
      expect(acceptable_time.new_time(action_time)).to eq(action_time_advanced.advance(days: 1).change(hour: 5))
    end

    it 'Test AcceptableTime.new_time_advance' do
      expect(acceptable_time.new_time_advance(action_time)).to eq(action_time_advanced)
    end

    it 'Test AcceptableTime.safe_time' do
      expect(acceptable_time.safe_time(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.safe_time?' do
      expect(acceptable_time.safe_time?(action_time)).to eq(true)
    end
  end

  describe 'Library: AcceptableTime (begin on date/NO constraints, advance: 3 months, 1 day, 4 hours, 10 minutes/holidays backward)' do
    # no constraints
    action_time = Time.current.round(0)
    action_time_advanced = action_time.in_time_zone('Eastern Time (US & Canada)').advance(months: 3, days: 1, hours: 4, minutes: 10).utc
    acceptable_time = AcceptableTime.new(
      time_zone:     'Eastern Time (US & Canada)',
      reverse:       false,
      delay_months:  3,
      delay_days:    1,
      delay_hours:   4,
      delay_minutes: 10,
      safe_start:    0,
      safe_end:      1440,
      safe_sun:      true,
      safe_mon:      true,
      safe_tue:      true,
      safe_wed:      true,
      safe_thu:      true,
      safe_fri:      true,
      safe_sat:      true,
      holidays:      { action_time_advanced.to_date => 'backward' },
      ok2skip:       false
    )

    it 'Test AcceptableTime.advance_months' do
      expect(acceptable_time.advance_months(action_time)).to eq(action_time.advance(months: 3))
    end

    it 'Test AcceptableTime.advance_days' do
      expect(acceptable_time.advance_days(action_time)).to eq(action_time.advance(days: 1))
    end

    it 'Test AcceptableTime.advance_hours' do
      expect(acceptable_time.advance_hours(action_time)).to eq(action_time.advance(hours: 4))
    end

    it 'Test AcceptableTime.advance_minutes' do
      expect(acceptable_time.advance_minutes(action_time)).to eq(action_time.advance(minutes: 10))
    end

    it 'Test AcceptableTime.new_time' do
      expect(acceptable_time.new_time(action_time)).to eq(action_time_advanced.advance(days: -1).change(hour: 5))
    end

    it 'Test AcceptableTime.new_time_advance' do
      expect(acceptable_time.new_time_advance(action_time)).to eq(action_time_advanced)
    end

    it 'Test AcceptableTime.safe_time' do
      expect(acceptable_time.safe_time(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.safe_time?' do
      expect(acceptable_time.safe_time?(action_time)).to eq(true)
    end
  end

  describe 'Library: AcceptableTime (begin on date/target time: 8:00am, safe times: 8:00am - 8:00pm, advance: 6 months, 1 day, 4 hours, 10 minutes/NO holidays)' do
    # target time: 8:00am
    # safe times:  8:00am to 8:00pm
    action_time = Time.current.round(0).in_time_zone('Eastern Time (US & Canada)').change(hour: 8).advance(days: 1).utc
    action_time_advanced = action_time.in_time_zone('Eastern Time (US & Canada)').advance(months: 6, days: 1, hours: 4, minutes: 10).utc
    acceptable_time = AcceptableTime.new(
      time_zone:     'Eastern Time (US & Canada)',
      reverse:       false,
      delay_months:  6,
      delay_days:    1,
      delay_hours:   4,
      delay_minutes: 10,
      safe_start:    480,
      safe_end:      1200,
      safe_sun:      true,
      safe_mon:      true,
      safe_tue:      true,
      safe_wed:      true,
      safe_thu:      true,
      safe_fri:      true,
      safe_sat:      true,
      holidays:      {},
      ok2skip:       false
    )

    it 'Test AcceptableTime.advance_months' do
      expect(acceptable_time.advance_months(action_time)).to eq(action_time.advance(months: 6))
    end

    it 'Test AcceptableTime.advance_days' do
      expect(acceptable_time.advance_days(action_time)).to eq(action_time.advance(days: 1))
    end

    it 'Test AcceptableTime.advance_hours' do
      expect(acceptable_time.advance_hours(action_time)).to eq(action_time.advance(hours: 4))
    end

    it 'Test AcceptableTime.advance_minutes' do
      expect(acceptable_time.advance_minutes(action_time)).to eq(action_time.advance(minutes: 10))
    end

    it 'Test AcceptableTime.new_time' do
      expect(acceptable_time.new_time(action_time)).to eq(action_time_advanced)
    end

    it 'Test AcceptableTime.new_time_advance' do
      expect(acceptable_time.new_time_advance(action_time)).to eq(action_time_advanced)
    end

    it 'Test AcceptableTime.safe_time' do
      expect(acceptable_time.safe_time(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.safe_time?' do
      expect(acceptable_time.safe_time?(action_time)).to eq(true)
    end
  end

  describe 'Library: AcceptableTime (begin on date/target time: 8:00am, safe times: 8:00am - 8:00pm, advance: 6 months, 1 day, 4 hours, 10 minutes/holidays forward)' do
    # target time: 8:00am
    # safe times:  8:00am to 8:00pm
    action_time = Time.current.round(0).in_time_zone('Eastern Time (US & Canada)').change(hour: 8).advance(days: 1).utc
    action_time_advanced = action_time.in_time_zone('Eastern Time (US & Canada)').advance(months: 6, days: 1, hours: 4, minutes: 10).utc
    acceptable_time = AcceptableTime.new(
      time_zone:     'Eastern Time (US & Canada)',
      reverse:       false,
      delay_months:  6,
      delay_days:    1,
      delay_hours:   4,
      delay_minutes: 10,
      safe_start:    480,
      safe_end:      1200,
      safe_sun:      true,
      safe_mon:      true,
      safe_tue:      true,
      safe_wed:      true,
      safe_thu:      true,
      safe_fri:      true,
      safe_sat:      true,
      holidays:      { action_time_advanced.to_date => 'forward' },
      ok2skip:       false
    )

    it 'Test AcceptableTime.advance_months' do
      expect(acceptable_time.advance_months(action_time)).to eq(action_time.advance(months: 6))
    end

    it 'Test AcceptableTime.advance_days' do
      expect(acceptable_time.advance_days(action_time)).to eq(action_time.advance(days: 1))
    end

    it 'Test AcceptableTime.advance_hours' do
      expect(acceptable_time.advance_hours(action_time)).to eq(action_time.advance(hours: 4))
    end

    it 'Test AcceptableTime.advance_minutes' do
      expect(acceptable_time.advance_minutes(action_time)).to eq(action_time.advance(minutes: 10))
    end

    it 'Test AcceptableTime.new_time' do
      expect(acceptable_time.new_time(action_time)).to eq(action_time_advanced.advance(days: 1).change(hour: 12))
    end

    it 'Test AcceptableTime.new_time_advance' do
      expect(acceptable_time.new_time_advance(action_time)).to eq(action_time_advanced)
    end

    it 'Test AcceptableTime.safe_time' do
      expect(acceptable_time.safe_time(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.safe_time?' do
      expect(acceptable_time.safe_time?(action_time)).to eq(true)
    end
  end

  describe 'Library: AcceptableTime (begin on date/target time: 8:00am, safe times: 8:00am - 8:00pm, advance: 6 months, 1 day, 4 hours, 10 minutes/holidays backward)' do
    # target time: 8:00am
    # safe times:  8:00am to 8:00pm
    action_time = Time.current.round(0).in_time_zone('Eastern Time (US & Canada)').change(hour: 8).advance(days: 1).utc
    action_time_advanced = action_time.in_time_zone('Eastern Time (US & Canada)').advance(months: 6, days: 1, hours: 4, minutes: 10).utc
    acceptable_time = AcceptableTime.new(
      time_zone:     'Eastern Time (US & Canada)',
      reverse:       false,
      delay_months:  6,
      delay_days:    1,
      delay_hours:   4,
      delay_minutes: 10,
      safe_start:    480,
      safe_end:      1200,
      safe_sun:      true,
      safe_mon:      true,
      safe_tue:      true,
      safe_wed:      true,
      safe_thu:      true,
      safe_fri:      true,
      safe_sat:      true,
      holidays:      { action_time_advanced.to_date => 'backward' },
      ok2skip:       false
    )

    it 'Test AcceptableTime.advance_months' do
      expect(acceptable_time.advance_months(action_time)).to eq(action_time.advance(months: 6))
    end

    it 'Test AcceptableTime.advance_days' do
      expect(acceptable_time.advance_days(action_time)).to eq(action_time.advance(days: 1))
    end

    it 'Test AcceptableTime.advance_hours' do
      expect(acceptable_time.advance_hours(action_time)).to eq(action_time.advance(hours: 4))
    end

    it 'Test AcceptableTime.advance_minutes' do
      expect(acceptable_time.advance_minutes(action_time)).to eq(action_time.advance(minutes: 10))
    end

    it 'Test AcceptableTime.new_time' do
      expect(acceptable_time.new_time(action_time)).to eq(action_time_advanced.advance(days: -1).change(hour: 12))
    end

    it 'Test AcceptableTime.new_time_advance' do
      expect(acceptable_time.new_time_advance(action_time)).to eq(action_time_advanced)
    end

    it 'Test AcceptableTime.safe_time' do
      expect(acceptable_time.safe_time(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.safe_time?' do
      expect(acceptable_time.safe_time?(action_time)).to eq(true)
    end
  end

  describe 'Library: AcceptableTime (begin on date/target time: 3:00am, safe times: 8:00am - 8:00pm, advance: 2 months, 1 day, 4 hours, 10 minutes/NO holidays)' do
    # target time: 3:00am
    # safe times:  8:00am to 8:00pm
    action_time = Time.current.round(0).in_time_zone('Eastern Time (US & Canada)').change(hour: 3).advance(days: 1).utc
    action_time_advanced = action_time.in_time_zone('Eastern Time (US & Canada)').advance(months: 2, days: 1, hours: 4).utc
    acceptable_time = AcceptableTime.new(
      time_zone:     'Eastern Time (US & Canada)',
      reverse:       false,
      delay_months:  2,
      delay_days:    1,
      delay_hours:   4,
      delay_minutes: 10,
      safe_start:    480,
      safe_end:      1200,
      safe_sun:      true,
      safe_mon:      true,
      safe_tue:      true,
      safe_wed:      true,
      safe_thu:      true,
      safe_fri:      true,
      safe_sat:      true,
      holidays:      {},
      ok2skip:       false
    )

    it 'Test AcceptableTime.advance_months' do
      expect(acceptable_time.advance_months(action_time)).to eq(action_time.advance(months: 2))
    end

    it 'Test AcceptableTime.advance_days' do
      expect(acceptable_time.advance_days(action_time)).to eq(action_time.advance(days: 1))
    end

    it 'Test AcceptableTime.advance_hours' do
      expect(acceptable_time.advance_hours(action_time)).to eq(action_time.advance(hours: 4))
    end

    it 'Test AcceptableTime.advance_minutes' do
      expect(acceptable_time.advance_minutes(action_time)).to eq(action_time.advance(minutes: 10))
    end

    it 'Test AcceptableTime.new_time' do
      expect(acceptable_time.new_time(action_time)).to eq(action_time_advanced.advance(hours: 1))
    end

    it 'Test AcceptableTime.new_time_advance' do
      expect(acceptable_time.new_time_advance(action_time)).to eq(action_time_advanced.advance(minutes: 10))
    end

    it 'Test AcceptableTime.safe_time' do
      expect(acceptable_time.safe_time(action_time)).to eq(action_time.advance(hours: 5))
    end

    it 'Test AcceptableTime.safe_time?' do
      expect(acceptable_time.safe_time?(action_time)).to eq(false)
    end
  end

  describe 'Library: AcceptableTime (begin on date/target time: 3:00am, safe times: 8:00am - 8:00pm, advance: 2 months, 1 day, 4 hours, 10 minutes/holidays forward)' do
    # target time: 3:00am
    # safe times:  8:00am to 8:00pm
    action_time = Time.current.round(0).in_time_zone('Eastern Time (US & Canada)').change(hour: 3).advance(days: 1).utc
    action_time_advanced = action_time.in_time_zone('Eastern Time (US & Canada)').advance(months: 2, days: 1, hours: 4).utc
    acceptable_time = AcceptableTime.new(
      time_zone:     'Eastern Time (US & Canada)',
      reverse:       false,
      delay_months:  2,
      delay_days:    1,
      delay_hours:   4,
      delay_minutes: 10,
      safe_start:    480,
      safe_end:      1200,
      safe_sun:      true,
      safe_mon:      true,
      safe_tue:      true,
      safe_wed:      true,
      safe_thu:      true,
      safe_fri:      true,
      safe_sat:      true,
      holidays:      { action_time_advanced.to_date => 'forward' },
      ok2skip:       false
    )

    it 'Test AcceptableTime.advance_months' do
      expect(acceptable_time.advance_months(action_time)).to eq(action_time.advance(months: 2))
    end

    it 'Test AcceptableTime.advance_days' do
      expect(acceptable_time.advance_days(action_time)).to eq(action_time.advance(days: 1))
    end

    it 'Test AcceptableTime.advance_hours' do
      expect(acceptable_time.advance_hours(action_time)).to eq(action_time.advance(hours: 4))
    end

    it 'Test AcceptableTime.advance_minutes' do
      expect(acceptable_time.advance_minutes(action_time)).to eq(action_time.advance(minutes: 10))
    end

    it 'Test AcceptableTime.new_time' do
      expect(acceptable_time.new_time(action_time)).to eq(action_time_advanced.advance(days: 1, hours: 1))
    end

    it 'Test AcceptableTime.new_time_advance' do
      expect(acceptable_time.new_time_advance(action_time)).to eq(action_time_advanced.advance(minutes: 10))
    end

    it 'Test AcceptableTime.safe_time' do
      expect(acceptable_time.safe_time(action_time)).to eq(action_time.advance(hours: 5))
    end

    it 'Test AcceptableTime.safe_time?' do
      expect(acceptable_time.safe_time?(action_time)).to eq(false)
    end
  end

  describe 'Library: AcceptableTime (begin on date/target time: 3:00am, safe times: 8:00am - 8:00pm, advance: 2 months, 1 day, 4 hours, 10 minutes/holidays backward)' do
    # target time: 3:00am
    # safe times:  8:00am to 8:00pm
    action_time = Time.current.round(0).in_time_zone('Eastern Time (US & Canada)').change(hour: 3).advance(days: 1).utc
    action_time_advanced = action_time.in_time_zone('Eastern Time (US & Canada)').advance(months: 2, days: 1, hours: 4).utc
    acceptable_time = AcceptableTime.new(
      time_zone:     'Eastern Time (US & Canada)',
      reverse:       false,
      delay_months:  2,
      delay_days:    1,
      delay_hours:   4,
      delay_minutes: 10,
      safe_start:    480,
      safe_end:      1200,
      safe_sun:      true,
      safe_mon:      true,
      safe_tue:      true,
      safe_wed:      true,
      safe_thu:      true,
      safe_fri:      true,
      safe_sat:      true,
      holidays:      { action_time_advanced.to_date => 'backward' },
      ok2skip:       false
    )

    it 'Test AcceptableTime.advance_months' do
      expect(acceptable_time.advance_months(action_time)).to eq(action_time.advance(months: 2))
    end

    it 'Test AcceptableTime.advance_days' do
      expect(acceptable_time.advance_days(action_time)).to eq(action_time.advance(days: 1))
    end

    it 'Test AcceptableTime.advance_hours' do
      expect(acceptable_time.advance_hours(action_time)).to eq(action_time.advance(hours: 4))
    end

    it 'Test AcceptableTime.advance_minutes' do
      expect(acceptable_time.advance_minutes(action_time)).to eq(action_time.advance(minutes: 10))
    end

    it 'Test AcceptableTime.new_time' do
      expect(acceptable_time.new_time(action_time)).to eq(action_time_advanced.advance(days: -1, hours: 1))
    end

    it 'Test AcceptableTime.new_time_advance' do
      expect(acceptable_time.new_time_advance(action_time)).to eq(action_time_advanced.advance(minutes: 10))
    end

    it 'Test AcceptableTime.safe_time' do
      expect(acceptable_time.safe_time(action_time)).to eq(action_time.advance(hours: 5))
    end

    it 'Test AcceptableTime.safe_time?' do
      expect(acceptable_time.safe_time?(action_time)).to eq(false)
    end
  end

  describe 'Library: AcceptableTime (begin on date/target time: 11:00pm, safe times: 8:00am - 8:00pm, advance: 12 months, 1 day, 4 hours, 10 minutes/NO holidays)' do
    # target time: 11:00pm
    # safe times:  8:00am to 8:00pm
    action_time = Time.current.round(0).in_time_zone('Eastern Time (US & Canada)').change(hour: 23).advance(days: 1).utc
    action_time_advanced = action_time.in_time_zone('Eastern Time (US & Canada)').advance(months: 12, days: 1, hours: 4).utc
    acceptable_time = AcceptableTime.new(
      time_zone:     'Eastern Time (US & Canada)',
      reverse:       false,
      delay_months:  12,
      delay_days:    1,
      delay_hours:   4,
      delay_minutes: 10,
      safe_start:    480,
      safe_end:      1200,
      safe_sun:      true,
      safe_mon:      true,
      safe_tue:      true,
      safe_wed:      true,
      safe_thu:      true,
      safe_fri:      true,
      safe_sat:      true,
      holidays:      {},
      ok2skip:       false
    )

    it 'Test AcceptableTime.advance_months' do
      expect(acceptable_time.advance_months(action_time)).to eq(action_time.advance(months: 12))
    end

    it 'Test AcceptableTime.advance_days' do
      expect(acceptable_time.advance_days(action_time)).to eq(action_time.advance(days: 1))
    end

    it 'Test AcceptableTime.advance_hours' do
      expect(acceptable_time.advance_hours(action_time)).to eq(action_time.advance(hours: 4))
    end

    it 'Test AcceptableTime.advance_minutes' do
      expect(acceptable_time.advance_minutes(action_time)).to eq(action_time.advance(minutes: 10))
    end

    it 'Test AcceptableTime.new_time' do
      expect(acceptable_time.new_time(action_time)).to eq(action_time_advanced.change(hour: action_time_advanced.dst? ? 12 : 13))
    end

    it 'Test AcceptableTime.new_time_advance' do
      expect(acceptable_time.new_time_advance(action_time)).to eq(action_time_advanced.advance(minutes: 10))
    end

    it 'Test AcceptableTime.safe_time' do
      expect(acceptable_time.safe_time(action_time.advance(months: 12, days: 1, hours: 4, minutes: 10))).to eq(action_time.advance(months: 12, days: 1, hours: 4).change(hour: action_time_advanced.dst? ? 12 : 13).utc)
    end

    it 'Test AcceptableTime.safe_time?' do
      expect(acceptable_time.safe_time?(action_time.advance(months: 12, days: 1, hours: 4, minutes: 10))).to eq(false)
    end
  end

  describe 'Library: AcceptableTime (begin on date/target time: 11:00pm, safe times: 8:00am - 8:00pm, advance: 12 months, 1 day, 4 hours, 10 minutes/holidays forward)' do
    # target time: 11:00pm
    # safe times:  8:00am to 8:00pm
    action_time = Time.current.round(0).in_time_zone('Eastern Time (US & Canada)').change(hour: 23).advance(days: 1).utc
    action_time_advanced = action_time.in_time_zone('Eastern Time (US & Canada)').advance(months: 12, days: 1, hours: 4).utc
    acceptable_time = AcceptableTime.new(
      time_zone:     'Eastern Time (US & Canada)',
      reverse:       false,
      delay_months:  12,
      delay_days:    1,
      delay_hours:   4,
      delay_minutes: 10,
      safe_start:    480,
      safe_end:      1200,
      safe_sun:      true,
      safe_mon:      true,
      safe_tue:      true,
      safe_wed:      true,
      safe_thu:      true,
      safe_fri:      true,
      safe_sat:      true,
      holidays:      { action_time_advanced.to_date => 'forward' },
      ok2skip:       false
    )

    it 'Test AcceptableTime.advance_months' do
      expect(acceptable_time.advance_months(action_time)).to eq(action_time.advance(months: 12))
    end

    it 'Test AcceptableTime.advance_days' do
      expect(acceptable_time.advance_days(action_time)).to eq(action_time.advance(days: 1))
    end

    it 'Test AcceptableTime.advance_hours' do
      expect(acceptable_time.advance_hours(action_time)).to eq(action_time.advance(hours: 4))
    end

    it 'Test AcceptableTime.advance_minutes' do
      expect(acceptable_time.advance_minutes(action_time)).to eq(action_time.advance(minutes: 10))
    end

    it 'Test AcceptableTime.new_time' do
      expect(acceptable_time.new_time(action_time)).to eq(action_time_advanced.advance(days: 1).change(hour: action_time_advanced.dst? ? 12 : 13))
    end

    it 'Test AcceptableTime.new_time_advance' do
      expect(acceptable_time.new_time_advance(action_time)).to eq(action_time_advanced.advance(minutes: 10))
    end

    it 'Test AcceptableTime.safe_time' do
      expect(acceptable_time.safe_time(action_time.advance(months: 12, days: 1, hours: 4, minutes: 10))).to eq(action_time.advance(months: 12, days: 2, hours: 4).change(hour: action_time_advanced.dst? ? 12 : 13).utc)
    end

    it 'Test AcceptableTime.safe_time?' do
      expect(acceptable_time.safe_time?(action_time.advance(months: 12, days: 1, hours: 4, minutes: 10))).to eq(false)
    end
  end

  describe 'Library: AcceptableTime (begin on date/target time: 11:00pm, safe times: 8:00am - 8:00pm, advance: 12 months, 1 day, 4 hours, 10 minutes/holidays backward)' do
    # target time: 11:00pm
    # safe times:  8:00am to 8:00pm
    action_time = Time.current.round(0).in_time_zone('Eastern Time (US & Canada)').change(hour: 23).advance(days: 1).utc
    action_time_advanced = action_time.in_time_zone('Eastern Time (US & Canada)').advance(months: 12, days: 1, hours: 4).utc
    acceptable_time = AcceptableTime.new(
      time_zone:     'Eastern Time (US & Canada)',
      reverse:       false,
      delay_months:  12,
      delay_days:    1,
      delay_hours:   4,
      delay_minutes: 10,
      safe_start:    480,
      safe_end:      1200,
      safe_sun:      true,
      safe_mon:      true,
      safe_tue:      true,
      safe_wed:      true,
      safe_thu:      true,
      safe_fri:      true,
      safe_sat:      true,
      holidays:      { action_time_advanced.to_date => 'backward' },
      ok2skip:       false
    )

    it 'Test AcceptableTime.advance_months' do
      expect(acceptable_time.advance_months(action_time)).to eq(action_time.advance(months: 12))
    end

    it 'Test AcceptableTime.advance_days' do
      expect(acceptable_time.advance_days(action_time)).to eq(action_time.advance(days: 1))
    end

    it 'Test AcceptableTime.advance_hours' do
      expect(acceptable_time.advance_hours(action_time)).to eq(action_time.advance(hours: 4))
    end

    it 'Test AcceptableTime.advance_minutes' do
      expect(acceptable_time.advance_minutes(action_time)).to eq(action_time.advance(minutes: 10))
    end

    it 'Test AcceptableTime.new_time' do
      expect(acceptable_time.new_time(action_time)).to eq(action_time_advanced.advance(days: -1).change(hour: action_time_advanced.dst? ? 12 : 13))
    end

    it 'Test AcceptableTime.new_time_advance' do
      expect(acceptable_time.new_time_advance(action_time)).to eq(action_time_advanced.advance(minutes: 10))
    end

    it 'Test AcceptableTime.safe_time' do
      expect(acceptable_time.safe_time(action_time.advance(months: 12, days: 1, hours: 4, minutes: 10))).to eq(action_time.advance(months: 12, hours: 4).change(hour: action_time_advanced.dst? ? 12 : 13).utc)
    end

    it 'Test AcceptableTime.safe_time?' do
      expect(acceptable_time.safe_time?(action_time.advance(months: 12, days: 1, hours: 4, minutes: 10))).to eq(false)
    end
  end

  describe 'Library: AcceptableTime (begin on date/target time: 10:00am, safe times: 8:00am - 8:00pm, advance: 6 months/NO holidays)' do
    # target time: 10:00am
    # safe times:  8:00am to 8:00pm
    action_time = Time.current.round(0).in_time_zone('Eastern Time (US & Canada)').advance(months: -12).change(hour: 10).utc
    action_time_advanced = nil
    acceptable_time = AcceptableTime.new(
      time_zone:     'Eastern Time (US & Canada)',
      reverse:       false,
      delay_months:  6,
      delay_days:    0,
      delay_hours:   0,
      delay_minutes: 0,
      safe_start:    480,
      safe_end:      1200,
      safe_sun:      true,
      safe_mon:      true,
      safe_tue:      true,
      safe_wed:      true,
      safe_thu:      true,
      safe_fri:      true,
      safe_sat:      true,
      holidays:      {},
      ok2skip:       false
    )

    it 'Test AcceptableTime.advance_months' do
      expect(acceptable_time.advance_months(action_time)).to eq(action_time.advance(months: 6))
    end

    it 'Test AcceptableTime.advance_days' do
      expect(acceptable_time.advance_days(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_hours' do
      expect(acceptable_time.advance_hours(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_minutes' do
      expect(acceptable_time.advance_minutes(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.new_time' do
      expect(acceptable_time.new_time(action_time)).to eq(action_time_advanced)
    end

    it 'Test AcceptableTime.new_time_advance' do
      expect(acceptable_time.new_time_advance(action_time)).to eq(action_time.in_time_zone('Eastern Time (US & Canada)').advance(months: 6))
    end

    it 'Test AcceptableTime.safe_time' do
      expect(acceptable_time.safe_time(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.safe_time?' do
      expect(acceptable_time.safe_time?(action_time)).to eq(true)
    end
  end

  describe 'Library: AcceptableTime (begin on date/target time: 10:00am, safe times: 8:00am - 8:00pm, advance: 6 months/holidays forward)' do
    # target time: 10:00am
    # safe times:  8:00am to 8:00pm
    action_time = Time.current.round(0).in_time_zone('Eastern Time (US & Canada)').advance(months: -12).change(hour: 10).utc
    action_time_advanced = nil
    acceptable_time = AcceptableTime.new(
      time_zone:     'Eastern Time (US & Canada)',
      reverse:       false,
      delay_months:  6,
      delay_days:    0,
      delay_hours:   0,
      delay_minutes: 0,
      safe_start:    480,
      safe_end:      1200,
      safe_sun:      true,
      safe_mon:      true,
      safe_tue:      true,
      safe_wed:      true,
      safe_thu:      true,
      safe_fri:      true,
      safe_sat:      true,
      holidays:      { action_time.to_date => 'forward' },
      ok2skip:       false
    )

    it 'Test AcceptableTime.advance_months' do
      expect(acceptable_time.advance_months(action_time)).to eq(action_time.advance(months: 6))
    end

    it 'Test AcceptableTime.advance_days' do
      expect(acceptable_time.advance_days(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_hours' do
      expect(acceptable_time.advance_hours(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_minutes' do
      expect(acceptable_time.advance_minutes(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.new_time' do
      expect(acceptable_time.new_time(action_time)).to eq(action_time_advanced)
    end

    it 'Test AcceptableTime.new_time_advance' do
      expect(acceptable_time.new_time_advance(action_time)).to eq(action_time.in_time_zone('Eastern Time (US & Canada)').advance(months: 6))
    end

    it 'Test AcceptableTime.safe_time' do
      expect(acceptable_time.safe_time(action_time)).to eq(action_time.advance(days: 1).change(hour: action_time.dst? ? 12 : 13))
    end

    it 'Test AcceptableTime.safe_time?' do
      expect(acceptable_time.safe_time?(action_time)).to eq(false)
    end
  end

  describe 'Library: AcceptableTime (begin on date/target time: 10:00am, safe times: 8:00am - 8:00pm, advance: 6 months/holidays backward)' do
    # target time: 10:00am
    # safe times:  8:00am to 8:00pm
    action_time = Time.current.round(0).in_time_zone('Eastern Time (US & Canada)').advance(months: -12).change(hour: 10).utc
    action_time_advanced = nil
    acceptable_time = AcceptableTime.new(
      time_zone:     'Eastern Time (US & Canada)',
      reverse:       false,
      delay_months:  6,
      delay_days:    0,
      delay_hours:   0,
      delay_minutes: 0,
      safe_start:    480,
      safe_end:      1200,
      safe_sun:      true,
      safe_mon:      true,
      safe_tue:      true,
      safe_wed:      true,
      safe_thu:      true,
      safe_fri:      true,
      safe_sat:      true,
      holidays:      { action_time.to_date => 'backward' },
      ok2skip:       false
    )

    it 'Test AcceptableTime.advance_months' do
      expect(acceptable_time.advance_months(action_time)).to eq(action_time.advance(months: 6))
    end

    it 'Test AcceptableTime.advance_days' do
      expect(acceptable_time.advance_days(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_hours' do
      expect(acceptable_time.advance_hours(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_minutes' do
      expect(acceptable_time.advance_minutes(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.new_time' do
      expect(acceptable_time.new_time(action_time)).to eq(action_time_advanced)
    end

    it 'Test AcceptableTime.new_time_advance' do
      expect(acceptable_time.new_time_advance(action_time)).to eq(action_time.in_time_zone('Eastern Time (US & Canada)').advance(months: 6))
    end

    it 'Test AcceptableTime.safe_time' do
      expect(acceptable_time.safe_time(action_time)).to eq(action_time.advance(days: -1).change(hour: action_time.dst? ? 12 : 13))
    end

    it 'Test AcceptableTime.safe_time?' do
      expect(acceptable_time.safe_time?(action_time)).to eq(false)
    end
  end

  ######################################

  describe 'Library: AcceptableTime (leading up to date/NO constraints/NO holidays)' do
    # no constraints
    action_time = Time.current.round(0).in_time_zone('Eastern Time (US & Canada)').advance(days: 10).utc
    action_time_advanced = action_time.in_time_zone('Eastern Time (US & Canada)').advance(days: -10).utc
    acceptable_time = AcceptableTime.new(
      time_zone:     'Eastern Time (US & Canada)',
      reverse:       true,
      delay_months:  0,
      delay_days:    0,
      delay_hours:   0,
      delay_minutes: 0,
      safe_start:    0,
      safe_end:      1440,
      safe_sun:      true,
      safe_mon:      true,
      safe_tue:      true,
      safe_wed:      true,
      safe_thu:      true,
      safe_fri:      true,
      safe_sat:      true,
      holidays:      {},
      ok2skip:       false
    )

    it 'Test AcceptableTime.advance_months' do
      expect(acceptable_time.advance_months(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_days' do
      expect(acceptable_time.advance_days(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_hours' do
      expect(acceptable_time.advance_hours(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_minutes' do
      expect(acceptable_time.advance_minutes(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.new_time' do
      expect(acceptable_time.new_time(action_time).round(0)).to eq(action_time_advanced)
    end

    it 'Test AcceptableTime.new_time_advance' do
      expect(acceptable_time.new_time_advance(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.safe_time' do
      expect(acceptable_time.safe_time(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.safe_time?' do
      expect(acceptable_time.safe_time?(action_time)).to eq(true)
    end
  end

  describe 'Library: AcceptableTime (leading up to date/NO constraints/holidays forward)' do
    # no constraints
    action_time = Time.current.round(0).in_time_zone('Eastern Time (US & Canada)').advance(days: 10).utc
    action_time_advanced = action_time.in_time_zone('Eastern Time (US & Canada)').advance(days: -10).utc
    acceptable_time = AcceptableTime.new(
      time_zone:     'Eastern Time (US & Canada)',
      reverse:       true,
      delay_months:  0,
      delay_days:    0,
      delay_hours:   0,
      delay_minutes: 0,
      safe_start:    0,
      safe_end:      1440,
      safe_sun:      true,
      safe_mon:      true,
      safe_tue:      true,
      safe_wed:      true,
      safe_thu:      true,
      safe_fri:      true,
      safe_sat:      true,
      holidays:      { action_time_advanced.to_date => 'forward' },
      ok2skip:       false
    )

    it 'Test AcceptableTime.advance_months' do
      expect(acceptable_time.advance_months(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_days' do
      expect(acceptable_time.advance_days(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_hours' do
      expect(acceptable_time.advance_hours(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_minutes' do
      expect(acceptable_time.advance_minutes(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.new_time' do
      expect(acceptable_time.new_time(action_time).round(0)).to eq(action_time_advanced.advance(days: 1).change(hour: 5))
    end

    it 'Test AcceptableTime.new_time_advance' do
      expect(acceptable_time.new_time_advance(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.safe_time' do
      expect(acceptable_time.safe_time(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.safe_time?' do
      expect(acceptable_time.safe_time?(action_time)).to eq(true)
    end
  end

  describe 'Library: AcceptableTime (leading up to date/NO constraints/holidays backward)' do
    # no constraints
    action_time = Time.current.round(0).in_time_zone('Eastern Time (US & Canada)').advance(days: 10).utc
    action_time_advanced = action_time.in_time_zone('Eastern Time (US & Canada)').advance(days: -10).utc
    acceptable_time = AcceptableTime.new(
      time_zone:     'Eastern Time (US & Canada)',
      reverse:       true,
      delay_months:  0,
      delay_days:    0,
      delay_hours:   0,
      delay_minutes: 0,
      safe_start:    0,
      safe_end:      1440,
      safe_sun:      true,
      safe_mon:      true,
      safe_tue:      true,
      safe_wed:      true,
      safe_thu:      true,
      safe_fri:      true,
      safe_sat:      true,
      holidays:      { action_time_advanced.to_date => 'backward' },
      ok2skip:       false
    )

    it 'Test AcceptableTime.advance_months' do
      expect(acceptable_time.advance_months(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_days' do
      expect(acceptable_time.advance_days(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_hours' do
      expect(acceptable_time.advance_hours(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_minutes' do
      expect(acceptable_time.advance_minutes(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.new_time' do
      expect(acceptable_time.new_time(action_time).round(0)).to eq(action_time_advanced.advance(days: -1).change(hour: 5))
    end

    it 'Test AcceptableTime.new_time_advance' do
      expect(acceptable_time.new_time_advance(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.safe_time' do
      expect(acceptable_time.safe_time(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.safe_time?' do
      expect(acceptable_time.safe_time?(action_time)).to eq(true)
    end
  end

  describe 'Library: AcceptableTime (leading up to date/target time: 8:00am, safe times: 8:00am - 8:00pm/NO holidays)' do
    # target time: 8:00am
    # safe times:  8:00am to 8:00pm
    action_time = Time.current.round(0).in_time_zone('Eastern Time (US & Canada)').advance(days: 10).change(hour: 8).utc
    action_time_advanced = action_time.in_time_zone('Eastern Time (US & Canada)').advance(days: -10).utc
    acceptable_time = AcceptableTime.new(
      time_zone:     'Eastern Time (US & Canada)',
      reverse:       true,
      delay_months:  0,
      delay_days:    0,
      delay_hours:   0,
      delay_minutes: 0,
      safe_start:    480,
      safe_end:      1200,
      safe_sun:      true,
      safe_mon:      true,
      safe_tue:      true,
      safe_wed:      true,
      safe_thu:      true,
      safe_fri:      true,
      safe_sat:      true,
      holidays:      {},
      ok2skip:       false
    )

    it 'Test AcceptableTime.advance_months' do
      expect(acceptable_time.advance_months(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_days' do
      expect(acceptable_time.advance_days(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_hours' do
      expect(acceptable_time.advance_hours(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_minutes' do
      expect(acceptable_time.advance_minutes(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.new_time' do
      expect(acceptable_time.new_time(action_time).round(0)).to eq(Time.current.round(0))
    end

    it 'Test AcceptableTime.new_time_advance' do
      expect(acceptable_time.new_time_advance(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.safe_time' do
      expect(acceptable_time.safe_time(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.safe_time?' do
      expect(acceptable_time.safe_time?(action_time)).to eq(true)
    end
  end

  describe 'Library: AcceptableTime (leading up to date/target time: 8:00am, safe times: 8:00am - 8:00pm/holidays forward)' do
    # target time: 8:00am
    # safe times:  8:00am to 8:00pm
    action_time = Time.current.round(0).in_time_zone('Eastern Time (US & Canada)').advance(days: 10).change(hour: 8).utc
    action_time_advanced = action_time.in_time_zone('Eastern Time (US & Canada)').advance(days: -10).utc
    acceptable_time = AcceptableTime.new(
      time_zone:     'Eastern Time (US & Canada)',
      reverse:       true,
      delay_months:  0,
      delay_days:    0,
      delay_hours:   0,
      delay_minutes: 0,
      safe_start:    480,
      safe_end:      1200,
      safe_sun:      true,
      safe_mon:      true,
      safe_tue:      true,
      safe_wed:      true,
      safe_thu:      true,
      safe_fri:      true,
      safe_sat:      true,
      holidays:      { action_time_advanced.to_date => 'forward' },
      ok2skip:       false
    )

    it 'Test AcceptableTime.advance_months' do
      expect(acceptable_time.advance_months(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_days' do
      expect(acceptable_time.advance_days(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_hours' do
      expect(acceptable_time.advance_hours(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_minutes' do
      expect(acceptable_time.advance_minutes(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.new_time' do
      expect(acceptable_time.new_time(action_time).round(0)).to eq(Time.current.round(0).advance(days: 1).change(hour: action_time.dst? ? 12 : 13))
    end

    it 'Test AcceptableTime.new_time_advance' do
      expect(acceptable_time.new_time_advance(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.safe_time' do
      expect(acceptable_time.safe_time(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.safe_time?' do
      expect(acceptable_time.safe_time?(action_time)).to eq(true)
    end
  end

  describe 'Library: AcceptableTime (leading up to date/target time: 8:00am, safe times: 8:00am - 8:00pm/holidays backward)' do
    # target time: 8:00am
    # safe times:  8:00am to 8:00pm
    action_time = Time.current.round(0).in_time_zone('Eastern Time (US & Canada)').advance(days: 10).change(hour: 8).utc
    action_time_advanced = action_time.in_time_zone('Eastern Time (US & Canada)').advance(days: -10).utc
    acceptable_time = AcceptableTime.new(
      time_zone:     'Eastern Time (US & Canada)',
      reverse:       true,
      delay_months:  0,
      delay_days:    0,
      delay_hours:   0,
      delay_minutes: 0,
      safe_start:    480,
      safe_end:      1200,
      safe_sun:      true,
      safe_mon:      true,
      safe_tue:      true,
      safe_wed:      true,
      safe_thu:      true,
      safe_fri:      true,
      safe_sat:      true,
      holidays:      { action_time_advanced.to_date => 'backward' },
      ok2skip:       false
    )

    it 'Test AcceptableTime.advance_months' do
      expect(acceptable_time.advance_months(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_days' do
      expect(acceptable_time.advance_days(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_hours' do
      expect(acceptable_time.advance_hours(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_minutes' do
      expect(acceptable_time.advance_minutes(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.new_time' do
      expect(acceptable_time.new_time(action_time).round(0)).to eq(Time.current.round(0).advance(days: -1).change(hour: action_time.dst? ? 12 : 13))
    end

    it 'Test AcceptableTime.new_time_advance' do
      expect(acceptable_time.new_time_advance(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.safe_time' do
      expect(acceptable_time.safe_time(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.safe_time?' do
      expect(acceptable_time.safe_time?(action_time)).to eq(true)
    end
  end

  describe 'Library: AcceptableTime (leading up to date/target time: 3:00am, safe times: 8:00am - 8:00pm/NO holidays)' do
    # target time: 3:00am
    # safe times:  8:00am to 8:00pm
    action_time = Time.current.round(0).in_time_zone('Eastern Time (US & Canada)').advance(days: 10).change(hour: 3).utc
    action_time_advanced = action_time.in_time_zone('Eastern Time (US & Canada)').advance(days: -10).utc
    acceptable_time = AcceptableTime.new(
      time_zone:     'Eastern Time (US & Canada)',
      reverse:       true,
      delay_months:  0,
      delay_days:    0,
      delay_hours:   0,
      delay_minutes: 0,
      safe_start:    480,
      safe_end:      1200,
      safe_sun:      true,
      safe_mon:      true,
      safe_tue:      true,
      safe_wed:      true,
      safe_thu:      true,
      safe_fri:      true,
      safe_sat:      true,
      holidays:      {},
      ok2skip:       false
    )

    it 'Test AcceptableTime.advance_months' do
      expect(acceptable_time.advance_months(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_days' do
      expect(acceptable_time.advance_days(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_hours' do
      expect(acceptable_time.advance_hours(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_minutes' do
      expect(acceptable_time.advance_minutes(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.new_time' do
      expect(acceptable_time.new_time(action_time).round(0)).to eq(Time.current.round(0))
    end

    it 'Test AcceptableTime.new_time_advance' do
      expect(acceptable_time.new_time_advance(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.safe_time' do
      expect(acceptable_time.safe_time(action_time)).to eq(action_time.advance(hours: 5))
    end

    it 'Test AcceptableTime.safe_time?' do
      expect(acceptable_time.safe_time?(action_time)).to eq(false)
    end
  end

  describe 'Library: AcceptableTime (leading up to date/target time: 3:00am, safe times: 8:00am - 8:00pm/holidays forward)' do
    # target time: 3:00am
    # safe times:  8:00am to 8:00pm
    action_time = Time.current.round(0).in_time_zone('Eastern Time (US & Canada)').advance(days: 10).change(hour: 3).utc
    action_time_advanced = action_time.in_time_zone('Eastern Time (US & Canada)').advance(days: -10).utc
    acceptable_time = AcceptableTime.new(
      time_zone:     'Eastern Time (US & Canada)',
      reverse:       true,
      delay_months:  0,
      delay_days:    0,
      delay_hours:   0,
      delay_minutes: 0,
      safe_start:    480,
      safe_end:      1200,
      safe_sun:      true,
      safe_mon:      true,
      safe_tue:      true,
      safe_wed:      true,
      safe_thu:      true,
      safe_fri:      true,
      safe_sat:      true,
      holidays:      { action_time_advanced.to_date => 'forward' },
      ok2skip:       false
    )

    it 'Test AcceptableTime.advance_months' do
      expect(acceptable_time.advance_months(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_days' do
      expect(acceptable_time.advance_days(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_hours' do
      expect(acceptable_time.advance_hours(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_minutes' do
      expect(acceptable_time.advance_minutes(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.new_time' do
      expect(acceptable_time.new_time(action_time).round(0)).to eq(Time.current.round(0).advance(days: 1).change(hour: action_time.dst? ? 12 : 13))
    end

    it 'Test AcceptableTime.new_time_advance' do
      expect(acceptable_time.new_time_advance(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.safe_time' do
      expect(acceptable_time.safe_time(action_time)).to eq(action_time.advance(hours: 5))
    end

    it 'Test AcceptableTime.safe_time?' do
      expect(acceptable_time.safe_time?(action_time)).to eq(false)
    end
  end

  describe 'Library: AcceptableTime (leading up to date/target time: 3:00am, safe times: 8:00am - 8:00pm/holidays backward)' do
    # target time: 3:00am
    # safe times:  8:00am to 8:00pm
    action_time = Time.current.round(0).in_time_zone('Eastern Time (US & Canada)').advance(days: 10).change(hour: 3).utc
    action_time_advanced = action_time.in_time_zone('Eastern Time (US & Canada)').advance(days: -10).utc
    acceptable_time = AcceptableTime.new(
      time_zone:     'Eastern Time (US & Canada)',
      reverse:       true,
      delay_months:  0,
      delay_days:    0,
      delay_hours:   0,
      delay_minutes: 0,
      safe_start:    480,
      safe_end:      1200,
      safe_sun:      true,
      safe_mon:      true,
      safe_tue:      true,
      safe_wed:      true,
      safe_thu:      true,
      safe_fri:      true,
      safe_sat:      true,
      holidays:      { action_time_advanced.to_date => 'backward' },
      ok2skip:       false
    )

    it 'Test AcceptableTime.advance_months' do
      expect(acceptable_time.advance_months(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_days' do
      expect(acceptable_time.advance_days(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_hours' do
      expect(acceptable_time.advance_hours(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.advance_minutes' do
      expect(acceptable_time.advance_minutes(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.new_time' do
      expect(acceptable_time.new_time(action_time).round(0)).to eq(Time.current.round(0).advance(days: -1).change(hour: action_time.dst? ? 12 : 13))
    end

    it 'Test AcceptableTime.new_time_advance' do
      expect(acceptable_time.new_time_advance(action_time)).to eq(action_time)
    end

    it 'Test AcceptableTime.safe_time' do
      expect(acceptable_time.safe_time(action_time)).to eq(action_time.advance(hours: 5))
    end

    it 'Test AcceptableTime.safe_time?' do
      expect(acceptable_time.safe_time?(action_time)).to eq(false)
    end
  end
end
