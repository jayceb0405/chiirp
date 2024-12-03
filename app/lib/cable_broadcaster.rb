# frozen_string_literal: true

# app/lib/cable_broadcaster.rb
class CableBroadcaster
  def broadcast(user, hash)
    ActionCable.server.broadcast "chat_channel:#{user.id}", hash if user
  end

  # update the meta data for the last Message for a Contact in Active Contacts
  # CableBoradcaster.new.active_contacts_typing()
  #   (req) contact: (Contact)
  def active_contacts_typing(contact, user, focus)
    return unless contact.is_a?(Contact)

    html = ApplicationController.render partial: 'central/sidebar/active_contacts/contact/user_typing', locals: { user_typing: user }

    contact.client.users.each do |u|
      case focus
      when 'on'
        broadcast u, { turnoff: true, id: "active_contacts_message_meta_#{contact.id}" }
        broadcast u, { turnon: true, id: "active_contacts_message_typing_#{contact.id}" }
        broadcast u, { append: 'false', id: "active_contacts_message_typing_#{contact.id}", html: }
      when 'off'
        broadcast u, { turnon: true, id: "active_contacts_message_meta_#{contact.id}" }
        broadcast u, { turnoff: true, id: "active_contacts_message_typing_#{contact.id}" }
      end
    end
  end

  # update Housecall Pro badge showing number of HCP customers remaining to be imported
  # CableBroadcaster.new.contacts_import_remaining(client: Client, count: String)
  def contacts_import_remaining(args = {})
    client = args.dig(:client)
    count  = args.dig(:count).to_s

    client = if client.is_a?(Client)
               client
             elsif client.is_a?(Integer)
               Client.find_by(id: client)
             end

    return unless client.is_a?(Client)

    client.users.each do |user|
      broadcast user, { append: 'false', id: 'contact_imports_remaining_count', html: count }
      broadcast user, { addclass: true, id: 'contact_imports_remaining', class: 'd-none' } if count == '0'
      broadcast user, { removeclass: true, id: 'contact_imports_remaining', class: 'd-none' } unless count == '0'
      broadcast user, { enable: true, id: 'import_contacts_button' } if count == '0'
      broadcast user, { disable: true, id: 'import_contacts_button' } unless count == '0'
    end
  end

  # update header unread messages icon & list
  # CableBroadcaster.new.unread_messages(user: User, light: Boolean)
  def unread_messages(args = {})
    user = if args.dig(:user).is_a?(User)
             args[:user]
           elsif args.dig(:user).is_a?(Integer)
             User.find_by(id: args[:user])
           end

    return if user.nil?

    # html = ApplicationController.render partial: 'layouts/looper/common/header/unread_messages_list', locals: { user: }
    # broadcast(user, { append: 'false', id: 'header_unread_messages_list', html: })
    if args.dig(:light).to_bool
      Api::Ui::V1::AlertsChannel.broadcast_to(user, { type: 'unread_messages', status: true }) if Api::Ui::V1::AlertsChannel.active_subscriptions_for?(user)
      broadcast user, { addclass: true, id: 'header_unread_messages_light', class: 'has-notified' }
    end

    return if args.dig(:light).to_bool

    Api::Ui::V1::AlertsChannel.broadcast_to(user, { type: 'unread_messages', status: false }) if Api::Ui::V1::AlertsChannel.active_subscriptions_for?(user)
    broadcast user, { removeclass: true, id: 'header_unread_messages_light', class: 'has-notified' }
  end
end
