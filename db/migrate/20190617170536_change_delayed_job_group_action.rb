class ChangeDelayedJobGroupAction < ActiveRecord::Migration[5.2]
  require "yaml"

  def up
  	add_column    :delayed_jobs, :group_process, :integer, null: false,   default: 0
  	add_column    :delayed_jobs, :data,          :jsonb,   null: false,   default: {}

    DelayedJob.where.not(group_action: [nil, ""]).update_all(group_process: 1)

    DelayedJob.all.each do |delayed_job|

      begin
        handler = YAML.load(delayed_job.handler)
      rescue ArgumentError => e

        if e.message[0,23] == "undefined class/module "
          say "Model: #{e.message.split(" ")[2]} constantized!"
          e.message.split(" ")[2].constantize rescue handler = nil
          handler = YAML.load(delayed_job.handler) rescue handler = nil
        end
      end

      if handler
        delayed_job.process = handler.method_name.to_s

        if delayed_job.process == "send_text"

          if handler.args[0].include?(:content) && handler.args[0].include?(:image_id_array)
            delayed_job.data = { content: handler.args[0][:content], image_id_array: handler.args[0][:image_id_array] }
            delayed_job.save
          elsif handler.args[0].include?(:message_text)
            contact = Contact.find_by_id(delayed_job.contact_id)

            contact.delay(
              run_at: delayed_job.run_at,
              priority: delayed_job.priority,
              contact_id: delayed_job.contact_id,
              triggeraction_id: delayed_job.triggeraction_id,
              contact_campaign_id: delayed_job.contact_campaign_id,
              data: { content: handler.args[0][:message_text], image_id_array: ( handler.args[0].include?(:image_id_array) ? handler.args[0][:image_id_array] : [] ) },
              process: "send_text"
            ).send_text(
              content: handler.args[0][:message_text],
              image_id_array: ( handler.args[0].include?(:image_id_array) ? handler.args[0][:image_id_array] : [] ),
              from_phone: ( handler.args[0].include?(:from_phone) ? handler.args[0][:from_phone] : "" ),
              triggeraction_id: ( handler.args[0].include?(:triggeraction_id) ? handler.args[0][:triggeraction_id] : 0 )
            )

            delayed_job.destroy
          else
            delayed_job.save
          end
        elsif delayed_job.process == "send_rvm"

          if handler.args[0].include?(:message) && handler.args[0].include?(:rvm_url)
            delayed_job.data = { content: handler.args[0][:message], rvm_url: handler.args[0][:rvm_url] }
            delayed_job.save
          end
        end
      end
    end

  	remove_column :delayed_jobs, :group_action
  end

  def down
  	add_column 		:delayed_jobs, :group_action,  :string,  null: false,   default: ""
  	remove_column :delayed_jobs, :group_process
  	remove_column :delayed_jobs, :data
  end
end
