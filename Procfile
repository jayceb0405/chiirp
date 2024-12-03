web: bundle exec rails server -p $PORT
worker: env QUEUE=default bundle exec rake jobs:work
clock: bundle exec clockwork clock.rb
