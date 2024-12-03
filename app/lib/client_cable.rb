# frozen_string_literal: true

class ClientCable
  def broadcast(client, hash)
    ActionCable.server.broadcast "client_channel:#{client.id}", hash if client
  end
end
