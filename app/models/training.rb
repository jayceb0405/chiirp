# frozen_string_literal: true

# app/models/training.rb
class Training < ApplicationRecord
  has_many :training_pages, dependent: :destroy

  # authorize User to edit Training
  # Training.user_authorized?( User, Training, String )
  #   (req) user:        (User)
  #   (req) training:    (Training)
  #   (req) action_name: (String)
  def self.user_authorized?(user, training, action_name)
    # rubocop:disable Lint/DuplicateBranch
    if !user.client.active?
      # Client is NOT active
      false
    elsif user.super_admin?
      # SuperAdmin can do anything
      true
    elsif %w[create destroy new].include?(action_name)
      # only SuperAdmin can create or destroy Training
      false
    elsif training && %w[edit update].include?(action_name) && user.trainings_editable.include?(training.id.to_s)
      # User may perform desired action
      true
    elsif training && %w[index show].include?(action_name) && user.client.training.include?(training.id.to_s)
      # User may view Training
      true
    else
      false
    end
    # rubocop:enable Lint/DuplicateBranch
  end
end
