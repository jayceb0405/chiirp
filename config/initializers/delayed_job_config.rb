# require 'acceptable_time'
# require 'user_cable'
require 'delayed_jobs_plugins'

Delayed::Worker.default_priority = 0
Delayed::Worker.destroy_failed_jobs = false
# Delayed::Worker.sleep_delay = 60
Delayed::Worker.sleep_delay = 5
Delayed::Worker.max_attempts = 3
Delayed::Worker.max_run_time = 30.minutes
Delayed::Worker.read_ahead = 10
Delayed::Worker.default_queue_name = 'default'

Delayed::Worker.delay_jobs = !Rails.env.test?
# Delayed::Worker.delay_jobs = false

# By default, Signals INT and TERM set @exit, and the worker exits upon completion of the current job.
# If you would prefer to raise a SignalException and exit immediately you can use this.
# Be aware daemons uses TERM to stop and restart
# false - No exceptions will be raised
# :term - Will only raise an exception on TERM signals but INT will wait for the current job to finish
# true - Will raise an exception on TERM and INT
Delayed::Worker.raise_signal_exceptions = :term

Delayed::Worker.plugins << DelayedJobsPlugins

# Delayed::Worker.logger = Rails.logger
# Delayed::Worker.logger = Logger.new(STDOUT)
# Delayed::Worker.logger = ActiveSupport::Logger.new(STDOUT)
# Delayed::Worker.logger = Logger.new(Rails.root.join('log/delayed_job.log').to_s)
Delayed::Worker.logger = nil
