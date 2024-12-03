# /Users/Kevin/Rails Projects/funyl/spec/models/application_spec.rb
# foreman run rspec spec/models/application_spec.rb
require 'rails_helper'

RSpec.describe Client do
  time_zone    = 'Eastern Time (US & Canada)'

  (0..11).each do |month|
    current_time = Time.current.in_time_zone(time_zone) + month.months

    it "verify dynamic_date_range ?? / current_time: #{current_time}" do
      expect(Client.dynamic_date_range(time_zone, '', current_time)).to eq([current_time.beginning_of_day.utc, current_time.end_of_day.utc])
    end

    it "verify dynamic_date_range td / current_time: #{current_time}" do
      expect(Client.dynamic_date_range(time_zone, 'td', current_time)).to eq([current_time.beginning_of_day.utc, current_time.end_of_day.utc])
    end

    it "verify dynamic_date_range yd / current_time: #{current_time}" do
      expect(Client.dynamic_date_range(time_zone, 'yd', current_time)).to eq([(current_time - 1.day).beginning_of_day.utc, (current_time - 1.day).end_of_day.utc])
    end

    it "verify dynamic_date_range tw / current_time: #{current_time}" do
      expect(Client.dynamic_date_range(time_zone, 'tw', current_time)).to eq([current_time.beginning_of_week.utc, current_time.end_of_week.utc])
    end

    it "verify dynamic_date_range lw / current_time: #{current_time}" do
      expect(Client.dynamic_date_range(time_zone, 'lw', current_time)).to eq([(current_time - 1.week).beginning_of_week.utc, (current_time - 1.week).end_of_week.utc])
    end

    it "verify dynamic_date_range tm / current_time: #{current_time}" do
      expect(Client.dynamic_date_range(time_zone, 'tm', current_time)).to eq([current_time.beginning_of_month.utc, current_time.end_of_month.utc])
    end

    it "verify dynamic_date_range lm / current_time: #{current_time}" do
      expect(Client.dynamic_date_range(time_zone, 'lm', current_time)).to eq([(current_time - 1.month).beginning_of_month.utc, (current_time - 1.month).end_of_month.utc])
    end

    it "verify dynamic_date_range tytd / current_time: #{current_time}" do
      expect(Client.dynamic_date_range(time_zone, 'tytd', current_time)).to eq([current_time.beginning_of_year.utc, current_time.end_of_year.utc])
    end

    it "verify dynamic_date_range lytd / current_time: #{current_time}" do
      expect(Client.dynamic_date_range(time_zone, 'lytd', current_time)).to eq([(current_time - 1.year).beginning_of_year.utc, (current_time - 1.year).utc])
    end

    it "verify dynamic_date_range ly / current_time: #{current_time}" do
      expect(Client.dynamic_date_range(time_zone, 'ly', current_time)).to eq([(current_time - 1.year).beginning_of_year.utc, (current_time - 1.year).end_of_year.utc])
    end

    it "verify dynamic_date_range l7 / current_time: #{current_time}" do
      expect(Client.dynamic_date_range(time_zone, 'l7', current_time)).to eq([(current_time - 7.days).beginning_of_day.utc, current_time.end_of_day.utc])
    end

    it "verify dynamic_date_range l30 / current_time: #{current_time}" do
      expect(Client.dynamic_date_range(time_zone, 'l30', current_time)).to eq([(current_time - 30.days).beginning_of_day.utc, current_time.end_of_day.utc])
    end

    it "verify dynamic_date_range l60 / current_time: #{current_time}" do
      expect(Client.dynamic_date_range(time_zone, 'l60', current_time)).to eq([(current_time - 60.days).beginning_of_day.utc, current_time.end_of_day.utc])
    end

    it "verify dynamic_date_range l90 / current_time: #{current_time}" do
      expect(Client.dynamic_date_range(time_zone, 'l90', current_time)).to eq([(current_time - 90.days).beginning_of_day.utc, current_time.end_of_day.utc])
    end
  end
end
