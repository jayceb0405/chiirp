# frozen_string_literal: true

# app/models/stage_parent.rb
class StageParent < ApplicationRecord
  belongs_to :client

  has_many :stages, -> { order(sort_order: :asc) }, inverse_of: :stage_parent, dependent: :destroy

  store_accessor :data, :users_permitted

  # rubocop:disable Rails/UniqueValidationWithoutIndex
  validates :name, presence: true, length: { minimum: 2 }, uniqueness: { scope: [:client_id] }
  # rubocop:enable Rails/UniqueValidationWithoutIndex

  after_initialize :apply_defaults, if: :new_record?

  scope :for_user, ->(user_id) {
    joins(:client)
      .joins(client: :users)
      .where(users: { id: user_id })
      .where('stage_parents.data @> ?', { users_permitted: [0] }.to_json)
      .or(StageParent.where('stage_parents.data @> ?', { users_permitted: [user_id] }.to_json))
      .uniq
  }

  # stage_parent.copy(new_client: Client)
  # (req) new_client: (Client)
  def copy(args = {})
    new_client       = args.dig(:new_client)
    new_stage_parent = nil

    return nil unless ((new_client.is_a?(Client) && !new_client.new_record?) || (new_client.to_i.positive? && (new_client = Client.find_by(id: new_client.to_i)))) &&
                      new_client.stages_count > new_client.stage_parents.count

    new_stage_parent = self.dup
    new_stage_parent.name            = "Copy of #{self.name}" if new_client.stage_parents.find_by(name: self.name)
    new_stage_parent.client_id       = new_client.id
    new_stage_parent.users_permitted = [0]
    new_stage_parent.new_share_code

    return nil unless new_stage_parent.save

    self.stages.find_each do |stage|
      stage.copy(new_stage_parent:)
    end

    new_stage_parent
  end

  def self.for_grouped_select(args = {})
    client_id = args.dig(:client_id).to_i

    StageParent.where(client_id:).order(:name).map do |stage_parent|
      [stage_parent.name, stage_parent.stages.order(:sort_order).map { |stage| [stage.name, stage.id] }]
    end
  end

  # change the share_code
  # stage_parent.new_share_code
  def new_share_code
    self.share_code = RandomCode.new.create(20)
    self.share_code = RandomCode.new.create(20) while StageParent.find_by(share_code: self.share_code)
  end

  def self.title
    I18n.t('activerecord.models.stage_parent.title')
  end

  private

  def apply_defaults
    new_share_code
    self.users_permitted ||= [0]
  end
end
