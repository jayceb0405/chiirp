# frozen_string_literal: true

# app/models/contacts/estimate.rb
module Contacts
  class Estimate < ApplicationRecord
    self.table_name = 'contact_estimates'

    belongs_to :contact
    belongs_to :job, class_name: '::Contacts::Job', optional: true

    has_many   :options, dependent: :delete_all, class_name: '::Contacts::Estimates::Option'
    has_many   :lineitems, as: :lineitemable, dependent: :delete_all, class_name: '::Contacts::Lineitem'

    validates  :estimate_number, :status, :ext_tech_id, :notes, :ext_source, :ext_id, presence: true, allow_blank: true
    validates  :address_01, :address_02, :city, :state, :postal_code, :country, presence: true, allow_blank: true
    validates  :scheduled_arrival_window, numericality: { only_integer: true }

    # replace Tags in message content with Contacts::Estimate data
    # content = contact_estimate.message_tag_replace(String)
    def message_tag_replace(message)
      # rubocop:disable Lint/InterpolationCheck
      client_api_integration = self.contact.client.client_api_integrations.find_by(target: self.ext_source.sub('housecallpro', 'housecall'), name: '')

      technician = if self.ext_tech_id.present? && ['#{tech-id}', '#{tech-name}', '#{tech-firstname}', '#{tech-phone}', '#{tech-email}', '#{tech-image}'].any? { |h| message.include?(h) }
                     self.technician
                   else
                     {}
                   end

      message = message.to_s
                       .gsub('#{estimate-estimate_number}', self.estimate_number)
                       .gsub('#{estimate-status}', self.status)
                       .gsub('#{estimate-scheduled_start_at}', self.scheduled_start_at&.in_time_zone(self.contact.client.time_zone)&.strftime('%A, %B %d, %Y at %l:%M%P')&.gsub('  ', ' ') || '')
                       .gsub('#{estimate-scheduled_end_at}', self.scheduled_end_at&.in_time_zone(self.contact.client.time_zone)&.strftime('%A, %B %d, %Y at %l:%M%P')&.gsub('  ', ' ') || '')
                       .gsub('#{estimate-scheduled_arrival_window_date}', self.scheduled_start_at&.in_time_zone(self.contact.client.time_zone)&.strftime('%A, %B %d, %Y') || '')
                       .gsub('#{estimate-actual_started_at}', self.actual_started_at&.in_time_zone(self.contact.client.time_zone)&.strftime('%A, %B %d, %Y at %l:%M%P')&.gsub('  ', ' ') || '')
                       .gsub('#{estimate-actual_completed_at}', self.actual_completed_at&.in_time_zone(self.contact.client.time_zone)&.strftime('%A, %B %d, %Y at %l:%M%P')&.gsub('  ', ' ') || '')
                       .gsub('#{estimate-actual_on_my_way_at}', self.actual_on_my_way_at&.in_time_zone(self.contact.client.time_zone)&.strftime('%A, %B %d, %Y at %l:%M%P')&.gsub('  ', ' ') || '')
                       .gsub('#{estimate-total_amount}', ActionController::Base.helpers.number_to_currency(self.total_amount.to_d))
                       .gsub('#{estimate-outstanding_balance}', ActionController::Base.helpers.number_to_currency(self.outstanding_balance.to_d))
                       .gsub('#{estimate-proposal_url}', self.proposal_url)

      message = if self.ext_source == 'servicetitan'
                  message.gsub('#{estimate-scheduled_arrival_window_time}', if self.scheduled_arrival_window_start_at.present? && self.scheduled_arrival_window_end_at.present?
                                                                              "#{self.scheduled_arrival_window_start_at.in_time_zone(self.contact.client.time_zone).strftime('%l:%M%P')} - #{self.scheduled_arrival_window_end_at.in_time_zone(self.contact.client.time_zone).strftime('%l:%M%P')}"
                                                                            else
                                                                              ''
                                                                            end)
                else
                  message.gsub('#{estimate-scheduled_arrival_window_time}', if self.scheduled_start_at.present?
                                                                              "#{self.scheduled_start_at.in_time_zone(self.contact.client.time_zone).strftime('%l:%M%P')}#{self.scheduled_arrival_window.positive? ? " - #{(self.scheduled_start_at.in_time_zone(self.contact.client.time_zone) + self.scheduled_arrival_window.to_i.minutes).strftime('%l:%M%P')}" : ''}"
                                                                            else
                                                                              ''
                                                                            end)
                end

      case self.ext_source
      when 'housecall', 'housecallpro', 'jobber'
        message = message
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

        if self.ext_sales_rep_id.present? && client_api_integration && (ext_sales_rep = Integration::Jobnimbus::V1::Base.new(client_api_integration).sales_rep_find(id: self.ext_sales_rep_id))
          message = message
                    .gsub('#{estimate-rep_name}', ext_sales_rep[:name])
                    .gsub('#{estimate-rep_email}', ext_sales_rep[:email])
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
                    message.gsub('#{tech-image}', ActionController::Base.helpers.cl_image_tag(user.avatar.key, secure_distribution: I18n.t("tenant.#{Rails.env}.cloudinary_cname"), transformation: [{ gravity: 'face', radius: 'max', crop: 'crop' }, { width: 100, crop: 'scale', effect: 'outline:outer:1:0' }], format: 'png'))
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

        if message.include?('#{tech-image}') && client_api_integration&.employees&.dig(technician.dig(:ext_id).to_s).to_i.positive? && (user = User.find_by(client_id: client_api_integration.client_id, id: client_api_integration.employees.dig(technician.dig(:ext_id).to_s)))
          message = if user.avatar.present?
                      message.gsub('#{tech-image}', user.avatar.url(secure_distribution: I18n.t("tenant.#{Rails.env}.cloudinary_cname"), transformation: [{ width: 250, height: 250, crop: 'scale', effect: 'outline:outer:1:0' }], format: 'png'))
                    else
                      message.gsub('#{tech-image}', '')
                    end
        end
      else
        message = message
                  .gsub('#{estimate-rep_name}', '')
                  .gsub('#{estimate-rep_email}', '')
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

    def technician
      return {} if self.ext_tech_id.blank?
      return {} unless (client_api_integration = self.contact.client.client_api_integrations.find_by(target: self.ext_source.sub('housecallpro', 'housecall'), name: ''))

      technician = if %w[housecall housecallpro].include?(self.ext_source)
                     Integration::Housecallpro::V1::Base.new(client_api_integration).technician(self.ext_tech_id)
                   elsif self.ext_source == 'servicemonster'
                     Integrations::ServiceMonster.new(client_api_integration.credentials).employee(self.ext_tech_id)
                   elsif self.ext_source == 'servicetitan'
                     Integration::Servicetitan::V2::Base.new(client_api_integration).technician(self.ext_tech_id)
                   elsif self.ext_source == 'jobber'
                     Integrations::JobBer::V20220915::Base.new(client_api_integration.credentials).user(self.ext_tech_id.to_i)
                   else
                     {}
                   end

      return {} if technician.blank?

      case self.ext_source
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
          email:      technician.dig(:email).to_s
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
