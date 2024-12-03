class CreateVoiceRecordings < ActiveRecord::Migration[6.0]
  class VoiceMailRecording < ApplicationRecord
  end
  class VoiceRecording < ApplicationRecord
  end

  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Creating VoiceRecordings...' do
      drop_table :voice_recordings if ActiveRecord::Base.connection.table_exists? :voice_recordings

      create_table :voice_recordings do |t|
        t.references :client, foreign_key: true
        t.string     :recording_name,    default: '',        null: false,        index: true
        t.string     :sid,               default: '',        null: false
        t.string     :url,               default: '',        null: false

        t.timestamps
      end
    end

    say_with_time 'Adding \'voice_recording_id\' to Twmessages...' do
      add_reference  :twmessages,        :voice_recording,   null: false,        default: 0
    end

    say_with_time 'Adding columns to Twnumbers...' do
      add_reference  :twnumbers,         :voice_recording,   null: false,        default: 0
      add_column     :twnumbers,         :data,              :jsonb,             null: false,        default: {}
    end

    voice_recordings_array = []

    say_with_time 'Migrating VoiceMailRecordings to VoiceRecordings...' do
      VoiceMailRecording.all.find_each do |voice_mail_recording|
        voice_recording = VoiceRecording.create!(
          client_id:      voice_mail_recording.client_id,
          recording_name: voice_mail_recording.name,
          sid:            voice_mail_recording.sid,
          url:            voice_mail_recording.url,
          created_at:     voice_mail_recording.created_at,
          updated_at:     voice_mail_recording.updated_at
        )
        
        voice_recordings_array << {
          old_voice_recording_id: voice_mail_recording.id,
          new_voice_recording_id: voice_recording.id,
          new_voice_recording_url: voice_recording.url,
          new_voice_recording_recording_name: voice_recording.recording_name
        }

        Triggeraction.where(action_type: 150).where('data @> ?', {rvm_id: voice_mail_recording.id}.to_json).find_each do |triggeraction|
          triggeraction.update(voice_recording_id: voice_recording.id)
        end

        Twmessage.where(voice_mail_recording_id: voice_mail_recording.id).update_all(voice_recording_id: voice_recording.id)
      end
    end

    say_with_time 'Migrating DelayedJobs referencing VoiceRecordings...' do
      DelayedJob.where(process: 'send_rvm').find_each do |job|
        handler = YAML.load(job.handler)
        data    = job.data
        voice_recording_hash = voice_recordings_array.find { |x| x[:old_voice_recording_id] == handler.args[0].dig(:voice_mail_recording_id).to_i }

        if voice_recording_hash.present?
          handler.args[0][:voice_recording_id]  = voice_recording_hash[:new_voice_recording_id]
          handler.args[0][:voice_recording_url] = voice_recording_hash[:new_voice_recording_url]
          handler.args[0][:message]             = voice_recording_hash[:new_voice_recording_recording_name]

          data[:voice_recording_id]  = voice_recording_hash[:new_voice_recording_id]
          data[:voice_recording_url] = voice_recording_hash[:new_voice_recording_url]
          data[:message]             = voice_recording_hash[:new_voice_recording_recording_name]
        else
          handler.args[0][:voice_recording_id]  = 0
          handler.args[0][:voice_recording_url] = ''
          handler.args[0][:message]             = ''

          data[:voice_recording_id]  = 0
          data[:voice_recording_url] = ''
          data[:message]             = ''
        end

        job.update(handler: handler.to_yaml, data: data)
      end
    end

    say_with_time 'Migrating Clients (rvm_count => max_voice_recordings)...' do
      Client.find_each do |client|

        if client.data.include?('rvm_count')
          client.max_voice_recordings = client.data['rvm_count'].to_i
          client.data.delete('rvm_count')
          client.save
        end
      end
    end

    say_with_time 'Migrating Packages (rvm_count => max_voice_recordings)...' do
      Package.find_each do |package|

        if package.package_data.include?('rvm_count')
          package.max_voice_recordings = package.package_data['rvm_count'].to_i
          package.package_data.delete('rvm_count')
          package.save
        end
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Dropping VoiceRecordings...' do
      drop_table :voice_recordings
    end

    say_with_time 'Removing \'voice_recording_id\' from Twmessages...' do
      remove_column :twmessages, :voice_recording_id
    end

    say_with_time 'Removing fields from Twnumbers...' do
      remove_column :twnumbers, :voice_recording_id
      remove_column :twnumbers, :data
    end

    say_with_time 'Rolling VoiceMailRecordings back...' do
      Client.find_each do |client|

        if client.data.include?('max_voice_recordings')
          client.data['rvm_count'] = client.data['max_voice_recordings'].to_i
          client.data.delete('max_voice_recordings')
          client.save
        end
      end

      Package.find_each do |package|

        if package.package_data.include?('max_voice_recordings')
          package.package_data['rvm_count'] = package.package_data['max_voice_recordings'].to_i
          package.package_data.delete('max_voice_recordings')
          package.save
        end
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
