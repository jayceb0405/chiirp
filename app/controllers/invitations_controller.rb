# frozen_string_literal: true

# app/controllers/invitations_controller.rb
class InvitationsController < Devise::InvitationsController
  def after_accept_path_for(_resource)
    root_path
  end

  # TODO: why do we need this?
  # added on Sep 24, 2024 to alleviate users who are unable to log in due to the invitation_*_at fields being set
  def update
    super

    return unless resource.invitation_accepted_at

    resource.update!(
      invitation_created_at:  nil,
      invitation_accepted_at: nil,
      invitation_sent_at:     nil
    )
  end
end
