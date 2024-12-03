# frozen_string_literal: true

# app/models/task.rb
class Task < ApplicationRecord
  belongs_to :client
  belongs_to :contact, optional: true
  belongs_to :campaign, optional: true
  belongs_to :user, optional: true

  scope :current, -> {
    where(completed_at: nil)
      .where('due_at >= ?', Time.current.beginning_of_day)
      .where('due_at <= ?', Time.current.end_of_day)
  }
  scope :future, -> {
    where(completed_at: nil)
      .where('due_at > ?', Time.current.end_of_day)
  }
  scope :incomplete, -> {
    where(completed_at: nil)
  }
  scope :incomplete_by_contact, ->(contact_id) {
    where(contact_id:)
      .where(completed_at: nil)
  }
  scope :incomplete_by_user, ->(user_id) {
    where(user_id:)
      .where(completed_at: nil)
  }
  scope :past_deadline, -> {
    where(completed_at: nil)
      .where('deadline_at < ?', Time.current)
  }
  scope :past_due, -> {
    where(completed_at: nil)
      .where('due_at < ?', Time.current.beginning_of_day)
  }
  scope :scheduled, ->(user_id, from_date, to_date) {
    select(:id, :contact_id, :name, :due_at)
      .where(user_id:)
      .where(completed_at: nil)
      .where(due_at: from_date..to_date)
  }
  scope :someday, -> {
    where(due_at: nil)
  }

  # process Task actions defined by Client
  # task.apply_actions
  def apply_actions(args = {})
    task_action = args.dig(:task_action).to_s.strip

    return unless task_action.present? && self.client && self.contact

    self.contact.process_actions(
      campaign_id:       self.client.task_actions[task_action]['campaign_id'],
      group_id:          self.client.task_actions[task_action]['group_id'],
      stage_id:          self.client.task_actions[task_action]['stage_id'],
      tag_id:            self.client.task_actions[task_action]['tag_id'],
      stop_campaign_ids: self.client.task_actions[task_action]['stop_campaign_ids']
    )
  end

  # create a new Task
  # Task.create_new()
  #   (req) assign_to:           (String)
  #   (opt) campaign_id:         (Integer)
  #   (opt) cancel_after:        (Integer)
  #   (opt) contact_campaign_id: (Integer),
  #   (req) contact_id:          (Integer)
  #   (opt) description:         (String)
  #   (opt) dead_delay_days:     (Integer)
  #   (opt) dead_delay_hours:    (Integer)
  #   (opt) dead_delay_minutes:  (Integer)
  #   (opt) due_delay_days:      (Integer)
  #   (opt) due_delay_hours:     (Integer)
  #   (opt) due_delay_minutes:   (Integer)
  #   (opt) from_phone:          (String)
  #   (req) name:                (String)
  #   (opt) triggeraction_id:    (Integer)
  def self.create_new(args = {})
    task_name          = args.dig(:name).to_s.strip
    assign_to          = args.dig(:assign_to).to_s.split('_')
    contact_id         = args.dig(:contact_id).to_i
    from_phone         = args.dig(:from_phone).to_s.strip.downcase
    from_phone         = args.dig(:from_phone).to_s
    description        = args.dig(:description).to_s.strip
    campaign_id        = args.dig(:campaign_id).to_i
    due_delay_days     = args.dig(:due_delay_days).to_i
    due_delay_hours    = args.dig(:due_delay_hours).to_i
    due_delay_minutes  = args.dig(:due_delay_minutes).to_i
    dead_delay_days    = args.dig(:dead_delay_days).to_i
    dead_delay_hours   = args.dig(:dead_delay_hours).to_i
    dead_delay_minutes = args.dig(:dead_delay_minutes).to_i
    cancel_after       = args.dig(:cancel_after).to_i

    return unless contact_id.to_i.positive? && task_name.present? && assign_to[0].present? && (contact = Contact.find_by(id: contact_id))

    task_name   = contact.message_tag_replace(task_name)
    description = contact.message_tag_replace(description)
    due_at      = Time.current + due_delay_days.days + due_delay_hours.hours + due_delay_minutes.minutes
    deadline_at = due_at + dead_delay_days.days + dead_delay_hours.hours + dead_delay_minutes.minutes
    from_phone  = contact.user.default_from_twnumber&.phonenumber.to_s if from_phone == 'user_number'
    from_phone  = contact.latest_client_phonenumber(default_ok: true, phone_numbers_only: true)&.phonenumber.to_s if from_phone == 'last_number' || from_phone.blank?

    if assign_to[0] == 'user' && assign_to.length == 1
      contact.client.tasks.create(
        user_id:      contact.user.id,
        contact_id:   contact.id,
        name:         task_name,
        from_phone:,
        description:,
        campaign_id:,
        due_at:,
        deadline_at:,
        cancel_after:
      )
    elsif assign_to[0] == 'user' && assign_to.length == 2

      if (user = contact.client.users.find_by(id: assign_to[1].to_i))
        contact.client.tasks.create(
          user_id:      user.id,
          contact_id:   contact.id,
          name:         task_name,
          from_phone:,
          description:,
          campaign_id:,
          due_at:,
          deadline_at:,
          cancel_after:
        )
      end
    elsif assign_to[0] == 'orgposition' && assign_to.length == 2

      if (org_user = contact.client.org_users.find_by(user_id: contact.user_id))

        contact.client.org_users.where(org_group: org_user.org_group, org_position_id: assign_to[1].to_i).where.not(user_id: 0).find_each do |new_org_user|
          new_org_user.user.client.tasks.create(
            user_id:      new_org_user.user.id,
            contact_id:   contact.id,
            name:         task_name,
            from_phone:,
            description:,
            campaign_id:,
            due_at:,
            deadline_at:,
            cancel_after:
          )
        end
      end
    end
  end

  # send notification to User
  # task.notify_user
  def notify_user(args = {})
    return unless (args.dig(:title).to_s.strip + args.dig(:content).to_s.strip).present? && self.user

    if self.user.notifications.dig('task', 'by_push')
      Users::SendPushJob.perform_later(
        content: args[:content].to_s.strip,
        target:  %w[desktop mobile],
        title:   args[:title].to_s.strip,
        user_id: self.user_id
      )
    end

    return unless self.user.notifications.dig('task', 'by_text') && self.user.phone.present?

    delay_data = {
      content:    args[:content].to_s.strip,
      to_phone:   self.user.phone,
      from_phone: self.from_phone,
      contact_id: self.contact_id || 0,
      automated:  true,
      msg_type:   'textoutuser'
    }
    self.user.delay(
      run_at:     Time.current,
      priority:   DelayedJob.job_priority('send_text_to_user'),
      queue:      DelayedJob.job_queue('send_text_to_user'),
      process:    'send_text_to_user',
      contact_id: self.contact_id || 0,
      user_id:    self.user.id,
      data:       delay_data
    ).send_text(delay_data)
  end

  # send notifications to Users with past deadline_at dates
  # only send out once a day
  # Task.send_notifications_on_past_deadline
  def self.send_notifications_on_past_deadline
    Task.past_deadline.left_joins(:user, :contact).where('notified_at IS null OR notified_at < ?', 24.hours.ago).find_each do |task|
      content = []

      if task.cancel_after.positive? && (task.deadline_at + task.cancel_after.days) < Time.current
        # Task is more than cancel_after days past deadline_at
        task.update(completed_at: Time.current)
        content_addon = 'Task marked as completed.'
      else
        content_addon = ''
      end

      if task.user.notifications.dig('task', 'deadline')
        title = 'Task Deadline Passed'
        content << "Task (ID: #{task.id}): #{task.name} #{task.description}"
        content << "Contact: #{task.contact.fullname}" if task.contact
        content << "Deadline date: #{Friendly.new.date(task.deadline_at, task.user.client.time_zone, true)}."
        content << content_addon

        task.notify_user(title:, content: content.join(' '))
      end

      task.apply_actions(task_action: 'deadline') unless task.contact_id.nil?

      task.update(notified_at: Time.current)
    end
  end

  # send notifications to Users with past due_at dates
  # only send out once a day
  # Task.send_notifications_on_past_due
  def self.send_notifications_on_past_due
    Task.past_due.left_joins(:user, :contact).where('notified_at IS null OR notified_at < ?', 24.hours.ago).find_each do |task|
      if task.user.notifications&.dig('task', 'due')
        title    = 'Task Past Due'
        content  = "Task Past Due (ID: #{task.id}): #{task.name} #{task.description}"
        content += " Contact: #{task.contact.fullname}" if task.contact
        content += " Due date: #{Friendly.new.date(task.due_at, task.user.client.time_zone, true)}."

        task.notify_user(title:, content:)
      end

      task.apply_actions(task_action: 'due') unless task.contact_id.nil?

      task.update(notified_at: Time.current)
    end
  end

  private

  def after_create_commit_actions
    super

    if self.user.notifications.dig('task', 'created')
      title    = 'New Task'
      content  = "New task created (ID: #{self.id}): #{self.name} #{self.description}"
      content += " Contact: #{self.contact.fullname}" if self.contact
      content += " Due date: #{Friendly.new.date(self.due_at, self.user.client.time_zone, true)}." if self.completed_at.nil?
      content += " Date Completed: #{Friendly.new.date(self.completed_at, self.user.client.time_zone, true)}." unless self.completed_at.nil?

      self.notify_user(title:, content:)
    end

    self.apply_actions(task_action: 'assigned') unless self.contact_id.nil?
  end

  def after_update_commit_actions
    super

    if self.saved_changes? && self.saved_change_to_completed_at?

      if self.user.notifications.dig('task', 'completed')
        title    = 'Completed Task'
        content  = "Task completed (ID: #{self.id}): #{self.name} #{self.description}"
        content += " Contact: #{self.contact.fullname}" if self.contact
        content += " Due date: #{Friendly.new.date(self.due_at, self.user.client.time_zone, true)}."
        content += " Date Completed: #{self.completed_at.nil? ? '(removed)' : Friendly.new.date(self.completed_at, self.user.client.time_zone, true)}."

        self.notify_user(title:, content:)
      end

      if self.campaign_id.positive? && self.contact_id.to_i.positive?
        Contacts::Campaigns::StartJob.perform_later(
          campaign_id: self.campaign_id,
          client_id:   self.client_id,
          contact_id:  self.contact_id,
          user_id:     self.user_id
        )
      end
    elsif self.saved_changes? && !self.saved_change_to_notified_at? && self.user.notifications.dig('task', 'updated')
      title    = 'Updated Task'
      content  = "Task updated (ID: #{self.id}): #{self.name} #{self.description}"
      content += " Contact: #{self.contact.fullname}" if self.contact
      content += " Due date: #{Friendly.new.date(self.due_at, self.user.client.time_zone, true)}." if self.completed_at.nil?
      content += " Date Completed: #{Friendly.new.date(self.completed_at, self.user.client.time_zone, true)}." unless self.completed_at.nil?

      self.notify_user(title:, content:)
    end

    self.apply_actions(task_action: 'completed') if self.saved_change_to_completed_at? && !self.contact_id.nil? && !self.completed_at.nil?
  end
end
