require 'uri'

class ConvertAvatars < ActiveRecord::Migration[6.0]
  def change
    say_with_time 'Changing existing User Avatar to User_avatar...' do
      rename_column  :users, :avatar,  :user_avatar
    end

    say_with_time 'Converting User Avatars...' do
      User.find_each do |user|
        if user.user_avatar.present?
          begin
            user.avatar.attach(io: URI.open(user.user_avatar.url), filename: user.user_avatar.filename.split("/").last.strip.chomp)
            say "SUCCESS (User: #{user.id}: #{user.fullname}!"
          rescue
            say "FAILED (User: #{user.id}: #{user.fullname}!"
          end
        end
      end
    end
  end
end
