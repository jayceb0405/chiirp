# frozen_string_literal: true

# app/models/clients/holiday.rb
module Clients
  class Holiday < ApplicationRecord
    self.table_name = 'client_holidays'

    belongs_to :client

    ACTIONS = {
      'before' => 'Send Before',
      'after'  => 'Send After',
      'skip'   => 'Don\'t Send'
    }.freeze
    HOLIDAYS = {
      '12/25/2023' => 'Christmas Day 2023',
      '01/01/2024' => 'New Years Day 2024',
      '11/28/2024' => 'Thanksgiving Day 2024',
      '12/25/2024' => 'Christmas Day 2024',
      '01/01/2025' => 'New Years Day 2025',
      '11/27/2025' => 'Thanksgiving Day 2025',
      '12/25/2025' => 'Christmas Day 2025',
      '01/01/2026' => 'New Years Day 2026',
      '11/26/2026' => 'Thanksgiving Day 2026',
      '12/25/2026' => 'Christmas Day 2026'
    }.freeze

    def action_title
      ACTIONS.dig(self.action)
    end

    # adjust all jobs in DelayedJob that fall on the holiday
    # holiday.adjust_delayed_jobs
    def adjust_delayed_jobs
      delayed_jobs = DelayedJob.left_joins(:contact).where(contact: { client_id: self.client_id }).or(DelayedJob.where(user_id: User.select(:id).where(client_id: self.client_id)))
                               .where(run_at: [self.occurs_at.to_datetime..self.occurs_at.to_datetime.advance(hours: 23, minutes: 59, seconds: 59)])
                               .where(process: %w[group_start_campaign group_send_rvm group_send_text start_campaign send_text send_rvm])
      time_zone    = self.client.time_zone
      holidays     = self.client.holidays.to_h { |h| [h.occurs_at, h.action] }
      common_args  = {
        time_zone:,
        reverse:       false,
        delay_months:  0,
        delay_days:    0,
        delay_hours:   0,
        delay_minutes: 0,
        safe_start:    480,
        safe_end:      1200,
        safe_sun:      false,
        safe_mon:      true,
        safe_tue:      true,
        safe_wed:      true,
        safe_thu:      true,
        safe_fri:      true,
        safe_sat:      false,
        holidays:,
        ok2skip:       false
      }

      if self.action == 'skip'
        delayed_jobs.delete_all
      else

        delayed_jobs.find_each do |dj|
          temp_common_args = if dj.triggeraction_id.present? && (triggeraction = Triggeraction.find_by(id: dj.triggeraction_id))
                               {
                                 time_zone:,
                                 reverse:       false,
                                 delay_months:  0,
                                 delay_days:    0,
                                 delay_hours:   0,
                                 delay_minutes: 0,
                                 safe_start:    (triggeraction.safe_start || 480).to_i,
                                 safe_end:      (triggeraction.safe_end || 1200).to_i,
                                 safe_sun:      (triggeraction.safe_sun || false).to_bool,
                                 safe_mon:      (triggeraction.safe_mon || true).to_bool,
                                 safe_tue:      (triggeraction.safe_tue || true).to_bool,
                                 safe_wed:      (triggeraction.safe_wed || true).to_bool,
                                 safe_thu:      (triggeraction.safe_thu || true).to_bool,
                                 safe_fri:      (triggeraction.safe_fri || true).to_bool,
                                 safe_sat:      (triggeraction.safe_sat || false).to_bool,
                                 holidays:,
                                 ok2skip:       (triggeraction.ok2skip || false).to_bool
                               }
                             else
                               common_args
                             end

          dj.update(run_at: AcceptableTime.new(temp_common_args).new_time(dj.run_at))
        end
      end
    end
  end
end
