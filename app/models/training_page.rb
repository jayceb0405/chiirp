# frozen_string_literal: true

# app/models/training_page.rb
class TrainingPage < ApplicationRecord
  belongs_to :training

  # authorize User to edit TrainingPage
  # TrainingPage.user_authorized?( User, Training, String )
  def self.user_authorized?(user, training, action_name)
    # rubocop:disable Lint/DuplicateBranch
    if !user.client.active?
      # Client is NOT active
      false
    elsif user.super_admin?
      # SuperAdmin can do anything
      true
    elsif training && %w[create destroy edit new update].include?(action_name) && user.trainings_editable.include?(training.id.to_s) && user.access_controller?('trainings', 'allowed')
      # User may edit Training
      true
    elsif training && %w[index show].include?(action_name) && user.client.training.include?(training.id.to_s) && user.access_controller?('trainings', 'allowed')
      # User may view Training
      true
    else
      false
    end
    # rubocop:enable Lint/DuplicateBranch
  end
end
