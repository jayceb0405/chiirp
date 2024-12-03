# frozen_string_literal: true

# app/models/campaign_share_code.rb
class CampaignShareCode < ApplicationRecord
  belongs_to :campaign, optional: true
  belongs_to :campaign_group, optional: true

  after_initialize :apply_new_record_data, if: :new_record?

  private

  def apply_new_record_data
    self.share_code = RandomCode.new.create(20)
    self.share_code = RandomCode.new.create(20) while CampaignShareCode.find_by_share_code(self.share_code)
  end
end
