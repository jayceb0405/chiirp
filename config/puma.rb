# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
workers Integer(ENV['WEB_CONCURRENCY'] || 2)
max_threads_count = Integer(ENV['RAILS_MAX_THREADS'] || 5)
min_threads_count = Integer(ENV['RAILS_MIN_THREADS'] || max_threads_count)
threads min_threads_count, max_threads_count

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
preload_app!

rackup      DefaultRackup if defined?(DefaultRackup)
port        ENV['PORT']      || 3000
environment ENV['RAILS_ENV'] || 'development'

on_worker_boot do
  # Worker-specific setup for Rails 4.1 to 5.2, after 5.2 it's not needed
  # See: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
  ActiveRecord::Base.establish_connection
end

# Specifies the `pidfile` that Puma will use.
pidfile ENV['PIDFILE'] || 'tmp/pids/server.pid'

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart
