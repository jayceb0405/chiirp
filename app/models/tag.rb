# frozen_string_literal: true

# app/models/tag.rb
class Tag < ApplicationRecord
  belongs_to :campaign, optional: true
  belongs_to :client
  belongs_to :group,    optional: true
  belongs_to :stage,    optional: true
  belongs_to :tag,      optional: true

  has_many   :aiagents,           dependent: :nullify
  has_many   :client_widgets,     dependent: nil, class_name: 'Clients::Widget'
  has_many   :contacttags,        dependent: :destroy
  has_many   :postcards,          dependent: :nullify
  has_many   :tags,               dependent: nil
  has_many   :trackable_links,    dependent: nil
  has_many   :user_contact_forms, dependent: nil
  has_many   :webhooks,           dependent: nil

  has_many   :contacts,           through: :contacttags

  # rubocop:disable Rails/UniqueValidationWithoutIndex
  validates :name, presence: true, length: { minimum: 1 }, uniqueness: { scope: [:client_id] }
  # rubocop:enable Rails/UniqueValidationWithoutIndex

  before_create  :before_create_actions
  before_update  :before_update_actions
  before_destroy :delete_tag_references

  scope :for_client, ->(client_id) {
    where(client_id:)
  }

  # copy Tag
  # tag.copy
  def copy(args = {})
    new_client_id = args.dig(:new_client_id).to_i
    new_tag       = nil

    new_client = if new_client_id.positive? && new_client_id != self.client_id
                   # copy Tag to another Client
                   Client.find_by(id: new_client_id)
                 else
                   # copy Tag to same Client
                   self.client
                 end

    if new_client
      new_tag = new_client.tags.find_or_initialize_by(name: self.name)
      new_tag = nil unless new_tag.save
    end

    new_tag
  end

  private

  def after_destroy_commit_actions
    super

    Tags::DestroyJob.perform_later(client_id: self.client_id, tag_id: self.id)
  end

  def before_create_actions
    self.block_tag_id_stack_too_deep
  end

  def before_update_actions
    self.block_tag_id_stack_too_deep
  end

  def block_tag_id_stack_too_deep
    self.tag_id = 0 if self.id.to_i == self.tag_id.to_i
  end

  def delete_tag_references
    # rubocop:disable Rails/SkipsModelValidations
    # remove Tag id from Clients::Widget
    self.client.client_widgets.where(tag_id: self.id).update_all(tag_id: 0)

    # remove Tag id from TrackableLinks
    self.client.trackable_links.where(tag_id: self.id).update_all(tag_id: 0)

    # remove Tag id from UserContactForms
    self.client.users.each do |user|
      user.user_contact_forms.where(tag_id: self.id).update_all(tag_id: 0)
    end

    # remove Tag id from Webhooks
    self.client.webhooks.where(tag_id: self.id).update_all(tag_id: 0)
    # rubocop:enable Rails/SkipsModelValidations

    # remove Tag id from Packages
    Package.where("(package_data ->> 'tag_id')::int = ?", self.id.to_i).find_each do |package|
      package.update(tag_id: 0)
    end

    Campaigns::Destroyed::TriggeractionsJob.perform_later(client_id: self.client.id, tag_id: self.id)

    # remove Tag id from ClientApiIntegrations
    # ServiceTitan & HousecallPro Integrations
    ClientApiIntegration.where(client_id: self.client_id, target: 'servicetitan', name: '').find_each do |client_api_integration|
      client_api_integration.import['tag_id_0']                        = 0 if client_api_integration.import['tag_id_0'] == self.id
      client_api_integration.import['tag_id_above_0']                  = 0 if client_api_integration.import['tag_id_above_0'] == self.id
      client_api_integration.import['tag_id_below_0']                  = 0 if client_api_integration.import['tag_id_below_0'] == self.id
      client_api_integration.update_balance_actions['tag_id_0']        = 0 if client_api_integration.update_balance_actions['tag_id_0'] == self.id
      client_api_integration.update_balance_actions['tag_id_decrease'] = 0 if client_api_integration.update_balance_actions['tag_id_decrease'] == self.id
      client_api_integration.update_balance_actions['tag_id_increase'] = 0 if client_api_integration.update_balance_actions['tag_id_increase'] == self.id
      client_api_integration.save
    end
  end
end
