# frozen_string_literal: true

# app/models/webhook.rb
class Webhook < ApplicationRecord
  belongs_to :client
  belongs_to :campaign,       optional: true
  belongs_to :group,          optional: true
  belongs_to :stage,          optional: true
  belongs_to :tag,            optional: true

  has_many :webhook_maps, dependent: :delete_all

  # rubocop:disable Rails/UniqueValidationWithoutIndex, Rails/I18nLocaleTexts
  validates :name, presence: true, uniqueness: { scope: :client_id, message: 'must be unique.' }
  # rubocop:enable Rails/UniqueValidationWithoutIndex, Rails/I18nLocaleTexts

  serialize :sample_data, coder: YAML, type: Hash

  after_initialize :apply_defaults, if: :new_record?

  scope :for_client, ->(client_id) {
    where(client_id:)
  }

  # return an internal key for a given external key
  # webhook.find_internal_key(external_key)
  #   (req) external_key: (String)
  def find_internal_key(external_key)
    self.webhook_maps.find_by(external_key:)&.internal_key.to_s
  end

  def stop_campaigns_names
    return ['All Campaigns'] if self.stop_campaign_ids.include?(0)

    self.client.campaigns.where(id: self.stop_campaign_ids).pluck(:name)
  end

  # generate a complete hash of all available Webhook internal keys
  # personal Contact keys + ClientCustomField keys + Webhook action keys
  # ::Webhook.internal_key_hash(client, data_type, fields)
  #   (req) client:    (Client)
  #   (req) data_type: (String)
  #           "contact": keys for Contact
  #           "user":    keys for User
  #   (opt) fields:    (Array)
  #           %w[action custom_fields ext_references personal phones reserved user]
  def self.internal_key_hash(client, data_type, fields = %w[personal phones custom_fields action])
    response = {}

    fields.each do |f|
      response.merge!(send(:"internal_key_hash_#{f}", client:, data_type:))
    end

    response
  end

  # rubocop:disable Lint/UnusedMethodArgument

  # generate a hash of available Webhook internal keys
  # Webhook action keys only
  # ::Webhook.internal_key_hash_action(client: Client, data_type: String)
  #   (req) client:    (Client)
  #   (opt) data_type: (String)
  #           "contact": keys for Contact
  #           "user":    keys for User
  def self.internal_key_hash_action(client:, data_type: 'contact')
    {
      'note'      => 'Note',
      'datetimez' => 'Date UTC (Appointment Campaign)',
      'datetimel' => 'Date Local (Appointment Campaign)',
      'datetimeu' => 'Date (UNIX) (Appointment Campaign',
      'yesno'     => 'Variable Response'
    }
  end

  # generate a hash of available webhook custom field keys for Contact::Client
  # ::Webhook.internal_key_hash_custom_fields(client: Client, data_type: String)
  #   (req) client:    (Client)
  #   (opt) data_type: (String)
  #           "contact": keys for Contact
  #           "user":    keys for User
  def self.internal_key_hash_custom_fields(client:, data_type: 'contact')
    client.client_custom_fields.pluck(:var_var, :var_name).to_h
  end

  # generate a hash of available webhook internal keys for Contact::ExtReferences
  # ::Webhook.internal_key_hash_ext_references(client: Client, data_type: String)
  #   (req) client:    (Client)
  #   (opt) data_type: (String)
  #           "contact": keys for Contact
  #           "user":    keys for User
  def self.internal_key_hash_ext_references(client:, data_type: 'contact')
    case data_type
    when 'contact'
      ApplicationController.helpers.ext_references_options(client).to_h { |e| ["contact-#{e[1]}-id", "Contact #{e[0]} ID"] }
    when 'user'
      {
        'ext_ref_id' => 'External Reference ID'
      }
    else
      {}
    end
  end

  # generate a hash of available Webhook internal keys
  # personal Contact keys only
  # ::Webhook.internal_key_hash_personal(client: Client, data_type: String)
  #   (req) client:    (Client)
  #   (opt) data_type: (String)
  #           "contact": keys for Contact
  #           "user":    keys for User
  def self.internal_key_hash_personal(client:, data_type: 'contact')
    response = {
      'companyname' => 'Company Name',
      'firstname'   => 'First Name',
      'lastname'    => 'Last Name',
      'fullname'    => 'Full Name',
      'email'       => 'Email Address'
    }

    case data_type
    when 'contact'
      response.merge!({
                        'address1'  => 'Address',
                        'address2'  => 'Address Line 2',
                        'city'      => 'City',
                        'state'     => 'State',
                        'zipcode'   => 'Zip Code',
                        'birthdate' => 'Birth Date'
                      })
    when 'user'
      response.merge!({
                        'phone' => 'Phone Number'
                      })
    end
  end

  # generate a hash of available Webhook internal keys
  # ContactPhone keys only
  # ::Webhook.internal_key_hash_phones(client: Client, data_type: String)
  #   (req) client: (Client)
  #   (opt) data_type: (String)
  #           "contact": keys for Contact
  #           "user":    keys for User
  def self.internal_key_hash_phones(client:, data_type: 'contact')
    client.contact_phone_labels.to_h { |label| ["phone_#{label}", "#{label.capitalize} Phone"] }
  end

  # generate a hash of available webhook internal keys for Contact::User
  # ::Webhook.internal_key_hash_user(client: Client, data_type: String)
  #   (req) client:    (Client)
  #   (opt) data_type: (String)
  #           "contact": keys for Contact
  #           "user":    keys for User
  def self.internal_key_hash_user(client:, data_type: 'contact')
    if data_type == 'contact'
      {
        'user_name'  => 'User Name',
        'user_id'    => 'User ID',
        'user_phone' => 'User Phone Number'
      }
    else
      {}
    end
  end

  # rubocop:enable Lint/UnusedMethodArgument

  # determine if external key connects to a reserved internal key
  # webhook.reserved_external_key?(data_type, client, external_key)
  #   (req) data_type:    (String)
  #           "contact": keys for Contact
  #           "user":    keys for User
  #   (req) client:       (Client)
  #   (req) external_key: (String)
  def reserved_external_key?(data_type, client, external_key)
    internal_key = self.find_internal_key(external_key)
    self.reserved_internal_key?(data_type, client, internal_key)
  end

  # determine if internal key is a reserved key
  # webhook.reserved_internal_key?(data_type, client, external_key)
  #   (req) data_type:    (String)
  #           "contact": keys for Contact
  #           "user":    keys for User
  #   (req) client:       (Client)
  #   (req) internal_key: (String)
  def reserved_internal_key?(data_type, client, internal_key)
    self.class.internal_key_hash(client, data_type, %w[personal phones action]).key?(internal_key)
  end

  # determine if internal key is variable from external key
  # webhook.is_variable_response_from_external_key?(data_type, client, external_key)
  #   (req) data_type:    (String)
  #           "contact": keys for Contact
  #           "user":    keys for User
  #   (req) client:       (Client)
  #   (req) external_key: (String)
  def variable_response_from_external_key?(data_type, client, external_key)
    return false unless (internal_key = self.find_internal_key(external_key))

    self.variable_response_from_internal_key?(data_type, client, internal_key)
  end

  # determine if internal key is variable
  # webhook.is_variable_response_from_internal_key?(data_type, client, internal_key)
  #   (req) data_type:    (String)
  #           "contact": keys for Contact
  #           "user":    keys for User
  #   (req) client:       (Client)
  #   (req) internal_key: (String)
  def variable_response_from_internal_key?(data_type, client, internal_key)
    if internal_key == 'yesno'
      true
    elsif self.class.internal_key_hash(client, data_type, %w[personal phones action]).key?(internal_key)
      false
    else
      client_custom_field = self.client.client_custom_fields.find_by(var_var: internal_key)
      client_custom_field && client_custom_field.var_type == 'string' && client_custom_field.var_options.include?(:string_options) && client_custom_field.string_options_as_array.present?
    end
  end

  # return hash of available responses to an external key
  #   {"Yes"=>"23,72", "No"=>"12,82"}
  #   left number in value is Campaign id
  #   right number in value is Tag id
  # webhook.variable_responses_from_external_key(data_type, client, external_key)
  #   (req) data_type:    (String)
  #           "contact": keys for Contact
  #           "user":    keys for User
  #   (req) client:       (Client)
  #   (req) external_key: (String)
  def variable_responses_from_external_key(data_type, client, external_key)
    return {} unless (internal_key = self.find_internal_key(external_key))

    if (webhook_map = self.webhook_maps.find_by(external_key:))
      webhook_map.response || {}
    else
      self.variable_responses_from_internal_key(data_type, client, internal_key) || {}
    end
  end

  # return hash of available responses to an internal key
  #   {"Yes"=>"23,72", "No"=>"12,82"}
  #   left number in value is Campaign id
  #   right number in value is Tag id
  # webhook.variable_responses_from_internal_key(data_type, client, internal_key)
  #   (req) data_type:    (String)
  #           "contact": keys for Contact
  #           "user":    keys for User
  #   (req) client:       (Client)
  #   (req) internal_key: (String)
  def variable_responses_from_internal_key(data_type, client, internal_key)
    response = {}

    if !self.class.internal_key_hash(client, data_type, %w[personal phones action]).key?(internal_key) && ((client_custom_field = self.client.client_custom_fields.find_by(var_var: internal_key)) && client_custom_field.var_type == 'string' && client_custom_field.var_options.include?(:string_options))

      client_custom_field.string_options_as_array.each do |vo|
        response[vo] = ' , ' unless response.key?(vo)
      end
    end

    response
  end

  # generate a SHA1 string from Client id, Webhook id, random salt and time
  # ::Webhook.generate_webhook_token({ client_id: Integer, webhook_id: Integer })
  #   (opt) client_id:  (Integer)
  #   (opt) webhook_id: (Integer)
  def self.generate_webhook_token(params)
    # rubocop:disable Performance/Sum
    client_id  = (params.include?(:client_id) ? params[:client_id].to_s : Time.current.strftime('%H:%M:%S').split(':').map(&:to_i).inject(0) { |sum, x| sum + x }.to_s)
    webhook_id = (params.include?(:webhook_id) ? params[:webhook_id].to_s : Time.current.strftime('%d:%m:%y:%H:%M:%S').split(':').map(&:to_i).inject(0) { |sum, x| sum + x }.to_s)
    # rubocop:enable Performance/Sum
    webhook_token = nil

    loop do
      webhook_token = Digest::SHA1.hexdigest("#{client_id}#{webhook_id}#{RandomCode.new.salt}#{Time.now.to_i}")

      break if ::Webhook.where(token: webhook_token).first.blank?
    end

    webhook_token
  end

  private

  def apply_defaults
    self.testing   = '1' if self.new_record?
    self.data_type = 'contact' if self.new_record?
  end
end
