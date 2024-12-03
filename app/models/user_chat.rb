# frozen_string_literal: true

# app/models/user_chat.rb
class UserChat < ApplicationRecord
  belongs_to       :from_user,         class_name: :User
  belongs_to       :to_user,           class_name: :User
  belongs_to       :contact,           optional: true

  private

  def after_create_commit_actions
    super

    update_cable
  end

  def after_destroy_commit_actions
    super

    update_cable
  end

  def after_update_commit_actions
    super

    update_cable
  end

  def update_cable
    # add new message to UserChat for recipient
    cable = UserCable.new

    html = ApplicationController.render partial: 'user_chats/chats/chat', locals: { recipient_user_id: self.from_user_id, chat: self }
    cable.broadcast(self.to_user.client, self.to_user, { id: "team_chats_#{self.from_user_id}", append: 'true', scrollup: 'true', html: })
    # cable.broadcast self.to_user.client, self.to_user, { turnon: "true", id: "user_chats_user_indicator_#{self.from_user_id}"}

    @users = self.to_user.by_last_chat
    html = ApplicationController.render partial: 'user_chats/users/user', collection: @users.collect { |_k, v| v }
    cable.broadcast(self.to_user.client, self.to_user, { id: "user_chats_users_inner_list_#{self.to_user_id}", append: 'false', scrollup: 'false', html: })

    @users = self.from_user.by_last_chat
    html = ApplicationController.render partial: 'user_chats/users/user', collection: @users.collect { |_k, v| v }
    cable.broadcast(self.from_user.client, self.from_user, { id: "user_chats_users_inner_list_#{self.from_user_id}", append: 'false', scrollup: 'false', html: })

    Users::SendPushJob.perform_later(
      content: self.content,
      title:   self.from_user.fullname,
      url:     Rails.application.routes.url_helpers.user_chats_path(id: self.from_user.id),
      user_id: self.to_user.id
    )
  end
end
