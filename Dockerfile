FROM ruby:3.3.4-bullseye

ARG APP_REVISION
ARG RAILS_ENV=production

ENV RAILS_SERVE_STATIC_FILES=true \
  RAILS_ENV=$RAILS_ENV \
  RACK_ENV=$RAILS_ENV \
  STATSD_ENV=$RAILS_ENV \
  STATSD_ADDR=172.17.0.1:8125 \
  RAILS_LOG_TO_STDOUT=enabled \
  RAILS_SERVE_STATIC_FILES=enabled \
  RAILS_MAX_THREADS=4 \
  WEB_CONCURRENCY=2 \
  NPM_CONFIG_PRODUCTION=true \
  REDIS_URL=redis://localhost:6379/0 \
  RUBYOPT='--yjit' \
  LANG=en_US.UTF-8 \
  chiirp_sitechat_key="" \
  chiirp_sitechat_version="" \
  mini_domain="{\"chiirp\":\"chiirp1.com/tl\"}" \
  user_contact_form_domains="30secondmortgagequiz,30secondroofquiz,chrplink,chrpweb,homeservicessurvey,reptxt1,sharesuccessteam,solarhomesurvey,textt,carpetcleaner.pro" \
  AWS_REGION=us-east-1 \
  PIDFILE=tmp/puma.pid \
  NODE_OPTIONS=--openssl-legacy-provider \
  APP_REVISION=$APP_REVISION

RUN apt-get update \
  && apt-get -y install libhunspell-dev hunspell-en-us ffmpeg libvips-dev libvips-tools libvips chromium chromium-driver \
  && rm -rf /var/lib/apt/lists/* \
  # throw errors if Gemfile has been modified since Gemfile.lock
  && gem install bundler \
  && bundle config --global frozen 1 \
  && mkdir -p /usr/src/app

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock /usr/src/app/
RUN bundle config set --local without 'development:test' \
  && bundle install -j4

# install node/npm/yarn
COPY package.json yarn.lock /usr/src/app/
RUN curl -sL https://deb.nodesource.com/setup_20.x | bash \
  && apt-get install -y nodejs \
  && rm -rf /var/lib/apt/lists/* \
  && npm i -g yarn \
  && yarn install

COPY . /usr/src/app

RUN bundle exec bootsnap precompile app/ lib/

# RUN bundle exec rake assets:precompile
RUN --mount=type=secret,id=RAILS_MASTER_KEY \
  RAILS_MASTER_KEY=$(cat /run/secrets/RAILS_MASTER_KEY) && \
  SECRET_KEY_BASE_DUMMY=1 RAILS_MASTER_KEY=$RAILS_MASTER_KEY bundle exec rails assets:precompile

EXPOSE 3000

ENTRYPOINT ["/usr/local/bin/bundle", "exec"]
CMD [ "puma", "config.ru", "-C", "config/puma.rb" ]
