# frozen_string_literal: true

# app/models/clients/api_call.rb
module Clients
  class ApiCall < ApplicationRecord
    self.table_name = 'client_api_calls'

    belongs_to :client

    before_validation :before_validation_actions

    private

    def before_validation_actions
      self.client_id = case self.target
                       when 'callrail'
                         ClientApiIntegration.where(target: self.target).find_by('client_api_integrations.data @> ?', { credentials: { api_key: self.client_api_id } }.to_json)&.client_id
                       when 'cardx'
                         ClientApiIntegration.where(target: self.target).find_by('client_api_integrations.data @> ?', { account: self.client_api_id }.to_json)&.client_id
                       when 'dope_marketing', 'email', 'jobnimbus', 'salesrabbit'
                         ClientApiIntegration.find_by(target: self.target, api_key: self.client_api_id)&.client_id
                       when 'fieldpulse'
                         ClientApiIntegration.find_by(target: self.target, api_key: self.client_api_id)&.client_id
                       when 'facebook'
                         UserApiIntegration.where(target: self.target).find_by('data @> ?', { users: [{ id: self.client_api_id }] }.to_json)&.user&.client_id
                       when 'google', 'slack'
                         UserApiIntegration.where(target: self.target).find_by('data @> ?', { token: self.client_api_id }.to_json)&.user&.client_id
                       when 'housecallpro'
                         ClientApiIntegration.where(target: 'housecall', name: '').find_by('client_api_integrations.data @> ?', { credentials: { access_token: self.client_api_id } }.to_json)&.client_id
                       when 'jobber'
                         ClientApiIntegration.where(target: self.target).find_by('client_api_integrations.data @> ?', { credentials: { refresh_token: self.client_api_id } }.to_json)&.client_id
                       when 'pcrichard'
                         ClientApiIntegration.where(target: self.target).find_by('client_api_integrations.data @> ?', { credentials: { auth_token: self.client_api_id } }.to_json)&.client_id
                       when 'searchlight', 'vitally'
                         self.client_api_id
                       when 'sendjim'
                         ClientApiIntegration.where(target: self.target).find_by('data @> ?', { token: self.client_api_id }.to_json)&.client_id
                       when 'sendgrid'
                         ClientApiIntegration.find_by(target: self.target, api_key: self.client_api_id)&.client_id
                       when 'servicemonster'
                         ClientApiIntegration.where(target: self.target).find_by('client_api_integrations.data @> ?', { credentials: { userName: self.client_api_id } }.to_json)&.client_id
                       when 'servicetitan'
                         ClientApiIntegration.where(target: self.target, name: '').find_by('client_api_integrations.data @> ?', { credentials: { client_id: self.client_api_id } }.to_json)&.client_id
                       when 'successware'
                         ClientApiIntegration.where(target: self.target).find_by('client_api_integrations.data @> ?', { credentials: { company_no: self.client_api_id } }.to_json)&.client_id
                       end
      self.client_api_id = nil
    end
  end
end
