# frozen_string_literal: true

# app/models/version.rb
class Version < ApplicationRecord
  store_accessor :data, :tenants

  validates :start_date, presence: true

  private

  def after_create_commit_actions
    super

    update_version_notification
  end

  def update_version_notification
    # rubocop:disable Rails/SkipsModelValidations
    User.all_users.update_all("data = jsonb_set(data, '{version_notification}', to_json(true::boolean)::jsonb)")
    # rubocop:enable Rails/SkipsModelValidations

    User.delay(
      run_at:              Time.current,
      priority:            DelayedJob.job_priority('send_push'),
      queue:               DelayedJob.job_queue('send_push'),
      user_id:             0,
      contact_id:          0,
      triggeraction_id:    0,
      contact_campaign_id: 0,
      group_process:       0,
      process:             'send_push',
      data:                { content: "New Version: #{self.header}" }
    ).notify_all_users(target: %w[toast], content: "New Version: #{self.header}")
  end
end
