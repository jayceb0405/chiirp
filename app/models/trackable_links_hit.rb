# frozen_string_literal: true

# app/models/trackable_links_hit.rb
class TrackableLinksHit < ApplicationRecord
  belongs_to :trackable_short_link
end
