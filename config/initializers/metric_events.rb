# frozen_string_literal: true

# config/initializers/events.rb
# instrument the perform.active_job event and send data to appsignal
ActiveSupport::Notifications.monotonic_subscribe('perform.active_job') do |event|
  # send accurate duration data to appsignal
  Appsignal.add_distribution_value('active_job_duration', event.duration, queue: event.payload[:job].queue_name)
end

ActiveSupport::Notifications.monotonic_subscribe('process_action.action_controller') do |event|
  next if event.payload[:controller] == 'HealthCheckController'

  Appsignal.add_distribution_value('action_controller_process_action', event.duration, controller: event.payload[:controller], action: event.payload[:action])
  # StatsD.measure('ActionControllerProcessAction', event.duration, tags: { Environment: Rails.env.to_s, Controller: event.payload[:controller], Action: event.payload[:action] })
end

ActiveSupport::Notifications.subscribe('perform.active_job') do |_name, _start, finish, _id, payload|
  # send lag data to appsignal
  lag_s = begin
    finish - (payload[:job].scheduled_at || payload[:job].enqueued_at)
  rescue StandardError
    nil
  end

  if lag_s
    Appsignal.add_distribution_value('active_job_lag', lag_s * 1000, queue: payload[:job].queue_name)
    # StatsD.measure('QueueLag', lag_s * 1000, tags: { Environment: Rails.env.to_s, Queue: payload[:job].queue_name })
  end
end
