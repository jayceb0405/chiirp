# frozen_string_literal: true

# app/jobs/application_job.rb
class ApplicationJob < ActiveJob::Base
  # ApplicationJob.set(wait_until: 1.day.from_now).perform_later()
  # ApplicationJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()
  #   (opt) contact_campaign_id: (Integer)
  #   (opt) contact_id:          (Integer)
  #   (opt) data:                (Hash)
  #   (opt) destroy_failed_jobs: (Boolean)
  #   (opt) group_process:       (Integer)
  #   (opt) group_uuid:          (String)
  #   (opt) max_attempts:        (Integer)
  #   (opt) max_run_time:        (Integer)
  #   (opt) priority:            (Integer)
  #   (opt) process:             (String)
  #   (opt) queue_name:          (String or Proc)
  #   (opt) reschedule_secs:     (Integer)
  #   (opt) reschedule_at:       (Time)
  #   (opt) triggeraction_id:    (Integer)
  #   (opt) user_id:             (Integer)

  class MaxReadRequestsPerSecondException < StandardError; end
  class MaxReadRequestsPerMinuteException < StandardError; end
  class MaxReadRequestsPerHourException < StandardError; end
  class MaxReadRequestsPerDayException < StandardError; end

  after_enqueue do |job|
    job_args = job.arguments.first

    if (dj = Delayed::Job.find_by(id: job.provider_job_id))
      dj.update(
        contact_campaign_id: job_args&.dig(:contact_campaign_id).to_i,
        contact_id:          job_args&.dig(:contact_id).to_i,
        data:                (job_args&.dig(:data) || job_args || {}).normalize_non_ascii,
        group_process:       job_args&.dig(:group_process).to_i,
        group_uuid:          job_args&.dig(:group_uuid),
        process:             (job_args&.dig(:process).presence || @process || 'unknown').to_s,
        triggeraction_id:    job_args&.dig(:triggeraction_id).to_i,
        user_id:             job_args&.dig(:user_id).to_i
      )
    end
  end

  retry_on MaxReadRequestsPerSecondException, wait: :polynomially_longer, attempts: 10
  retry_on MaxReadRequestsPerMinuteException, wait: :polynomially_longer, attempts: 10
  retry_on MaxReadRequestsPerHourException, wait: 1.hour, jitter: 0.30, attempts: 5
  retry_on MaxReadRequestsPerDayException, wait: 1.day, jitter: 0.30, attempts: 5

  def initialize(**args)
    super

    @process          = (args.dig(:process).presence || 'process_name').to_s
    @reschedule_secs  = 0
  end

  def after(job); end

  def before(job); end

  def destroy_failed_jobs?
    false
  end

  def error(_job, exception)
    @exception = exception
  end

  def failure(job)
    JsonLog.info "#{self.class}.#{__method__}", { job: }
  end

  def max_attempts
    3
  end

  def max_run_time
    360 # seconds (6 minutes)
  end

  # perform the ActiveJob
  def perform(**args); end

  def priority
    @priority ||= DelayedJob.job_priority(@process)
  end

  def queue_name
    @queue_name.is_a?(Proc) ? DelayedJob.job_queue(@process) : @queue_name
  end

  def reschedule_at(current_time, attempts)
    if @reschedule_secs.positive?
      current_time + @reschedule_secs.seconds
    else
      current_time + ProcessError::Backoff.full_jitter(base: 1, cap: 30, retries: attempts).minutes
    end
  end

  def success(job); end
end
