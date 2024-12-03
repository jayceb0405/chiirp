class AddRoutingMethodToTwnumber < ActiveRecord::Migration[7.0]
  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Migrating Twnumber model...' do
      remove_index    :twnumbers, :phonenumber, name: 'index_twnumbers_on_phonenumber'
      add_index       :twnumbers, :phonenumber, unique: true
      add_reference   :twnumbers, :vm_greeting_recording, null: true, default: nil, index: false, foreign_key: { to_table: :voice_recordings }
      add_reference   :twnumbers, :announcement_recording, null: true, default: nil, index: false, foreign_key: { to_table: :voice_recordings }

      Twnumber.find_each do |twnumber|
        twnumber.pass_routing              = [twnumber.data.dig('routing').to_s]
        twnumber.pass_routing_method       = 'chain'
        twnumber.pass_routing_phone_number = twnumber.data.dig('routing_phone_number').to_s
        twnumber.incoming_call_routing     = case twnumber.data.dig('voice_recording_use').to_s
                                             when 'vm'
                                               'play_vm'
                                             when 'play'
                                               'play'
                                             else
                                               'pass'
                                             end
        twnumber.announcement_recording_id = %w[play_vm, play].include?(twnumber.incoming_call_routing) && twnumber.voice_recording_id.positive? ? twnumber.voice_recording_id : nil
        twnumber.vm_greeting_recording_id  = %w[play_vm, play].include?(twnumber.incoming_call_routing) || twnumber.voice_recording_id.zero? ? nil : twnumber.voice_recording_id

        twnumber.data.delete('routing')
        twnumber.data.delete('routing_phone_number')
        twnumber.data.delete('voice_recording_use')
        twnumber.save
      end

      remove_column :twnumbers, :voice_recording_id

      User.find_each do |user|
        user.update(ring_duration: 20) if user&.ring_duration.to_i > 20
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Reverting Twnumber model...' do
      remove_index   :twnumbers, :phonenumber, name: 'index_twnumbers_on_phonenumber'
      add_index      :twnumbers, :phonenumber
      add_reference  :twnumbers, :voice_recording, null: false, default: 0

      Twnumber.find_each do |twnumber|
        twnumber.data['routing']              = twnumber.pass_routing.first
        twnumber.data['routing_phone_number'] = twnumber.pass_routing_phone_number
        twnumber.data['voice_recording_use']  = case twnumber.incoming_call_routing
                                                when 'play_vm'
                                                  'vm'
                                                when 'play'
                                                  'play'
                                                else
                                                  ''
                                                end
        twnumber.voice_recording_id           = %w[vm, play].include?(twnumber.data.dig('voice_recording_use').to_s) ? twnumber.announcement_recording_id : 0

        twnumber.data.delete('pass_routing')
        twnumber.data.delete('pass_routing_phone_number')
        twnumber.data.delete('pass_routing_method')
        twnumber.data.delete('incoming_call_routing')
        twnumber.save
      end

      remove_column :twnumbers, :vm_greeting_recording_id
      remove_column :twnumbers, :announcement_recording_id
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
