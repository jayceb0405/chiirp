# frozen_string_literal: true

# app/models/contact_api_integration.rb
class ContactApiIntegration < ApplicationRecord
  belongs_to :contact

  # general use accessors
  store_accessor :data, :status,
                 # Housecall Pro accessors
                 :account_balance, :completion_date, :customer_id, :customer_type, :estimate_total,
                 :ext_tech_id, :ext_tech_name, :ext_tech_phone,
                 :job_address, :job_city, :job_number, :job_state, :job_total, :job_zip, :update_balance_window_days,
                 # Maestro accessors
                 :client_code, :arrival_date, :departure_date, :guest_type, :checked_in, :room_number,
                 # ServiceTitan accessors
                 :account_balance, :history_item_ids, :update_balance_window_days,
                 # Xencall accessors
                 :xencall_lead_id

  after_initialize :apply_defaults, if: :new_record?

  private

  def apply_defaults
    # initialize JSONB data

    case self.target.downcase
    when 'housecallpro'
      # Housecall Pro data
      self.customer_id                ||= '' # Customer ID
      self.completion_date            ||= ''
      self.account_balance            ||= 0
      self.ext_tech_id                ||= ''
      self.ext_tech_name              ||= ''
      self.ext_tech_phone             ||= ''
      self.customer_type              ||= ''
      self.job_number                 ||= ''
      self.job_address                ||= ''
      self.job_city                   ||= ''
      self.job_state                  ||= ''
      self.job_zip                    ||= ''
      self.update_balance_window_days ||= 0
    when 'maestro'
      # Maestro data
      self.client_code                ||= '' # ClientCode
      self.arrival_date               ||= '' # ArrivalDate
      self.departure_date             ||= '' # DepartureDate
      self.guest_type                 ||= '' # GuestType
      self.checked_in                 ||= 0
      self.room_number                ||= '' # RoomCode
      self.status                     ||= '' # ReservationStatus (reserved / cancelled / checked_in / checked_out)
    when 'salesrabbit'
      # SalesRabbit data
      self.status                     ||= ''
    when 'servicetitan'
      # ServiceTitan data
      self.account_balance            ||= 0.0
      self.history_item_ids           ||= {}
      self.update_balance_window_days ||= 0
    when 'xencall'
      self.xencall_lead_id            ||= ''
    end
  end
end
