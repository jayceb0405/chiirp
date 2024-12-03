# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'
    resource '/oauth/token', headers: :any, methods: %i[post]
  end
  allow do
    origins '*'
    resource '/oauth/authorize', headers: :any, methods: %i[get]
  end
  allow do
    origins '*'
    resource '/api/ui/v1/*', headers: :any, methods: :any
  end
end
