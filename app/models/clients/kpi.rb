# frozen_string_literal: true

# app/models/clients/kpi.rb
module Clients
  # Client::Kpi data processing
  class Kpi < ApplicationRecord
    self.table_name = 'client_kpis'

    belongs_to :client

    validate :count_is_approved, on: [:create]

    private

    def count_is_approved
      errors.add(:base, "Maximum KPIs for #{self.client&.name} has been met.") if self.client&.max_kpis_count.to_i < self.client&.client_kpis&.count.to_i
    end
  end
end
