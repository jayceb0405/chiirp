# frozen_string_literal: true

# app/jobs/sample_job.rb
class SampleJob < ApplicationJob
  # description of this job
  # SampleJob.perform_now()
  # SampleJob.set(wait_until: 1.day.from_now).perform_later()
  # SampleJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
  def initialize(**args)
    super

    @process = (args.dig(:process).presence || 'sample_job').to_s
  end

  # perform the ActiveJob
  def perform(**args)
    super
  end
end
