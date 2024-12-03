# frozen_string_literal: true

# app/lib/show_live_messenger.rb
class ShowLiveMessenger
  # Create the object
  # show_live_messenger = ShowLiveMessenger.new(message: Messages::Message)
  def initialize(args = {})
    @message   = args.dig(:message)
    @contact   = @message&.contact
    @user      = @contact&.user
    @client    = @contact&.client
    @cable     = args.dig(:cable) || UserCable.new
  end

  # Broadcast update to Message Central Active Contacts
  # show_live_messenger.broadcast_active_contacts()
  # (req) user_id: (Integer) the User for which to update Active Contacts
  def broadcast_active_contacts(user_id)
    return unless @message.is_a?(Messages::Message) && user_id.to_i.positive? && (user = User.find_by(id: user_id))

    presenter = CentralPresenter.new(client: user.client, user:, contact: @contact)
    html = ApplicationController.render partial: 'central/sidebar/active_contacts/active_contacts', locals: { presenter: }
    @cable.broadcast(@client, user, { append: 'false', id: 'active_contacts_index', html: })

    return unless Api::Ui::V1::ActiveContactsChannel.active_subscriptions_for?(user)

    json = ApplicationController.render partial: 'central/sidebar/active_contacts/active_contacts', locals: { presenter: }, formats: [:json]
    Api::Ui::V1::ActiveContactsChannel.broadcast_to(user, JSON.parse(json))
  end

  # Queue Broadcast update to Message Central Active Contacts for all Users viewing list that would include Contact
  # show_live_messenger.queue_broadcast_active_contacts
  def queue_broadcast_active_contacts
    return unless @message.is_a?(Messages::Message)

    self.user_ids_with_contact_in_active_contacts_and_not_in_queue.each do |user_id|
      self.delay(
        run_at:              Time.current,
        priority:            DelayedJob.job_priority('show_active_contacts'),
        queue:               DelayedJob.job_queue('show_active_contacts'),
        user_id:,
        contact_id:          @contact.id,
        triggeraction_id:    0,
        contact_campaign_id: 0,
        group_process:       0,
        process:             'show_active_contacts',
        data:                { message: @message, user_id: }
      ).broadcast_active_contacts(user_id)
    end
  end

  # Broadcast message to Message Central message thread to append to thread
  # show_live_messenger.broadcast_message_thread_message()
  # (req) user_id: (Integer) the User for which to update message thread
  def broadcast_message_thread_message(user_id)
    return unless @message.is_a?(Messages::Message) && (user = User.find_by(id: user_id))

    presenter = CentralPresenter.new(client: @client, user:, contact: @contact)
    html = ApplicationController.render partial: 'central/conversation/message', locals: { message: @message, presenter: }
    @cable.broadcast(@client, user, { replace_or_append: 'true', append_id: "conversation_list_#{@contact.id}", replace_id: @message.id, html:, scrollup: 'true' })

    return unless Api::Ui::V1::MessageCentralChannel.active_subscriptions_for?([@contact, user])

    json = ApplicationController.render partial: 'central/conversation/message', locals: { message: @message, presenter: }, formats: [:json]
    Api::Ui::V1::MessageCentralChannel.broadcast_to([@contact, user], JSON.parse(json))
  end

  # Queue Broadcast message to Message Central message thread to append to thread for all Users viewing the Contact message thread
  # show_live_messenger.queue_broadcast_message_thread_message
  def queue_broadcast_message_thread_message
    return unless @message.is_a?(Messages::Message)

    user_ids_viewing_contact_and_not_in_queue.each do |user_id|
      self.delay(
        run_at:              Time.current,
        priority:            DelayedJob.job_priority('show_message_thread_message'),
        queue:               DelayedJob.job_queue('show_message_thread_message'),
        user_id:,
        contact_id:          @contact.id,
        triggeraction_id:    0,
        contact_campaign_id: 0,
        group_process:       0,
        process:             'show_message_thread_message',
        data:                { message: @message, user_id: }
      ).broadcast_message_thread_message(user_id)
    end
  end

  private

  # message = Messages::Message.last; show_live_messenger = ShowLiveMessenger.new(message:); show_live_messenger.send(:user_ids_viewing_contact_and_not_in_queue)
  # return array of User.ids who are currently viewing the message thread for Contact and who do not have "show_message_thread_message" already queued
  def user_ids_viewing_contact_and_not_in_queue
    user_ids = Users::RedisPool.new(@user.id).users_viewing_contact(@contact.id)
    user_ids += Api::Ui::V1::MessageCentralChannel.active_subscriptions_for_prefix(@contact).map { |x| GlobalID::Locator.locate(x.split(':').last)&.id }
    (user_ids - DelayedJob.where(user_id: user_ids, process: 'show_message_thread_message', contact_id: @contact.id).pluck(:id)).uniq
  end

  # return array of User.ids who belong to the Contact's Client or who are Agents of the Contact's Client
  def user_ids_with_access_to_contact
    @client.users.pluck(:id) + User.where(client_id: @client.my_agencies).where('data @> ?', { agent: true }.to_json).pluck(:id)
  end

  # return array of User.ids who may have the Contact listed in their Active Contacts
  def user_ids_with_contact_in_active_contacts
    Users::Setting.where(controller_action: 'message_central', user_id: user_ids_with_access_to_contact)
                  .map do |us|
      us.user_id if
          !us.data.dig(:active_contacts_paused) &&
          (([0, @user.id] & us.data.dig(:show_user_ids)&.collect { |x| x if x[0, 4] != 'all_' }.to_a.compact_blank.map(&:to_i)).present? ||
          us.data.dig(:show_user_ids)&.collect { |x| x[4..] if x[0, 4] == 'all_' }.to_a.compact_blank.map(&:to_i).include?(@client.id))
    end.compact_blank
  end

  # message = Messages::Message.last; show_live_messenger = ShowLiveMessenger.new(message:); show_live_messenger.send(:user_ids_with_contact_in_active_contacts_and_not_in_queue)
  # return array of User.ids who may have the Contact listed in their Active Contacts and who do not have "show_active_contacts" already queued
  def user_ids_with_contact_in_active_contacts_and_not_in_queue
    user_ids = user_ids_with_contact_in_active_contacts
    (user_ids - DelayedJob.where(user_id: user_ids, process: 'show_active_contacts', contact_id: @contact.id).pluck(:id)).map { |u| u if Users::RedisPool.new(u).message_central_visible? || Api::Ui::V1::ActiveContactsChannel.active_subscriptions_for?(GlobalID.new(URI::GID.build(app: GlobalID.app, model_name: 'User', model_id: u))) }.compact_blank
  end
end
