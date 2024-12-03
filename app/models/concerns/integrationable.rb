# frozen_string_literal: true

# app/models/concerns/integrationable.rb
module Integrationable
  extend ActiveSupport::Concern

  def integration_allowed?(integration)
    client = self.class.name.casecmp?('client') ? self : self.client
    client.integrations_allowed.include?(integration)
  end

  def integration_configured?(integration)
    send(:"#{integration}_configured?") unless %w[yelp].include?(integration)
  end

  def job_integration_available?
    client = self.class.name.casecmp?('client') ? self : self.client
    client.integrations_allowed.intersect?(%w[servicetitan housecall jobber jobnimbus servicemonster])
  end

  def ok2cardx?
    integration_allowed?('cardx') && cardx_configured?
  end

  private

  def activeprospect_configured?
    return false unless self.class.name.casecmp?('user')

    (user_api_integration = self.user_api_integrations.find_by(target: 'activeprospect', name: '')) &&
      user_api_integration&.trusted_form_script.present?
  end

  def angi_configured?
    client = self.class.name.casecmp?('client') ? self : self.client

    (client_api_integration = client.client_api_integrations.find_by(target: 'angi', name: '')) &&
      Integration::Angi::V1::Base.new(client_api_integration).valid_credentials?
  end

  def calendly_configured?
    return false unless self.class.name.casecmp?('user')

    (user_api_integration = self.user_api_integrations.find_by(target: 'calendly', name: '')) &&
      user_api_integration&.embed_script.present?
  end

  def callrail_configured?
    client = self.class.name.casecmp?('client') ? self : self.client

    (client_api_integration = client.client_api_integrations.find_by(target: 'callrail', name: '')) &&
      ::Integration::Callrail::V3::Base.credentials_exist?(client_api_integration)
  end

  def cardx_configured?
    client = self.class.name.casecmp?('client') ? self : self.client

    (client_api_integration = client.client_api_integrations.find_by(target: 'cardx', name: '')) &&
      (cardx_client = Integrations::CardX::Base.new(client_api_integration.account)) &&
      cardx_client.valid_credentials?
  end

  def contractorcommerce_configured?
    client = self.class.name.casecmp?('client') ? self : self.client

    (client_api_integration = client.client_api_integrations.find_by(target: 'contractorcommerce', name: '')) &&
      (cc_model = Integration::Contractorcommerce::V1::Base.new(client_api_integration)) &&
      cc_model.valid_credentials?
  end

  def dope_marketing_configured?
    client = self.class.name.casecmp?('client') ? self : self.client

    (client_api_integration = client.client_api_integrations.find_by(target: 'dope_marketing', name: '')) &&
      client_api_integration&.api_key.present?
  end

  def dropfunnels_configured?
    client = self.class.name.casecmp?('client') ? self : self.client

    (client_api_integration = client.client_api_integrations.find_by(target: 'dropfunnels', name: '')) &&
      client_api_integration&.api_key.present?
  end

  def email_configured?
    client = self.class.name.casecmp?('client') ? self : self.client

    (client_api_integration = client.client_api_integrations.find_by(target: 'email', name: '')) &&
      (email_client = Integrations::EMail::V1::Base.new(client_api_integration.username, client_api_integration.api_key, client_api_integration.client_id)) &&
      email_client&.valid_credentials?
  end

  def facebook_leads_configured?
    return false unless self.class.name.casecmp?('user')

    (user_api_integration = self.user_api_integrations.find_by(target: 'facebook', name: '')) &&
      user_api_integration&.pages.present?
  end

  def fieldpulse_configured?
    client = self.class.name.casecmp?('client') ? self : self.client

    (client_api_integration = client.client_api_integrations.find_by(target: 'fieldpulse', name: '')) &&
      Integration::Fieldpulse::Base.new(client_api_integration).valid_credentials?
  end

  def fieldroutes_configured?
    client = self.class.name.casecmp?('client') ? self : self.client

    (client_api_integration = client.client_api_integrations.find_by(target: 'fieldroutes', name: '')) &&
      Integration::Fieldroutes::V1::Base.new(client_api_integration).valid_credentials?
  end

  def five9_configured?
    client = self.class.name.casecmp?('client') ? self : self.client

    (client_api_integration = client.client_api_integrations.find_by(target: 'five9', name: '')) &&
      Integration::Five9::Base.new(client_api_integration).call(:valid_credentials?)
  end

  def google_configured?
    client = self.class.name.casecmp?('client') ? self : self.client

    (client_api_integration = client.client_api_integrations.find_by(target: 'google', name: '')) &&
      client_api_integration.user_id.present? &&
      (user_api_integration = UserApiIntegration.find_by(user_id: client_api_integration.user_id, target: 'google', name: '')) &&
      ::Integration::Google.valid_token?(user_api_integration)
  end

  def housecall_configured?
    client = self.class.name.casecmp?('client') ? self : self.client

    (client_api_integration = client.client_api_integrations.find_by(target: 'housecall', name: '')) &&
      ::Integration::Housecallpro::V1::Base.new(client_api_integration).valid_credentials?
  end

  def interest_rates_configured?
    client = self.class.name.casecmp?('client') ? self : self.client

    (client_api_integration = client.client_api_integrations.find_by(target: 'interest_rates', name: '')) &&
      (client_api_integration&.campaign_id&.positive? || client_api_integration&.group_id&.positive? || client_api_integration&.stage_id&.positive? || client_api_integration&.tag_id&.positive?)
  end

  def jobber_configured?
    client = self.class.name.casecmp?('client') ? self : self.client

    (client_api_integration = client.client_api_integrations.find_by(target: 'jobber', name: '')) &&
      Integration::Jobber::Base.new(client_api_integration).valid_credentials?
  end

  def jobnimbus_configured?
    client = self.class.name.casecmp?('client') ? self : self.client

    (client_api_integration = client.client_api_integrations.find_by(target: 'jobnimbus', name: '')) &&
      client_api_integration&.api_key.present?
  end

  def jotform_configured?
    return false unless self.class.name.casecmp?('user')

    (user_api_integration = self.user_api_integrations.find_by(target: 'jotform', name: '')) &&
      user_api_integration&.api_key.present?
  end

  def maestro_configured?
    client = self.class.name.casecmp?('client') ? self : self.client

    (client_api_integration = client.client_api_integrations.find_by(target: 'maestro', name: '')) &&
      client_api_integration&.api_pass.present?
  end

  def outreach_configured?
    client = self.class.name.casecmp?('client') ? self : self.client

    (client_api_integration = client.client_api_integrations.find_by(target: 'outreach', name: '')) &&
      client_api_integration&.valid_outreach_token?
  end

  def pcrichard_configured?
    client = self.class.name.casecmp?('client') ? self : self.client

    (client_api_integration = client.client_api_integrations.find_by(target: 'pcrichard', name: '')) &&
      client_api_integration&.api_key.present? && client_api_integration&.credentials&.dig('auth_token').present?
  end

  def phone_sites_configured?
    return false unless self.class.name.casecmp?('user')

    user_api_integrations = self.user_api_integrations.where(target: 'phone_sites').where.not(api_key: nil)
    user_api_integrations.find_each do |user_api_integration|
      return true if user_api_integration.live.to_bool
    end

    false
  end

  def responsibid_configured?
    client = self.class.name.casecmp?('client') ? self : self.client

    (client_api_integration = client.client_api_integrations.find_by(target: 'responsibid', name: '')) &&
      client_api_integration&.api_key.present?
  end

  def salesrabbit_configured?
    client = self.class.name.casecmp?('client') ? self : self.client

    (client_api_integration = client.client_api_integrations.find_by(target: 'salesrabbit', name: '')) &&
      client_api_integration&.api_key.present?
  end

  def searchlight_configured?
    client = self.class.name.casecmp?('client') ? self : self.client

    (client_api_integration = client.client_api_integrations.find_by(target: 'searchlight', name: '')) &&
      client_api_integration&.active
  end

  def sendgrid_configured?
    client = self.class.name.casecmp?('client') ? self : self.client

    (client_api_integration = client.client_api_integrations.find_by(target: 'sendgrid')) &&
      client_api_integration&.api_key.present?
  end

  def sendjim_configured?
    client = self.class.name.casecmp?('client') ? self : self.client

    (client_api_integration = client.client_api_integrations.find_by(target: 'sendjim', name: '')) &&
      ::Integration::Sendjim::V3::Sendjim.credentials_exist?(client_api_integration)
  end

  def servicemonster_configured?
    client = self.class.name.casecmp?('client') ? self : self.client

    (client_api_integration = client.client_api_integrations.find_by(target: 'servicemonster', name: '')) &&
      ::Integration::Servicemonster.credentials_exist?(client_api_integration)
  end

  def servicetitan_configured?
    client = self.class.name.casecmp?('client') ? self : self.client

    (client_api_integration = client.client_api_integrations.find_by(target: 'servicetitan', name: '')) &&
      ::Integration::Servicetitan::V2::Base.new(client_api_integration).credentials_exist?
  end

  def slack_configured?
    return false unless self.class.name.casecmp?('user')

    (user_api_integration = self.user_api_integrations.find_by(target: 'slack', name: '')) &&
      user_api_integration&.token.present?
  end

  def successware_configured?
    client = self.class.name.casecmp?('client') ? self : self.client

    (client_api_integration = client.client_api_integrations.find_by(target: 'successware', name: '')) &&
      ::Integration::Successware::V202311::Base.new(client_api_integration).valid_credentials?
  end

  def sunbasedata_configured?
    client = self.class.name.casecmp?('client') ? self : self.client

    (client_api_integration = client.client_api_integrations.find_by(target: 'sunbasedata', name: '')) &&
      client_api_integration&.api_key.present? && client_api_integration&.sales_rep_id.present? && client_api_integration&.appt_setter_id.present?
  end

  def thumbtack_configured?
    client = self.class.name.casecmp?('client') ? self : self.client

    (client_api_integration = client.client_api_integrations.find_by(target: 'thumbtack', name: '')) &&
      Integration::Thumbtack::Base.new(client_api_integration).valid_credentials?
  end

  def webhooks_configured?
    client = self.class.name.casecmp?('client') ? self : self.client

    (client_api_integration = client.client_api_integrations.find_by(target: 'webhook', name: '')) &&
      client_api_integration&.webhooks.present?
  end

  def xencall_configured?
    client = self.class.name.casecmp?('client') ? self : self.client

    (client_api_integration = client.client_api_integrations.find_by(target: 'xencall', name: '')) &&
      client_api_integration&.api_key.present?
  end

  def zapier_configured?
    return false unless self.class.name.casecmp?('user')

    (user_api_integration = self.user_api_integrations.find_by(target: 'zapier')) &&
      user_api_integration&.zapier_subscription_url.present?
  end
end
