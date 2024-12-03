# frozen_string_literal: true

# app/lib/tenant.rb
module Tenant
  # Chiirp tenant processing

  # return the OmniAuth authorization path
  # omniauth_authorize_path = Tenant.omniauth_authorize_path(request, provider)
  def self.omniauth_authorize_path(_request, provider)
    "user_#{provider}_chiirp_omniauth_authorize_path"
  end

  # return the OmniAuth provider found in request
  # provider = Tenant.omniauth_provider(request)
  def self.omniauth_provider(request)
    provider = request.env['omniauth.auth'].provider.to_s.downcase
    provider = 'google_oauth2' if provider == 'google_oauth2_chiirp'
    provider = 'outreach' if provider == 'outreach_chiirp'
    provider = 'slack' if provider == 'slack_chiirp'

    provider
  end

  # validate requested domain / generate redirect string if necessary
  # redirect_url = Tenant.validate_requested_domain(request)
  #   request.domain: "chiirp.com"
  #   request.subdomain: "dev"
  #   request.original_url: "https://dev.chiirp.com/"
  def self.validate_requested_domain(request)
    return '' if Rails.env.test? && request.domain.blank?

    domain           = request.domain.split('.').first.downcase
    top_level_domain = request.domain.split('.').last.downcase

    if domain == 'chiirp' && top_level_domain == 'com'
      ''
    elsif ENV['user_contact_form_domains'].split(',').include?(domain)
      request.original_url.gsub(domain, 'chiirp').gsub(top_level_domain, 'com')
    elsif (client = Client.find_by("data->'domains' ?| array[:options]", options: request.domain)) && (user_contact_form = UserContactForm.find_by(id: client.domains[request.domain]))
      user_contact_form.landing_page_url
    else
      request.original_url.gsub(domain, 'chiirp').reverse.sub(".#{top_level_domain}".reverse, '.com'.reverse).reverse
    end
  end
end
