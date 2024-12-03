class AddUserTasksAllowedToClientsAndPackages < ActiveRecord::Migration[5.2]
  def up
    rename_column  :tasks,             :date_due,          :due_at
    rename_column  :tasks,             :date_completed,    :completed_at
    rename_column  :tasks,             :deadline,          :deadline_at
    add_column     :tasks,             :notified_at,       :datetime,          null: true,         default: nil

    ActiveRecord::Base.record_timestamps = false

  	Package.find_each do |package|
      package.save
  	end

  	Client.find_each do |client|
      client.save
  	end

    User.find_each do |user|
      user.task_notify["by_text"] = user.data.include?("tasks_notify_by_text") ? user.data["tasks_notify_by_text"] : true
      user.task_notify["by_push"] = user.data.include?("tasks_notify_by_push") ? user.data["tasks_notify_by_push"] : true
      user.task_notify["created"] = user.data.include?("tasks_notify_created") ? user.data["tasks_notify_created"] : true
      user.task_notify["updated"] = user.data.include?("tasks_notify_updated") ? user.data["tasks_notify_updated"] : true
      user.data.delete("tasks_notify_by_text")
      user.data.delete("tasks_notify_by_push")
      user.data.delete("tasks_notify_created")
      user.data.delete("tasks_notify_updated")
      user.save
    end

    Task.where("due_at < ?", Time.current-30.days).where(completed_at: nil).update_all(completed_at: Time.current)
    
    ActiveRecord::Base.record_timestamps = true
  end

  def down
    ActiveRecord::Base.record_timestamps = false

  	Package.find_each do |package|
  		package.package_data.delete("tasks_allowed")
  		package.package_data.delete("task_actions")
  		package.save
  	end

  	Client.find_each do |client|
  		client.data.delete("tasks_allowed")
  		client.data.delete("task_actions")
  		client.save
  	end

    User.find_each do |user|
      user.data["tasks_notify_by_text"] = user.data.include?("task_notify") && user.data["task_notify"].include?("by_text") ? user.data["task_notify"]["by_text"] : true
      user.data["tasks_notify_by_push"] = user.data.include?("task_notify") && user.data["task_notify"].include?("by_push") ? user.data["task_notify"]["by_push"] : true
      user.data["tasks_notify_created"] = user.data.include?("task_notify") && user.data["task_notify"].include?("created") ? user.data["task_notify"]["created"] : true
      user.data["tasks_notify_updated"] = user.data.include?("task_notify") && user.data["task_notify"].include?("updated") ? user.data["task_notify"]["updated"] : true
      user.data.delete("task_notify")
      user.save
    end

    ActiveRecord::Base.record_timestamps = true

    rename_column  :tasks,             :due_at,            :date_due
    rename_column  :tasks,             :completed_at,      :date_completed
    rename_column  :tasks,             :deadline_at,       :deadline
    remove_column  :tasks,             :notified_at
  end
end
