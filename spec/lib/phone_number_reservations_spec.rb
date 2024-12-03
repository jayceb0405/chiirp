# frozen_string_literal: true

# spec/lib/phone_number_reservations_spec.rb
# foreman run rspec spec/lib/phone_number_reservations_spec.rb
require 'rails_helper'

describe 'Library: PhoneNumberReservations (NO constraints)' do
  before(:all) do
    @phone_number = '1234567890'
    @common_args  = {
      interval:   10,
      time_zone:  'Eastern Time (US & Canada)',
      safe_start: 0,
      safe_end:   1440,
      safe_sun:   true,
      safe_mon:   true,
      safe_tue:   true,
      safe_wed:   true,
      safe_thu:   true,
      safe_fri:   true,
      safe_sat:   true
    }
    @action_time = Time.current
    REDIS_POOL.with { |client| client.setex("phone_number_reservations:#{@phone_number}:#{Time.current.strftime('%Y-%m-%d')}", 60, []) }
    @phone_number_reservations = PhoneNumberReservations.new(@phone_number)
    @action_time = @phone_number_reservations.normalize_time(@action_time, @common_args[:interval])
  end

  it 'Test PhoneNumberReservations.phone_number' do
    expect(@phone_number_reservations.phone_number).to eq(@phone_number)
  end

  it 'Test PhoneNumberReservations.reserve immediately 01' do
    expect(@phone_number_reservations.reserve(
             @common_args.merge(action_time: @action_time)
           )).to eq(@action_time)
  end

  it 'Test PhoneNumberReservations.reserve immediately 02' do
    expect(@phone_number_reservations.reserve(
             @common_args.merge(action_time: @action_time)
           )).to eq(@action_time + @common_args[:interval].seconds)
  end

  it 'Test PhoneNumberReservations.reserve immediately 03' do
    expect(@phone_number_reservations.reserve(
             @common_args.merge(action_time: @action_time)
           )).to eq(@action_time + (@common_args[:interval] * 2).seconds)
  end

  it 'Test PhoneNumberReservations.reserve in 1 hour 01' do
    expect(@phone_number_reservations.reserve(
             @common_args.merge(action_time: @action_time + 1.hour)
           )).to eq(@action_time + 1.hour)
  end

  it 'Test PhoneNumberReservations.reserve in 1 hour 02' do
    expect(@phone_number_reservations.reserve(
             @common_args.merge(action_time: @action_time + 1.hour)
           )).to eq(@action_time + 1.hour + @common_args[:interval].seconds)
  end

  it 'Test PhoneNumberReservations.reserve in 1 hour 03' do
    expect(@phone_number_reservations.reserve(
             @common_args.merge(action_time: @action_time + 1.hour)
           )).to eq(@action_time + 1.hour + (@common_args[:interval] * 2).seconds)
  end
end

describe 'Library: PhoneNumberReservations (target time: 8:00am, safe times: 8:00am - 8:00pm)' do
  before(:all) do
    @phone_number = '1234567890'
    @common_args  = {
      interval:   10,
      time_zone:  'Eastern Time (US & Canada)',
      safe_start: 480,
      safe_end:   1200,
      safe_sun:   true,
      safe_mon:   true,
      safe_tue:   true,
      safe_wed:   true,
      safe_thu:   true,
      safe_fri:   true,
      safe_sat:   true
    }
    @action_time = Time.current.in_time_zone('Eastern Time (US & Canada)').change(hour: 8).utc + 1.day
    REDIS_POOL.with { |client| client.setex("phone_number_reservations:#{@phone_number}:#{1.day.from_now.strftime('%Y-%m-%d')}", 60, []) }
    @phone_number_reservations = PhoneNumberReservations.new(@phone_number)
    @action_time = @phone_number_reservations.normalize_time(@action_time, @common_args[:interval])
  end

  it 'Test PhoneNumberReservations.phone_number' do
    expect(@phone_number_reservations.phone_number).to eq(@phone_number)
  end

  it 'Test PhoneNumberReservations.reserve immediately 01' do
    expect(@phone_number_reservations.reserve(
             @common_args.merge(action_time: @action_time)
           )).to eq(@action_time)
  end

  it 'Test PhoneNumberReservations.reserve immediately 02' do
    expect(@phone_number_reservations.reserve(
             @common_args.merge(action_time: @action_time)
           )).to eq(@action_time + @common_args[:interval].seconds)
  end

  it 'Test PhoneNumberReservations.reserve immediately 03' do
    expect(@phone_number_reservations.reserve(
             @common_args.merge(action_time: @action_time)
           )).to eq(@action_time + (@common_args[:interval] * 2).seconds)
  end

  it 'Test PhoneNumberReservations.reserve in 1 hour 01' do
    expect(@phone_number_reservations.reserve(
             @common_args.merge(action_time: @action_time + 1.hour)
           )).to eq(@action_time + 1.hour)
  end

  it 'Test PhoneNumberReservations.reserve in 1 hour 02' do
    expect(@phone_number_reservations.reserve(
             @common_args.merge(action_time: @action_time + 1.hour)
           )).to eq(@action_time + 1.hour + @common_args[:interval].seconds)
  end

  it 'Test PhoneNumberReservations.reserve in 1 hour 03' do
    expect(@phone_number_reservations.reserve(
             @common_args.merge(action_time: @action_time + 1.hour)
           )).to eq(@action_time + 1.hour + (@common_args[:interval] * 2).seconds)
  end
end

describe 'Library: PhoneNumberReservations (target time: 3:00am, safe times: 8:00am - 8:00pm)' do
  before(:all) do
    @phone_number = '1234567890'
    @common_args  = {
      interval:   10,
      time_zone:  'Eastern Time (US & Canada)',
      safe_start: 480,
      safe_end:   1200,
      safe_sun:   true,
      safe_mon:   true,
      safe_tue:   true,
      safe_wed:   true,
      safe_thu:   true,
      safe_fri:   true,
      safe_sat:   true
    }
    @action_time = Time.current.in_time_zone('Eastern Time (US & Canada)').change(hour: 3).utc + 1.day
    REDIS_POOL.with { |client| client.setex("phone_number_reservations:#{@phone_number}:#{1.day.from_now.strftime('%Y-%m-%d')}", 60, []) }
    @phone_number_reservations = PhoneNumberReservations.new(@phone_number)
    @action_time = @phone_number_reservations.normalize_time(@action_time, @common_args[:interval])
  end

  it 'Test PhoneNumberReservations.phone_number' do
    expect(@phone_number_reservations.phone_number).to eq(@phone_number)
  end

  it 'Test PhoneNumberReservations.reserve immediately 01' do
    expect(@phone_number_reservations.reserve(
             @common_args.merge(action_time: @action_time)
           )).to eq(@action_time + 5.hours)
  end

  it 'Test PhoneNumberReservations.reserve immediately 02' do
    expect(@phone_number_reservations.reserve(
             @common_args.merge(action_time: @action_time)
           )).to eq(@action_time + 5.hours + @common_args[:interval].seconds)
  end

  it 'Test PhoneNumberReservations.reserve immediately 03' do
    expect(@phone_number_reservations.reserve(
             @common_args.merge(action_time: @action_time)
           )).to eq(@action_time + 5.hours + (@common_args[:interval] * 2).seconds)
  end

  it 'Test PhoneNumberReservations.reserve in 1 hour 01' do
    expect(@phone_number_reservations.reserve(
             @common_args.merge(action_time: @action_time + 1.hour)
           )).to eq(@action_time + 5.hours + (@common_args[:interval] * 3).seconds)
  end

  it 'Test PhoneNumberReservations.reserve in 1 hour 02' do
    expect(@phone_number_reservations.reserve(
             @common_args.merge(action_time: @action_time + 1.hour)
           )).to eq(@action_time + 5.hours + + (@common_args[:interval] * 4).seconds)
  end

  it 'Test PhoneNumberReservations.reserve in 1 hour 03' do
    expect(@phone_number_reservations.reserve(
             @common_args.merge(action_time: @action_time + 1.hour)
           )).to eq(@action_time + 5.hours + (@common_args[:interval] * 5).seconds)
  end
end

describe 'Library: PhoneNumberReservations (target time: 11:00pm, safe times: 8:00am - 8:00pm)' do
  before(:all) do
    # freeze time at 5am on Oct 1, 2023
    Timecop.freeze(Time.new(2023, 10, 1, 5, 0, 0).in_time_zone('Eastern Time (US & Canada)'))

    @phone_number = '1234567890'
    @common_args  = {
      interval:   10,
      time_zone:  'Eastern Time (US & Canada)',
      safe_start: 480,
      safe_end:   1200,
      safe_sun:   true,
      safe_mon:   true,
      safe_tue:   true,
      safe_wed:   true,
      safe_thu:   true,
      safe_fri:   true,
      safe_sat:   true
    }
    @action_time = Time.current.in_time_zone('Eastern Time (US & Canada)').change(hour: 23).utc + 1.day
    puts @action_time
    REDIS_POOL.with { |client| client.setex("phone_number_reservations:#{@phone_number}:#{@action_time.strftime('%Y-%m-%d')}", 60, []) }
    @phone_number_reservations = PhoneNumberReservations.new(@phone_number)
    @action_time = @phone_number_reservations.normalize_time(@action_time, @common_args[:interval])
  end

  after(:all) do
    # unfreeze time
    Timecop.return
  end

  it 'Test PhoneNumberReservations.phone_number' do
    expect(@phone_number_reservations.phone_number).to eq(@phone_number)
  end

  it 'Test PhoneNumberReservations.reserve immediately 01' do
    expect(@phone_number_reservations.reserve(
             @common_args.merge(action_time: @action_time)
           )).to eq(@action_time + 9.hours)
  end

  it 'Test PhoneNumberReservations.reserve immediately 02' do
    expect(@phone_number_reservations.reserve(
             @common_args.merge(action_time: @action_time)
           )).to eq(@action_time + 9.hours + @common_args[:interval].seconds)
  end

  it 'Test PhoneNumberReservations.reserve immediately 03' do
    expect(@phone_number_reservations.reserve(
             @common_args.merge(action_time: @action_time)
           )).to eq(@action_time + 9.hours + (@common_args[:interval] * 2).seconds)
  end

  it 'Test PhoneNumberReservations.reserve in 1 hour 01' do
    expect(@phone_number_reservations.reserve(
             @common_args.merge(action_time: @action_time + 1.hour)
           )).to eq(@action_time + 9.hours + (@common_args[:interval] * 3).seconds)
  end

  it 'Test PhoneNumberReservations.reserve in 1 hour 02' do
    expect(@phone_number_reservations.reserve(
             @common_args.merge(action_time: @action_time + 1.hour)
           )).to eq(@action_time + 9.hours + + (@common_args[:interval] * 4).seconds)
  end

  it 'Test PhoneNumberReservations.reserve in 1 hour 03' do
    expect(@phone_number_reservations.reserve(
             @common_args.merge(action_time: @action_time + 1.hour)
           )).to eq(@action_time + 9.hours + (@common_args[:interval] * 5).seconds)
  end
end
