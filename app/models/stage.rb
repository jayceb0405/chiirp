# frozen_string_literal: true

# app/models/stage.rb
class Stage < ApplicationRecord
  belongs_to :stage_parent
  belongs_to :campaign, optional: true

  has_many   :aiagents,           dependent: :nullify
  has_many   :contacts,           dependent: nil
  has_many   :client_widgets,     dependent: nil, class_name: 'Clients::Widget'
  has_many   :tags,               dependent: nil
  has_many   :trackable_links,    dependent: nil
  has_many   :user_contact_forms, dependent: nil
  has_many   :webhooks,           dependent: nil

  store_accessor :data, :show_custom_fields

  # rubocop:disable Rails/UniqueValidationWithoutIndex
  validates :name, presence: true, length: { minimum: 2 }, uniqueness: { scope: [:stage_parent_id] }
  # rubocop:enable Rails/UniqueValidationWithoutIndex

  after_initialize :apply_defaults, if: :new_record?

  scope :for_client, ->(client_id) {
    joins(:stage_parent)
      .where(stage_parent: { client_id: })
  }

  # Copy a Stage within same Client or to a new Client
  # When copying a Stage the StageParent and all linked Stages must be copied
  # if StageParent already exists and Stage already exists within Stage Parent return existing Stage
  # stage.copy(new_client: Client, new_stage_parent: StageParent)
  def copy(args = {})
    new_client       = args.dig(:new_client)
    new_stage_parent = args.dig(:new_stage_parent)
    new_stage        = nil

    if (new_stage_parent.is_a?(StageParent) && !new_stage_parent.new_record?) || (new_stage_parent.to_i.positive? && (new_stage_parent = StageParent.find_by(id: new_stage_parent.to_i)))

      unless (new_stage = new_stage_parent.stages.find_by(name: [self.name, "Copy of #{self.name}"]))
        new_stage                 = self.dup
        new_stage.name            = "Copy of #{self.name}" if new_stage_parent.stages.find_by(name: self.name)
        new_stage.stage_parent_id = new_stage_parent.id

        new_stage = nil unless new_stage.save
      end
    elsif (new_client.is_a?(Client) && !new_client.new_record?) || (new_client.to_i.positive? && (new_client = Client.find_by(id: new_client.to_i)))

      unless (new_stage_parent = StageParent.find_by(client_id: new_client.id, name: [self.stage_parent.name, "Copy of #{self.stage_parent.name}"]) && (new_stage = new_stage_parent.stages.find_by(name: [self.name, "Copy of #{self.name}"]))) &&
             !((new_stage_parent = self.stage_parent.copy(new_client:)) && (new_stage = new_stage_parent&.stages&.find_by(name: [self.name, "Copy of #{self.name}"])))

        new_stage = nil
      end
    end

    new_stage
  end

  def self.title
    I18n.t('activerecord.models.stage.title')
  end

  private

  def after_create_commit_actions
    super

    # rubocop:disable Rails/SkipsModelValidations
    Stage.where(stage_parent_id: self.stage_parent_id).where.not(id: self.id).where(sort_order: self.sort_order..).update_all('sort_order = sort_order + 1')
    # rubocop:enable Rails/SkipsModelValidations
  end

  def after_destroy_commit_actions
    super

    Stages::DestroyJob.perform_later(client_id: self.stage_parent.client_id, stage_id: self.id, stage_parent_id: self.stage_parent_id, sort_order: self.sort_order)
  end

  def after_update_commit_actions
    super

    # rubocop:disable Rails/SkipsModelValidations
    Stage.where(stage_parent_id: self.stage_parent_id).where.not(id: self.id).where(sort_order: self.sort_order..).update_all('sort_order = sort_order + 1')
    # rubocop:enable Rails/SkipsModelValidations
  end

  def apply_defaults
    self.show_custom_fields ||= []
  end
end
