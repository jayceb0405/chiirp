# frozen_string_literal: true

#
# app/models/package_campaign.rb
class PackageCampaign < ApplicationRecord
  belongs_to :package
  belongs_to :campaign, optional: true
  belongs_to :campaign_group, optional: true
end
