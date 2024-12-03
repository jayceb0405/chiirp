# frozen_string_literal: true

# app/models/client_custom_field.rb
class ClientCustomField < ApplicationRecord
  belongs_to :client

  has_many   :contact_custom_fields, dependent: :destroy
  has_many   :org_positions,         dependent: nil

  serialize :var_options, coder: YAML, type: Hash

  # rubocop:disable Rails/UniqueValidationWithoutIndex
  validates :var_var, presence: true, length: { minimum: 1 }, uniqueness: { scope: [:client_id] }
  # rubocop:enable Rails/UniqueValidationWithoutIndex

  # after_initialize     :apply_new_record_data, if: :new_record?
  before_validation    :validate_data
  validate             :count_is_approved, on: [:create]

  # copy ClientCustomField
  # client_custom_field.copy
  def copy(args)
    new_client_id           = args.dig(:new_client_id).to_i
    new_client_custom_field = nil

    new_client = if new_client_id.positive? && new_client_id != self.client_id
                   # new_client_id was received
                   Client.find_by(id: new_client_id)
                 else
                   # copy ClientCustomField to same Client
                   self.client
                 end

    if new_client

      if (new_client_custom_field = new_client.client_custom_fields.find_by(var_var: self.var_var))
        # existing ClientCustomField was found
        new_client_custom_field.image_is_valid = self.image_is_valid

        case var_type
        when 'string'
          string_options     = self.var_options.dig(:string_options).to_s.split(',')
          new_string_options = new_client_custom_field.var_options.dig(:string_options).to_s.split(',')
          new_client_custom_field.var_options[:string_options] = (string_options + new_string_options).uniq.join(',')

          unless new_client_custom_field.save
            # new ClientCustomField could NOT be saved
            new_client_custom_field = nil
          end
        when 'numeric'
          new_client_custom_field.var_options[:numeric_min] = [new_client_custom_field.var_options.dig(:numeric_min).to_f, self.var_options.dig(:numeric_min).to_f].min
          new_client_custom_field.var_options[:numeric_max] = [new_client_custom_field.var_options.dig(:numeric_max).to_f, self.var_options.dig(:numeric_max).to_f].max

          unless new_client_custom_field.save
            # new ClientCustomField could NOT be saved
            new_client_custom_field = nil
          end
        when 'stars'
          new_client_custom_field.var_options[:stars_max] = [new_client_custom_field.var_options.dig(:stars_max).to_i, self.var_options.dig(:stars_max).to_i].max

          unless new_client_custom_field.save
            # new ClientCustomField could NOT be saved
            new_client_custom_field = nil
          end
        when 'currency'
          new_client_custom_field.var_options[:currency_min] = [new_client_custom_field.var_options.dig(:currency_min).to_d, self.var_options.dig(:currency_min).to_d].min
          new_client_custom_field.var_options[:currency_max] = [new_client_custom_field.var_options.dig(:currency_max).to_d, self.var_options.dig(:currency_max).to_d].max

          unless new_client_custom_field.save
            # new ClientCustomField could NOT be saved
            new_client_custom_field = nil
          end
          # when 'date'
        end
      elsif new_client.client_custom_fields.count < new_client.custom_fields_count.to_i
        # existing ClientCustomField was NOT found

        new_client_custom_field = self.dup
        new_client_custom_field.client_id = new_client.id

        unless new_client_custom_field.save
          # new ClientCustomField could NOT be saved
          new_client_custom_field = nil
        end
        # ClientCustomFields count is below maximum allowed

        # create a new ClientCustomField
      end
    end

    new_client_custom_field
  end

  def self.currency_fields(client)
    ClientCustomField.where(client_id: client.id, var_type: 'currency').order(:var_name).pluck(:var_name, :id)
  end

  def self.date_fields(client)
    ClientCustomField.where(client_id: client.id, var_type: 'date').order(:var_name).pluck(:var_name, :id)
  end

  def self.numeric_fields(client)
    ClientCustomField.where(client_id: client.id, var_type: 'numeric').order(:var_name).pluck(:var_name, :id)
  end

  def self.star_fields(client)
    ClientCustomField.where(client_id: client.id, var_type: 'stars').order(:var_name).pluck(:var_name, :id)
  end

  def self.string_fields(client)
    ClientCustomField.where(client_id: client.id, var_type: 'string').order(:var_name).pluck(:var_name, :id)
  end

  # convert a var_name to a variable style
  # First Name is converted to first_name
  # self.var_name_var
  def var_name_var
    self.var_name.downcase.gsub(%r{[^0-9a-z]}i, '_')
  end

  # split & format var_options[:string_options] into an array
  # client_custom_field.string_options_as_array
  def string_options_as_array
    self.var_options.dig(:string_options)&.split(',') || []
  end

  def string_options_for_select
    self.string_options_as_array.map { |x| [x, x] }
  end

  private

  def after_destroy_commit_actions
    super

    Triggeraction.for_client_and_action_type(self.client.id, [600, 605, 610]).find_each do |triggeraction|
      triggeraction.campaign.update(analyzed: triggeraction.campaign.analyze!.empty?) if triggeraction.client_custom_field_id.to_i == self.id
    end
  end

  def apply_new_record_data
    self.var_name        ||= ''
    self.var_var         ||= ''
    self.var_placeholder ||= ''
    self.var_type          = self.var_type.empty? ? 'text' : self.var_type
    self.var_options       = (self.var_options.empty? || !self.var_options.is_a?(Array) ? {} : self.var_options)
  end

  # confirm that count is less than Client.custom_fields_count setting
  def count_is_approved
    errors.add(:base, "Maximum Custom Fields for #{self.client.name} has been met.") unless self.client.client_custom_fields.count < self.client.custom_fields_count.to_i
  end

  def validate_data
    if self.var_var.empty?
      self.var_var = self.var_name_var
      self.var_var = self.var_var += '_c' while ::Webhook.internal_key_hash(self.client, 'contact', %w[personal phones action]).key?(self.var_var) || self.client.client_custom_fields.where(var_var: self.var_var).where.not(id: self.id).any?
    end

    self.var_options[:string_options] = self.var_options.dig(:string_options)&.split(',')&.map { |x| x.strip.gsub(%r{[^\w$()<>?!+~./:' &-]}, '') }&.join(',') || '' if self.var_type == 'string'
  end
end
