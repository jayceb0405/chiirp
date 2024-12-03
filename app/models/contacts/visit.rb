# frozen_string_literal: true

# app/models/contacts/visit.rb
module Contacts
  class Visit < ApplicationRecord
    self.table_name = 'contact_visits'

    belongs_to :contact
    belongs_to :job, class_name: '::Contacts::Job', optional: true

    validates :ext_id, :ext_source, :status, presence: true, allow_blank: true

    # replace Tags in message content with Contacts::Visit data
    # content = contact_visit.message_tag_replace(String)
    def message_tag_replace(message)
      # rubocop:disable Lint/InterpolationCheck
      client_api_integration = self.contact.client.client_api_integrations.find_by(target: self.ext_source.sub('housecallpro', 'housecall'), name: '')

      technician = if self.ext_tech_id.present? && ['#{tech-id}', '#{tech-name}', '#{tech-firstname}', '#{tech-phone}', '#{tech-email}', '#{tech-image}'].any? { |h| message.include?(h) }
                     self.technician
                   else
                     {}
                   end

      message = message.to_s
                       .gsub('#{visit-status}', self.status)
                       .gsub('#{visit-start_at}', self.start_at&.in_time_zone(self.contact.client.time_zone)&.strftime('%A, %B %d, %Y at %l:%M%P')&.gsub('  ', ' ') || '')
                       .gsub('#{visit-end_at}', self.end_at&.in_time_zone(self.contact.client.time_zone)&.strftime('%A, %B %d, %Y at %l:%M%P')&.gsub('  ', ' ') || '')

      case self.ext_source
      when 'jobber'

        message = if technician.present?
                    message
                      .gsub('#{tech-id}', technician.dig(:id).to_s)
                      .gsub('#{tech-name}', technician.dig(:name, :full).to_s)
                      .gsub('#{tech-firstname}', technician.dig(:name, :full).to_s.split.first)
                      .gsub('#{tech-phone}', technician.dig(:phone, :friendly).to_s)
                      .gsub('#{tech-email}', technician.dig(:email).to_s)
                  else
                    message
                      .gsub('#{tech-id}', '')
                      .gsub('#{tech-name}', '')
                      .gsub('#{tech-firstname}', '')
                      .gsub('#{tech-phone}', '')
                      .gsub('#{tech-email}', '')
                  end

        message = if message.include?('#{tech-image}') && client_api_integration && (user = User.find_by(id: client_api_integration.employees.dig(self.ext_tech_id))) && user.avatar.present?
                    message.gsub('#{tech-image}', user.avatar.url(secure_distribution: I18n.t("tenant.#{Rails.env}.cloudinary_cname"), transformation: [{ width: 250, height: 250, crop: 'scale', effect: 'outline:outer:1:0' }], format: 'png'))
                  else
                    message.gsub('#{tech-image}', '')
                  end
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
                     Integrations::ServiceTitan::Base.new(client_api_integration.credentials).technician(self.ext_tech_id)
                   elsif self.ext_source == 'jobber'
                     "Integration::Jobber::V#{client_api_integration.data.dig('credentials', 'version')}::Base".constantize.new(client_api_integration.credentials).user(self.ext_tech_id)
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
          phone:      technician.dig(:phone).to_s,
          email:      technician.dig(:email).to_s
        }
      else
        {}
      end
    end
  end
end
