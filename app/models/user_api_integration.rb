# frozen_string_literal: true

# app/models/user_api_integration.rb
class UserApiIntegration < ApplicationRecord
  belongs_to :user

  # General
  store_accessor :data, :refresh_token, :token, :expires_at,
                 # ActiveProspect
                 :trusted_form_script,
                 # Calendly
                 :embed_script,
                 # Facebook
                 :pages, :users,
                 # Facebook Leads
                 :forms,
                 # Facebook Messenger
                 # Google
                 :dashboard_calendars,
                 # JotForm
                 :jotform_forms, :version,
                 # PhoneSites
                 :live, :campaign_id, :form_fields, :last_form_keys,
                 # Slack
                 :notifications_channel,
                 # Zapier
                 :zapier_subscription_url

  after_initialize :apply_defaults, if: :new_record?

  def self.integrations
    %w[
      activeprospect
      calendly
      facebook_leads
      facebook_messenger
      google
      jotform
      phone_sites
      slack
      zapier
    ]
  end

  def self.integrations_array
    [
      %w[ActiveProspect activeprospect],
      %w[Calendly calendly],
      ['Facebook Leads', 'facebook_leads'],
      ['Facebook Messenger', 'facebook_messenger'],
      %w[Google google],
      %w[JotForm jotform],
      %w[PhoneSites phone_sites],
      %w[Slack slack],
      %w[Zapier zapier]
    ]
  end

  def attributes_cleaned
    self.attributes.tap do |attributes|
      attributes['data'].delete('refresh_token')
      attributes['data'].delete('token')
    end
  end

  private

  def apply_defaults
    self.expires_at              ||= 0
    self.refresh_token           ||= ''
    self.token                   ||= ''

    case self.target.downcase
    when 'activeprospect'
      self.trusted_form_script     ||= ''
    when 'calendly'
      self.embed_script            ||= ''
    when 'facebook'

      case self.name.downcase
      when ''
        self.pages                   ||= []
        self.users                   ||= []
      when 'leads'
        self.forms                   ||= []
      when 'messenger'
        ''
      end
    when 'google'
      self.dashboard_calendars     ||= []
    when 'jotform'
      self.jotform_forms           ||= {}
      self.version                 ||= '1'
    when 'phone_sites'
      self.campaign_id             ||= 0
      self.form_fields             ||= {}
      self.last_form_keys          ||= []
      self.live                      = self.live.nil? ? true : self.live
    when 'slack'
      self.notifications_channel   ||= ''
    when 'zapier'
      self.zapier_subscription_url ||= ''
    end
  end
end
