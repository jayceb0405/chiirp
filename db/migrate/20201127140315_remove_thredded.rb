class RemoveThredded < ActiveRecord::Migration[6.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Dropping VoiceRecordings...' do
      drop_table :thredded_user_post_notifications if table_exists?(:thredded_user_post_notifications)
      drop_table :thredded_messageboard_notifications_for_followed_topics if table_exists?(:thredded_messageboard_notifications_for_followed_topics)
      drop_table :thredded_notifications_for_followed_topics if table_exists?(:thredded_notifications_for_followed_topics)
      drop_table :thredded_notifications_for_private_topics if table_exists?(:thredded_notifications_for_private_topics)
      drop_table :thredded_post_moderation_records if table_exists?(:thredded_post_moderation_records)
      drop_table :thredded_user_topic_follows if table_exists?(:thredded_user_topic_follows)
      drop_table :thredded_messageboard_groups if table_exists?(:thredded_messageboard_groups)

      %i[topic private_topic].each do |topics_table|
        table_name = :"thredded_user_#{topics_table}_read_states"
        drop_table table_name if table_exists?(table_name)
      end

      drop_table :thredded_user_messageboard_preferences if table_exists?(:thredded_user_messageboard_preferences)
      drop_table :thredded_user_preferences if table_exists?(:thredded_user_preferences)
      drop_table :thredded_messageboard_users if table_exists?(:thredded_messageboard_users)
      drop_table :thredded_user_details if table_exists?(:thredded_user_details)
      drop_table :thredded_topics if table_exists?(:thredded_topics)
      drop_table :thredded_topic_categories if table_exists?(:thredded_topic_categories)
      drop_table :thredded_private_users if table_exists?(:thredded_private_users)
      drop_table :thredded_private_topics if table_exists?(:thredded_private_topics)
      drop_table :thredded_private_posts if table_exists?(:thredded_private_posts)
      drop_table :thredded_posts if table_exists?(:thredded_posts)
      drop_table :thredded_messageboards if table_exists?(:thredded_messageboards)
      drop_table :thredded_categories if table_exists?(:thredded_categories)
      drop_table :friendly_id_slugs if table_exists?(:friendly_id_slugs)
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
