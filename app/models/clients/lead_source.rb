# frozen_string_literal: true

# app/models/clients/lead_source.rb
module Clients
  # Clients::LeadSource data processing
  class LeadSource < ApplicationRecord
    self.table_name = 'clients_lead_sources'

    belongs_to :client

    has_many :contacts, dependent: :nullify

    # copy Lead Source
    # lead_source.copy
    def copy(args)
      new_client_id   = args.dig(:new_client_id).to_i
      new_lead_source = nil

      new_client = if new_client_id.positive? && new_client_id != self.client_id
                     # new_client_id was received
                     Client.find_by(id: new_client_id)
                   else
                     # copy Lead Source to same Client
                     self.client
                   end

      if new_client
        new_lead_source = new_client.lead_sources.find_or_initialize_by(name: self.name)

        unless new_lead_source.save
          # new Lead SOurce could NOT be saved
          new_lead_source = nil
        end
      end

      new_lead_source
    end
  end
end
