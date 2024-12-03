# /Users/Kevin/Rails Projects/funyl/spec/models/client_spec.rb
# foreman run rspec spec/models/client_spec.rb
require 'rails_helper'

describe Client, :special do
  time_current = Time.current.to_date

  (1..366).each do |current_day|
    it "Test Client.first_payment_date using date: #{time_current}, created_at: #{time_current - current_day.days}, current_day: #{current_day}" do
      client = Client.new(created_at: (time_current - current_day.days))
      expect(client.first_payment_date).to eq((time_current - current_day.days))
    end
  end

  (1..366).each do |current_day|
    it "Test Client.first_payment_date using date: #{time_current}, created_at: #{time_current - current_day.days}, current_day: #{current_day}, first_payment_delay_days: 14" do
      client = Client.new(created_at: (time_current - current_day.days), first_payment_delay_days: 14)
      expect(client.first_payment_date).to eq((time_current - current_day.days) + 14.days)
    end
  end

  (1..366).each do |current_day|
    it "Test Client.first_payment_date using date: #{time_current}, created_at: #{time_current - current_day.days}, current_day: #{current_day}, first_payment_delay_months: 2" do
      client = Client.new(created_at: (time_current - current_day.days), first_payment_delay_months: 2)
      expect(client.first_payment_date).to eq((time_current - current_day.days) + 2.months)
    end
  end

  (1..366).each do |current_day|
    it "Test Client.first_payment_date using date: #{time_current}, created_at: #{time_current - current_day.days}, current_day: #{current_day}, first_payment_delay_days: 14, first_payment_delay_months: 3" do
      client = Client.new(created_at: (time_current - current_day.days), first_payment_delay_days: 14, first_payment_delay_months: 3)
      expect(client.first_payment_date).to eq((time_current - current_day.days) + 14.days + 3.months)
    end
  end

  (1..366).each do |current_day|
    client = Client.new(created_at: (time_current - current_day.days))

    it "Test Client.next_payment_date using date: #{time_current}, created_at: #{time_current - current_day.days}, current_day: #{current_day}" do
      expected_payment_date = Time.current.change(day: client.created_at.day).to_date
      expected_payment_date += 1.month unless expected_payment_date.future?
      expect(client.next_payment_date).to eq(expected_payment_date)
    end

    it "Test Client.within_promo_period? using date: #{time_current}, created_at: #{time_current - current_day.days}, current_day: #{current_day}" do
      expect(client.within_promo_period?(time_current)).to eq(false)
    end
  end

  (1..366).each do |current_day|
    client = Client.new(created_at: (time_current - current_day.days), promo_months: 2)

    it "Test Client.next_payment_date using date: #{time_current}, created_at: #{time_current - current_day.days}, current_day: #{current_day}, promo_months: 2" do
      expected_payment_date = Time.current.change(day: client.created_at.day).to_date
      expected_payment_date += 1.month unless expected_payment_date.future?
      expect(client.next_payment_date).to eq(expected_payment_date)
    end

    it "Test Client.within_promo_period? using date: #{time_current}, created_at: #{time_current - current_day.days}, current_day: #{current_day}, promo_months: 2" do
      expect(client.within_promo_period?(time_current)).to eq((client.first_payment_date + client.promo_months.months) > time_current)
    end
  end

  (1..366).each do |current_day|
    client = Client.new(created_at: (time_current - current_day.days), first_payment_delay_days: 14)

    it "Test Client.next_payment_date using date: #{time_current}, created_at: #{time_current - current_day.days}, current_day: #{current_day}, first_payment_delay_days: 14" do
      expected_payment_date = client.first_payment_date.to_date + (((time_current.year * 12) + time_current.month) - ((client.first_payment_date.year * 12) + client.first_payment_date.month)).month
      expected_payment_date += 1.month unless expected_payment_date.future?
      expect(client.next_payment_date).to eq(expected_payment_date)
    end

    it "Test Client.within_promo_period? using date: #{time_current}, created_at: #{time_current - current_day.days}, current_day: #{current_day}, first_payment_delay_days: 14" do
      expect(client.within_promo_period?(time_current)).to eq(false)
    end
  end

  (1..366).each do |current_day|
    client = Client.new(created_at: (time_current - current_day.days), first_payment_delay_days: 14, promo_months: 2)

    it "Test Client.next_payment_date using date: #{time_current}, created_at: #{time_current - current_day.days}, current_day: #{current_day}, first_payment_delay_days: 14, promo_months: 2" do
      expected_payment_date = client.first_payment_date.to_date + (((time_current.year * 12) + time_current.month) - ((client.first_payment_date.year * 12) + client.first_payment_date.month)).month
      expected_payment_date += 1.month unless expected_payment_date.future?
      expect(client.next_payment_date).to eq(expected_payment_date)
    end

    it "Test Client.within_promo_period? using date: #{time_current}, created_at: #{time_current - current_day.days}, current_day: #{current_day}, first_payment_delay_days: 14, promo_months: 2" do
      expect(client.within_promo_period?(time_current)).to eq((client.first_payment_date + client.promo_months.months) > time_current)
    end
  end

  (1..366).each do |current_day|
    client = Client.new(created_at: (time_current - current_day.days), first_payment_delay_months: 2)

    it "Test Client.next_payment_date using date: #{time_current}, created_at: #{time_current - current_day.days}, current_day: #{current_day}, first_payment_delay_months: 2" do
      expected_payment_date = client.first_payment_date.to_date + (((time_current.year * 12) + time_current.month) - ((client.first_payment_date.year * 12) + client.first_payment_date.month)).month
      expected_payment_date += 1.month unless expected_payment_date.future?
      expect(client.next_payment_date).to eq(expected_payment_date)
    end

    it "Test Client.within_promo_period? using date: #{time_current}, created_at: #{time_current - current_day.days}, current_day: #{current_day}, first_payment_delay_months: 2" do
      expect(client.within_promo_period?(time_current)).to eq(false)
    end
  end

  (1..366).each do |current_day|
    client = Client.new(created_at: (time_current - current_day.days), first_payment_delay_months: 2, promo_months: 2)

    it "Test Client.next_payment_date using date: #{time_current}, created_at: #{time_current - current_day.days}, current_day: #{current_day}, first_payment_delay_months: 2, promo_months: 2" do
      expected_payment_date = client.first_payment_date.to_date + (((time_current.year * 12) + time_current.month) - ((client.first_payment_date.year * 12) + client.first_payment_date.month)).month
      expected_payment_date += 1.month unless expected_payment_date.future?
      expect(client.next_payment_date).to eq(expected_payment_date)
    end

    it "Test Client.within_promo_period? using date: #{time_current}, created_at: #{time_current - current_day.days}, current_day: #{current_day}, first_payment_delay_months: 2, promo_months: 2" do
      expect(client.within_promo_period?(time_current)).to eq((client.first_payment_date + client.promo_months.months) > time_current)
    end
  end

  (1..366).each do |current_day|
    client = Client.new(created_at: (time_current - current_day.days), first_payment_delay_days: 14, first_payment_delay_months: 3)

    it "Test Client.next_payment_date using date: #{time_current}, created_at: #{time_current - current_day.days}, current_day: #{current_day}, first_payment_delay_days: 14, first_payment_delay_months: 3" do
      expected_payment_date = client.first_payment_date.to_date + (((time_current.year * 12) + time_current.month) - ((client.first_payment_date.year * 12) + client.first_payment_date.month)).month
      expected_payment_date += 1.month unless expected_payment_date.future?
      expect(client.next_payment_date).to eq(expected_payment_date)
    end

    it "Test Client.within_promo_period? using date: #{time_current}, created_at: #{time_current - current_day.days}, current_day: #{current_day}, first_payment_delay_days: 14, first_payment_delay_months: 3" do
      expect(client.within_promo_period?(time_current)).to eq(false)
    end
  end

  (1..366).each do |current_day|
    client = Client.new(created_at: (time_current - current_day.days), first_payment_delay_days: 14, first_payment_delay_months: 3, promo_months: 2)

    it "Test Client.next_payment_date using date: #{time_current}, created_at: #{time_current - current_day.days}, current_day: #{current_day}, first_payment_delay_days: 14, first_payment_delay_months: 3, promo_months: 2" do
      # expected_payment_date = (client.created_at + 3.months + 14.days).to_date + ((time_current.year * 12 + time_current.month) - ((client.created_at + 3.months + 14.days).year * 12 + (client.created_at + 3.months + 14.days).month)).month
      expected_payment_date = client.first_payment_date.to_date + (((time_current.year * 12) + time_current.month) - ((client.first_payment_date.year * 12) + client.first_payment_date.month)).month
      expected_payment_date += 1.month unless expected_payment_date.future?
      expect(client.next_payment_date).to eq(expected_payment_date)
    end

    it "Test Client.within_promo_period? using date: #{time_current}, created_at: #{time_current - current_day.days}, current_day: #{current_day}, first_payment_delay_days: 14, first_payment_delay_months: 3, promo_months: 2" do
      expect(client.within_promo_period?(time_current)).to eq((client.first_payment_date + client.promo_months.months) > time_current)
    end
  end
end
