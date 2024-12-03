# frozen_string_literal: true

# app/jobs/queue_metrics_job.rb
class QueueMetricsJob < ApplicationJob
  # description of this job
  # QueueMetricsJob.perform_now()
  # QueueMetricsJob.set(wait_until: 1.day.from_now).perform_later()
  # QueueMetricsJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
  def initialize(**args)
    super

    @process = (args.dig(:process).presence || 'queue_metrics').to_s
  end

  # perform the ActiveJob
  def perform(**args)
    super

    # TODO: this list needs to be updated as queues are added/removed
    # this should stay in sync with Tofu configuration
    all_queues = %w[campaigns
                    default
                    housecallpro
                    imports
                    integrations
                    jobber
                    notify
                    secondary
                    servicemonster
                    servicetitan
                    servicetitannotes
                    servicetitanupdates
                    urgent
                    zapier]

    # get the queue metrics
    # do we need to set empty queues to zero or can we assume zero?
    queues = Delayed::Job.where(run_at: ...Time.current).where(failed_at: nil).group(:queue).count(:queue)

    # merge the queues with the empty queues
    queues = all_queues.index_with { |queue| queues[queue] || 0 }

    data = {
      namespace:   'Chiirp',
      metric_data: queues.map do |queue, count|
                     {
                       metric_name: 'QueueLength',
                       dimensions:  [
                         {
                           name:  'Queue',
                           value: queue
                         },
                         {
                           name:  'Environment',
                           value: Rails.env
                         }
                       ],
                       timestamp:   Time.current,
                       value:       count,
                       unit:        'Count'
                     }
                   end
    }

    # post metrics to AWS CloudWatch
    client = Aws::CloudWatch::Client.new
    client.put_metric_data(data)
  end
end
