# frozen_string_literal: true

# app/models/group.rb
class Group < ApplicationRecord
  belongs_to :client

  has_many   :aiagents,           dependent: :nullify
  has_many   :client_widgets,     dependent: nil, class_name: 'Clients::Widget'
  has_many   :contacts,           dependent: nil
  has_many   :tags,               dependent: nil
  has_many   :trackable_links,    dependent: nil
  has_many   :user_contact_forms, dependent: nil
  has_many   :webhooks,           dependent: nil

  # rubocop:disable Rails/UniqueValidationWithoutIndex
  validates :name, presence: true, length: { minimum: 2 }, uniqueness: { scope: [:client_id] }
  # rubocop:enable Rails/UniqueValidationWithoutIndex

  scope :for_client, ->(client_id) {
    where(client_id:)
  }

  # copy Group
  # group.copy
  def copy(args)
    new_client_id = args.dig(:new_client_id).to_i
    new_group     = nil

    new_client = if new_client_id.positive? && new_client_id != self.client_id
                   # new_client_id was received
                   Client.find_by(id: new_client_id)
                 else
                   # copy Group to same Client
                   self.client
                 end

    if new_client
      # Client was found

      # find or create Group for new Client
      new_group = new_client.groups.find_or_initialize_by(name: self.name)

      unless new_group.save
        # new Group could NOT be saved
        new_group = nil
      end
    end

    new_group
  end

  private

  def after_destroy_commit_actions
    super

    Groups::DestroyJob.perform_later(client_id: self.client_id, group_id: self.id)
  end
end
