# frozen_string_literal: true

# app/models/contacts/job.rb
module Contacts
  class Job < ApplicationRecord
    include PaymentRequestable

    self.table_name = 'contact_jobs'

    belongs_to :contact

    has_many   :estimates,                    dependent: :destroy,    class_name: '::Contacts::Estimate'
    has_many   :lineitems, as: :lineitemable, dependent: :delete_all, class_name: '::Contacts::Lineitem'
    has_many   :payment_transactions,         dependent: :nullify,    foreign_key: :contact_jobs_id, inverse_of: :contact_job
    has_many   :visits,                       dependent: :destroy,    class_name: '::Contacts::Visit'

    validates  :status, :description, :ext_tech_id, :notes, :invoice_number, :ext_source, :ext_id, presence: true, allow_blank: true
    validates  :address_01, :address_02, :city, :state, :postal_code, :country, presence: true, allow_blank: true
    validates  :scheduled_arrival_window, numericality: { only_integer: true }
    validates  :total_amount, :outstanding_balance, numericality: true

    # replace Tags in message content with Contacts::Job data
    # content = contact_job.message_tag_replace(String)
    def message_tag_replace(message)
      return message unless message.include?('#{')

      # rubocop:disable Lint/InterpolationCheck
      client_api_integration = self.contact.client.client_api_integrations.find_by(target: self.ext_source.sub('housecallpro', 'housecall'), name: '')

      technician = if self.ext_tech_id.present? && ['#{tech-id}', '#{tech-name}', '#{tech-firstname}', '#{tech-phone}', '#{tech-email}', '#{tech-image}'].any? { |h| message.include?(h) }
                     self.technician
                   else
                     {}
                   end

      message = message.to_s
                       .gsub('#{job-status}', self.status)
                       .gsub('#{job-description}', self.description)
                       .gsub('#{job-scheduled_start_at}', self.scheduled_start_at&.in_time_zone(self.contact.client.time_zone)&.strftime('%A, %B %d, %Y at %l:%M%P')&.gsub('  ', ' ') || '')
                       .gsub('#{job-scheduled_end_at}', self.scheduled_end_at&.in_time_zone(self.contact.client.time_zone)&.strftime('%A, %B %d, %Y at %l:%M%P')&.gsub('  ', ' ') || '')
                       .gsub('#{job-scheduled_arrival_window_date}', self.scheduled_start_at&.in_time_zone(self.contact.client.time_zone)&.strftime('%A, %B %d, %Y') || '')
                       .gsub('#{job-actual_started_at}', self.actual_started_at&.in_time_zone(self.contact.client.time_zone)&.strftime('%A, %B %d, %Y at %l:%M%P')&.gsub('  ', ' ') || '')
                       .gsub('#{job-actual_completed_at}', self.actual_completed_at&.in_time_zone(self.contact.client.time_zone)&.strftime('%A, %B %d, %Y at %l:%M%P')&.gsub('  ', ' ') || '')
                       .gsub('#{job-actual_on_my_way_at}', self.actual_on_my_way_at&.in_time_zone(self.contact.client.time_zone)&.strftime('%A, %B %d, %Y at %l:%M%P')&.gsub('  ', ' ') || '')
                       .gsub('#{job-total_amount}', ActionController::Base.helpers.number_to_currency(self.total_amount.to_d))
                       .gsub('#{job-outstanding_balance}', ActionController::Base.helpers.number_to_currency(self.outstanding_balance.to_d))
                       .gsub('#{job-invoice_number}', self.invoice_number)

      message = message.gsub('#{job-payment_request}', payment_request_url(contact:, amount: self.outstanding_balance, job_id: self.id)) if message.include?('#{job-payment_request}')
      message = message.gsub('#{job-total_amount_paid}', ActionController::Base.helpers.number_to_currency(self.payments_received)) if message.include?('#{job-total_amount_paid}')
      message = message.gsub('#{job-remaining_amount_due}', ActionController::Base.helpers.number_to_currency(self.outstanding_balance)) if message.include?('#{job-remaining_amount_due}')

      message = if %w[servicemonster servicetitan].include?(self.ext_source)
                  message.gsub('#{job-scheduled_arrival_window_time}', if self.scheduled_arrival_window_start_at.present? && self.scheduled_arrival_window_end_at.present?
                                                                         "#{self.scheduled_arrival_window_start_at.in_time_zone(self.contact.client.time_zone).strftime('%l:%M%P').strip} - #{self.scheduled_arrival_window_end_at.in_time_zone(self.contact.client.time_zone).strftime('%l:%M%P').strip}"
                                                                       elsif self.scheduled_start_at.present?
                                                                         self.scheduled_start_at.in_time_zone(self.contact.client.time_zone).strftime('%l:%M%P').strip.to_s
                                                                       else
                                                                         ''
                                                                       end)
                else
                  message.gsub('#{job-scheduled_arrival_window_time}', if self.scheduled_start_at.present?
                                                                         "#{self.scheduled_start_at.in_time_zone(self.contact.client.time_zone).strftime('%l:%M%P').strip}#{self.scheduled_arrival_window.positive? ? " - #{(self.scheduled_start_at.in_time_zone(self.contact.client.time_zone) + self.scheduled_arrival_window.to_i.minutes).strftime('%l:%M%P').strip}" : ''}"
                                                                       else
                                                                         ''
                                                                       end)
                end

      case self.ext_source
      when 'fieldroutes'
        message = message
                  .gsub('#{job-address}', [self.address_01, self.address_02].compact_blank.join(', '))
                  .gsub('#{job-city}', self.city)
                  .gsub('#{job-state}', self.state)
                  .gsub('#{job-postal_code}', self.postal_code)
                  .gsub('#{tech-id}', technician.dig(:ext_id).to_s)
                  .gsub('#{tech-name}', Friendly.new.fullname(technician.dig(:firstname).to_s, technician.dig(:lastname).to_s))
                  .gsub('#{tech-firstname}', technician.dig(:firstname).to_s)
                  .gsub('#{tech-phone}', technician.dig(:phone).to_s)
                  .gsub('#{tech-email}', technician.dig(:email).to_s)
      when 'housecall', 'housecallpro', 'jobber'
        message = message
                  .gsub('#{job-address}', [self.address_01, self.address_02].compact_blank.join(', '))
                  .gsub('#{job-city}', self.city)
                  .gsub('#{job-state}', self.state)
                  .gsub('#{job-postal_code}', self.postal_code)
                  .gsub('#{tech-id}', technician.dig(:ext_id).to_s)
                  .gsub('#{tech-name}', Friendly.new.fullname(technician.dig(:firstname).to_s, technician.dig(:lastname).to_s))
                  .gsub('#{tech-firstname}', technician.dig(:firstname).to_s)
                  .gsub('#{tech-phone}', technician.dig(:phone).to_s)
                  .gsub('#{tech-email}', technician.dig(:email).to_s)

        message = if message.include?('#{tech-image}') && client_api_integration && (user = User.find_by(id: client_api_integration.employees.dig(self.ext_tech_id))) && user.avatar.present?
                    message.gsub('#{tech-image}', user.avatar.url(secure_distribution: I18n.t("tenant.#{Rails.env}.cloudinary_cname"), transformation: [{ width: 250, height: 250, crop: 'scale', effect: 'outline:outer:1:0' }], format: 'png'))
                  else
                    message.gsub('#{tech-image}', '')
                  end
      when 'jobnimbus'

        message = if self.ext_sales_rep_id.present? && client_api_integration && (ext_sales_rep = Integration::Jobnimbus::V1::Base.new(client_api_integration).sales_rep_find(id: self.ext_sales_rep_id))
                    message
                      .gsub('#{job-rep_name}', ext_sales_rep[:name])
                      .gsub('#{job-rep_email}', ext_sales_rep[:email])
                  else
                    message
                      .gsub('#{job-rep_name}', '')
                      .gsub('#{job-rep_email}', '')
                  end
      when 'servicemonster'
        message = message
                  .gsub('#{site-address}', [self.address_01, self.address_02].compact_blank.join(', '))
                  .gsub('#{site-city}', self.city)
                  .gsub('#{site-state}', self.state)
                  .gsub('#{site-postal_code}', self.postal_code)
                  .gsub('#{tech-id}', technician.dig(:ext_id).to_s)
                  .gsub('#{tech-name}', Friendly.new.fullname(technician.dig(:firstname).to_s, technician.dig(:lastname).to_s))
                  .gsub('#{tech-firstname}', technician.dig(:firstname).to_s)
                  .gsub('#{tech-phone}', technician.dig(:phone).to_s)
                  .gsub('#{tech-email}', technician.dig(:email).to_s)

        message = if message.include?('#{tech-image}') && client_api_integration && (user = User.find_by(id: client_api_integration.employees.dig(self.ext_tech_id))) && user.avatar.present?
                    message.gsub('#{tech-image}', user.avatar.url(secure_distribution: I18n.t("tenant.#{Rails.env}.cloudinary_cname"), transformation: [{ width: 250, height: 250, crop: 'scale', effect: 'outline:outer:1:0' }], format: 'png'))
                  else
                    message.gsub('#{tech-image}', '')
                  end
      when 'servicetitan'
        message = message
                  .gsub('#{site-address}', [self.address_01, self.address_02].compact_blank.join(', '))
                  .gsub('#{site-city}', self.city)
                  .gsub('#{site-state}', self.state)
                  .gsub('#{site-postal_code}', self.postal_code)
                  .gsub('#{tech-id}', technician.dig(:ext_id).to_s)
                  .gsub('#{tech-name}', Friendly.new.fullname(technician.dig(:firstname).to_s, technician.dig(:lastname).to_s))
                  .gsub('#{tech-firstname}', technician.dig(:firstname).to_s)
                  .gsub('#{tech-phone}', technician.dig(:phone).to_s)
                  .gsub('#{tech-email}', technician.dig(:email).to_s)
                  .gsub('#{job-business_unit_name}', self.servicetitan_business_unit_name)

        if message.include?('#{tech-image}') && client_api_integration&.employees&.dig(technician.dig(:ext_id).to_s).to_i.positive? && (user = User.find_by(client_id: client_api_integration.client_id, id: client_api_integration.employees.dig(technician.dig(:ext_id).to_s)))
          message = if user.avatar.present?
                      message.gsub('#{tech-image}', user.avatar.url(secure_distribution: I18n.t("tenant.#{Rails.env}.cloudinary_cname"), transformation: [{ width: 250, height: 250, crop: 'scale', effect: 'outline:outer:1:0' }], format: 'png'))
                    else
                      message.gsub('#{tech-image}', '')
                    end
        end
      else
        message = message
                  .gsub('#{job-rep_name}', '')
                  .gsub('#{job-rep_email}', '')
                  .gsub('#{site-address}', '')
                  .gsub('#{site-city}', '')
                  .gsub('#{site-state}', '')
                  .gsub('#{site-postal_code}', '')
                  .gsub('#{tech-id}', '')
                  .gsub('#{tech-name}', '')
                  .gsub('#{tech-firstname}', '')
                  .gsub('#{tech-phone}', '')
                  .gsub('#{tech-email}', '')
                  .gsub('#{tech-image}', '')
      end
      # rubocop:enable Lint/InterpolationCheck

      message
    end

    def remaining_balance
      total_amount - payments_received
    end

    # return the business unit name for the Contacts::Job business_unit_id
    # business_unit_name = contact_job.servicetitan_business_unit_name
    def servicetitan_business_unit_name
      if self.business_unit_id.to_i.positive?
        ClientApiIntegration.find_by(client_id: self.contact.client_id, target: 'servicetitan', name: 'business_units')&.data&.find { |bu| bu['id'] == self.business_unit_id.to_i }.presence || ''
      else
        ''
      end
    end

    def technician
      return {} if self.ext_tech_id.blank?
      return {} unless (client_api_integration = self.contact.client.client_api_integrations.find_by(target: self.ext_source.sub('housecallpro', 'housecall'), name: ''))

      technician = if self.ext_source == 'fieldroutes'
                     Integration::Fieldroutes::V1::Base.new(client_api_integration).employees.find { |e| e[:employeeID] == self.ext_tech_id }
                   elsif %w[housecall housecallpro].include?(self.ext_source)
                     Integration::Housecallpro::V1::Base.new(client_api_integration).technician(self.ext_tech_id)
                   elsif self.ext_source == 'jobber'
                     "Integration::Jobber::V#{Integration::Jobber::Base.new(client_api_integration).current_version}::Base".constantize.new(client_api_integration).valid_credentials?
                     "Integrations::JobBer::V#{Integration::Jobber::Base.new(client_api_integration).current_version}::Base".constantize.new(client_api_integration.credentials).user(self.ext_tech_id)
                   elsif self.ext_source == 'servicemonster'
                     Integrations::ServiceMonster.new(client_api_integration.credentials).employee(self.ext_tech_id)
                   elsif self.ext_source == 'servicetitan'
                     Integration::Servicetitan::V2::Base.new(client_api_integration).technician(self.ext_tech_id.to_i)
                   else
                     {}
                   end

      return {} if technician.blank?

      case self.ext_source
      when 'fieldroutes'
        {
          ext_id:     technician.dig(:employeeID).to_s,
          ext_source: self.ext_source,
          firstname:  technician.dig(:fname).to_s,
          lastname:   technician.dig(:lname).to_s,
          phone:      technician.dig(:phone).to_s.clean_phone(self.contact.client.primary_area_code),
          email:      technician.dig(:email).to_s
        }
      when 'housecall', 'housecallpro'
        {
          ext_id:     technician.dig(:id).to_s,
          ext_source: self.ext_source.sub('housecallpro', 'housecall'),
          firstname:  technician.dig(:firstname).to_s,
          lastname:   technician.dig(:lastname).to_s,
          phone:      technician.dig(:phone).to_s.clean_phone(self.contact.client.primary_area_code),
          email:      technician.dig(:email).to_s
        }
      when 'jobber'
        tech_name = technician.dig(:name, :full).to_s.dup.parse_name # added "dup" to unfreeze empty name string
        {
          ext_id:     technician.dig(:id).to_s,
          ext_source: self.ext_source,
          firstname:  tech_name.dig(:firstname).to_s,
          lastname:   tech_name.dig(:lastname).to_s,
          phone:      technician.dig(:phone, :raw).to_s.clean_phone(self.contact.client.primary_area_code),
          email:      technician.dig(:email, :raw).to_s
        }
      when 'servicemonster'
        {
          ext_id:     technician.dig(:employeeID).to_s,
          ext_source: self.ext_source,
          firstname:  technician.dig(:firstName).to_s,
          lastname:   technician.dig(:lastName).to_s,
          phone:      if technician.dig(:phone1).present?
                        technician.dig(:phone1).to_s.clean_phone(self.contact.client.primary_area_code)
                      elsif technician.dig(:phone2).present?
                        technician.dig(:phone2).to_s.clean_phone(self.contact.client.primary_area_code)
                      elsif technician.dig(:phone3).present?
                        technician.dig(:phone3).to_s.clean_phone(self.contact.client.primary_area_code)
                      else
                        ''
                      end,
          email:      technician.dig(:email).to_s
        }
      when 'servicetitan'
        tech_name = technician.dig(:name).to_s.dup.parse_name # added "dup" to unfreeze empty name string
        {
          ext_id:     technician.dig(:id).to_s,
          ext_source: self.ext_source,
          firstname:  tech_name.dig(:firstname).to_s,
          lastname:   tech_name.dig(:lastname).to_s,
          phone:      technician.dig(:phone).to_s.clean_phone(self.contact.client.primary_area_code),
          email:      technician.dig(:email).to_s
        }
      else
        {}
      end
    end
  end
end
