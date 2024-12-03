# frozen_string_literal: true

# app/models/application_record.rb
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  after_update_commit  :after_update_commit_actions
  after_create_commit  :after_create_commit_actions
  after_destroy_commit :after_destroy_commit_actions

  def self.dynamic_date_range(time_zone, range, current_time = Time.current)
    case range
    when 'td'
      start_date = current_time.in_time_zone(time_zone).beginning_of_day.utc
      end_date   = current_time.in_time_zone(time_zone).end_of_day.utc
    when 'yd'
      start_date = (current_time.in_time_zone(time_zone) - 1.day).beginning_of_day.utc
      end_date   = (current_time.in_time_zone(time_zone) - 1.day).end_of_day.utc
    when 'tw'
      start_date = current_time.in_time_zone(time_zone).beginning_of_week.utc
      end_date   = current_time.in_time_zone(time_zone).end_of_week.utc
    when 'lw'
      start_date = (current_time.in_time_zone(time_zone).beginning_of_week - 1.second).beginning_of_week.utc
      end_date   = (current_time.in_time_zone(time_zone).beginning_of_week - 1.second).end_of_week.utc
    when 'tm'
      start_date = current_time.in_time_zone(time_zone).beginning_of_month.utc
      end_date   = current_time.in_time_zone(time_zone).end_of_month.utc
    when 'lm'
      start_date = (current_time.in_time_zone(time_zone).beginning_of_month - 1.second).beginning_of_month.utc
      end_date   = (current_time.in_time_zone(time_zone).beginning_of_month - 1.second).end_of_month.utc
    when 'tytd'
      start_date = current_time.in_time_zone(time_zone).beginning_of_year.utc
      end_date   = current_time.in_time_zone(time_zone).end_of_year.utc
    when 'lytd'
      start_date = (current_time.in_time_zone(time_zone).beginning_of_year - 1.second).beginning_of_year.utc
      end_date   = (current_time.in_time_zone(time_zone) - 1.year).utc
    when 'ly'
      start_date = (current_time.in_time_zone(time_zone).beginning_of_year - 1.second).beginning_of_year.utc
      end_date   = (current_time.in_time_zone(time_zone).beginning_of_year - 1.second).end_of_year.utc
    when 'l7'
      start_date = (current_time.in_time_zone(time_zone).end_of_day - 7.days).beginning_of_day.utc
      end_date   = current_time.in_time_zone(time_zone).end_of_day.utc
    when 'l30'
      start_date = (current_time.in_time_zone(time_zone).end_of_day - 30.days).beginning_of_day.utc
      end_date   = current_time.in_time_zone(time_zone).end_of_day.utc
    when 'l60'
      start_date = (current_time.in_time_zone(time_zone).end_of_day - 60.days).beginning_of_day.utc
      end_date   = current_time.in_time_zone(time_zone).end_of_day.utc
    when 'l90'
      start_date = (current_time.in_time_zone(time_zone).end_of_day - 90.days).beginning_of_day.utc
      end_date   = current_time.in_time_zone(time_zone).end_of_day.utc
    else
      start_date = current_time.in_time_zone(time_zone).beginning_of_day.utc
      end_date   = current_time.in_time_zone(time_zone).end_of_day.utc
    end

    [start_date, end_date]
  end

  private

  def after_create_commit_actions
    # JsonLog.info 'INSERT', { table: self.class.table_name, attributes: self.attributes }
  end

  def after_destroy_commit_actions
    # JsonLog.info 'DESTROY', { table: self.class.table_name, attributes: self.attributes } if Rails.env.production?
  end

  def after_update_commit_actions
    # JsonLog.info 'UPDATE', { table: self.class.table_name, changes: self.previous_changes, attributes: self.attributes } if Rails.env.production? && self.previous_changes.present?
  end
end
