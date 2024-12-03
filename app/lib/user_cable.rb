# frozen_string_literal: true

# app/lib/user_cable.rb
class UserCable
  def broadcast(_client, user, hash)
    return unless user

    ActionCable.server.broadcast "chat_channel:#{user.id}", hash
  end
end
