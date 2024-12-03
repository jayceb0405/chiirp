# frozen_string_literal: true

# app/lib/integrations/jot_form/jotform.rb
require 'net/http'
require 'uri'
require 'rubygems'
require 'json'

module Integrations
  module JotForm
    class Jotform
      # general JotForm API class methods for any version
      # Integrations::JotForm::Jotform.new()
      #   (req) apiKey:     (String)
      #   (opt) baseURL:    (String / default: 'http://api.jotform.com')
      #   (opt) apiVersion: (String / default: 'v1')
      # rubocop:disable Naming/MethodName, Naming/MethodParameterName, Naming/VariableName
      attr_accessor :apiKey, :baseURL, :apiVersion

      # Create the object
      def initialize(apiKey = nil, baseURL = 'http://api.jotform.com', apiVersion = 'v1')
        @apiKey = apiKey
        @baseURL = baseURL
        @apiVersion = apiVersion
      end

      def _executeHTTPRequest(endpoint, parameters = nil, type = 'GET')
        url = "#{[@baseURL, @apiVersion, endpoint].join('/')}?apiKey=#{@apiKey}"
        url = URI.parse(url)

        case type
        when 'GET'
          response = Net::HTTP.get_response(url)
        when 'POST'
          response = Net::HTTP.post_form(url, parameters)
        when 'DELETE'
          uri      = URI(url)
          http     = Net::HTTP.new(uri.host, uri.port)
          req      = Net::HTTP::Delete.new(uri.request_uri)
          response = http.request(req)
        end

        Rails.logger.info "Integrations::JotForm::Jotform._executeHTTPRequest: #{{ base_url: @baseURL, api_version: @apiVersion, endpoint:, type:, parameters:, response:, response_body: response.body }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"

        if response.is_a?(Net::HTTPSuccess)
          JSON.parse(response.body)['content']
        else
          Rails.logger.info "Integrations::JotForm::Jotform._executeHTTPRequest: #{{ message: JSON.parse(response.body)['message'] }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
          nil
        end
      end

      def _executeGetRequest(endpoint, parameters = [])
        _executeHTTPRequest(endpoint, parameters, 'GET')
      end

      def _executePostRequest(endpoint, parameters = [])
        _executeHTTPRequest(endpoint, parameters, 'POST')
      end

      def _executeDeleteRequest(endpoint, parameters = [])
        _executeHTTPRequest(endpoint, parameters, 'DELETE')
      end

      def getUser
        _executeGetRequest('user')
      end

      def getUsage
        _executeGetRequest('user/usage')
      end

      def getForms
        _executeGetRequest('user/forms')
      end

      def getSubmissions
        _executeGetRequest('user/submissions')
      end

      def getSubusers
        _executeGetRequest('user/subusers')
      end

      def getFolders
        _executeGetRequest('user/folders')
      end

      def getReports
        _executeGetRequest('user/reports')
      end

      def getSettings
        _executeGetRequest('user/settings')
      end

      def getHistory
        _executeGetRequest('user/history')
      end

      def getForm(formID)
        _executeGetRequest("form/#{formID}")
      end

      def getFormQuestions(formID)
        _executeGetRequest("form/#{formID}/questions")
      end

      def getFormQuestion(formID, qid)
        _executeGetRequest("form/#{formID}/question/#{qid}")
      end

      def getFormProperties(formID)
        _executeGetRequest("form/#{formID}/properties")
      end

      def getFormProperty(formID, propertyKey)
        _executeGetRequest("form/#{formID}/properties/#{propertyKey}")
      end

      def getFormSubmissions(formID)
        _executeGetRequest("form/#{formID}/submissions")
      end

      def getFormFiles(formID)
        _executeGetRequest("form/#{formID}/files")
      end

      def getFormWebhooks(formID)
        _executeGetRequest("form/#{formID}/webhooks")
      end

      def getSubmission(sid)
        _executeGetRequest("submission/#{sid}")
      end

      def getReport(reportID)
        _executeGetRequest("report/#{reportID}")
      end

      def getFolder(folderID)
        _executeGetRequest("folder/#{folderID}")
      end

      def createFormWebhook(formID, webhookURL)
        _executePostRequest("form/#{formID}/webhooks", { 'webhookURL' => webhookURL })
      end

      def deleteFormWebhook(formID, webhookID)
        _executeDeleteRequest("form/#{formID}/webhooks/#{webhookID}")
      end

      def createFormSubmissions(formID, submission)
        _executePostRequest("form/#{formID}/submissions", submission)
      end
      # rubocop:enable Naming/MethodName, Naming/MethodParameterName, Naming/VariableName
    end
  end
end
