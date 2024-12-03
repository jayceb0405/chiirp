# Chiirp

![tests status](https://github.com/Hwy-18-LLC/Chiirp/actions/workflows/tests.yml/badge.svg)

This is Chiirp.

## Enviroment variables

Below is a list of ENV vars that are needed in the dev environment

1. `user_contact_form_domains`
1. `mini_domain`
1. `REDIS_URL`
1. `save_chiirp_sitechat_key`
1. `chiirp_sitechat_key`
1. `chiirp_sitechat_version`

1. `WEB_CONCURRENCY=0`
1. `RAILS_MAX_THREADS=1`
1. `DATABASE_URL`
1. `RAILS_LOG_TO_STDOUT=true`

1. `BANDWIDTH_VOICE_APPLICATION_ID`
1. `BANDWIDTH_MESSAGING_APPLICATION_ID`

1. `SUPER_USER_EMAIL` example: `dev@chiirp.com`

1. `SUPER_USER_PHONES` example: `7145551212,9495551212` description: Comma separated list of 10 digit phone numbers. In dev/test only these phone numbers will be allowed to send messages to.

1. `DEV_DOMAIN_PREFIX` use this to prefix some/all domains with your identifier. example: `ian-` will yield domains like: `ian-dev.chiirp.io`.

## Developer Setup

1. Add dev to `Development` team in GitHub
1. Set dev up with [Cloudflare tunnel](https://one.dash.cloudflare.com/a3ac6c3b6582967dd5361b14fefb3c86/networks/tunnels)
1. Send `dump.sql` to dev
1. Get initial copy of `config/credentials/development.yml.enc`
1. Get initial copy of `config/credentials/development.key`
1. Set up initial `.env`.

### Prerequisites

1. Install Docker / Docker desktop
1. Install Cloudflare tunnel: https://www.cloudflare.com/products/tunnel/

### Set up

1. `docker compose up -d`
1. Get latest copy of dev database, save it to `dump.sql` in the project root.
1. Optional: customizations might need to be made in `lib/tasks/dev.rake`.
1. `docker compose exec -it app ./bin/reset_db_from_backup` will apply `dump.sql` to current database.
1. `docker compose exec -it app yarn install` will get required node packages.

### Notes

1. Use `docker compose down` to delete containers, but retain database data.
1. Use `docker compose down -v` to completely delete database env and delete data.
