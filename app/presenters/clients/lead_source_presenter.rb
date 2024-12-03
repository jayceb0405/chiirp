# frozen_string_literal: true

# app/presenters/clients/lead_source_presenter.rb
module Clients
  # variables required by KPI views
  class LeadSourcePresenter
    attr_accessor :lead_source
    attr_reader   :client

    def initialize(args = {})
      self.client = args.dig(:client)
    end

    def client=(client)
      @client = if client.is_a?(Client)
                  client
                elsif client.is_a?(Integer)
                  Client.find_by(id: client)
                elsif self.user.is_a?(User)
                  self.user.client
                else
                  Client.new
                end

      @lead_source = nil
    end

    def lead_sources
      @lead_sources ||= @client.lead_sources.order(name: :asc).left_joins(:contacts).select(:id, :name, :created_at, 'contacts.count AS contacts_count').group(:id)
    end
  end
end
