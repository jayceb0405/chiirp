class CreateContactPhones < ActiveRecord::Migration[5.2]
  def up
    create_table   :contact_phones do |t|
			t.references :contact,           foreign_key: {on_delete: :cascade}
      t.string     :phone,             default: "",        null: false,        index: true
      t.string     :label,             default: "",        null: false
      t.boolean    :primary,           default: false,     null: false

      t.timestamps
    end

    ActiveRecord::Base.record_timestamps = false
    say "Turned off timestamps."

    say_with_time "Converting Contact's phone numbers..." do
      counter     = 0
      contact_ids = []

      Contact.joins(:client).where( "clients.data @> ?", {active: true}.to_json ).find_each do |contact|
        counter += 1
        contact_ids << contact.id

        if ( counter % 100 ) == 0
          Contact.delay( priority: 0, process: "convert_phone_to_phones" ).convert_phone_to_phones( contact_ids )
          contact_ids = []
        end
      end

      Contact.delay( priority: 0, process: "convert_phone_to_phones" ).convert_phone_to_phones( contact_ids ) if contact_ids.length > 0
    end

    # to be processed after migration
    # Contact.joins(:client).where( "clients.data @> ?", {active: false}.to_json ).each do |contact|
    #   contact.contact_phones.create( phone: contact.phone, label: "mobile", primary: true, created_at: Time.current, updated_at: Time.current )
    #   contact.contact_phones.create( phone: contact.alt_phone, label: "other", primary: false, created_at: Time.current, updated_at: Time.current ) if contact.alt_phone && !contact.alt_phone.to_s.strip.empty?
    # end

    say_with_time "Converting Triggeraction's send_to..." do
      Triggeraction.where( action_type: [100, 750] ).each do |triggeraction|

        if triggeraction.data && triggeraction.data.include?(:send_to) && triggeraction.data[:send_to] == "contact"
          triggeraction.data[:send_to] = "contact_mobile"
          triggeraction.save
        end
      end
    end

    say_with_time "Converting Triggeraction's to_phone..." do
      Triggeraction.where( action_type: [550, 551] ).each do |triggeraction|

        if triggeraction.data && triggeraction.data.include?(:to_phone) && triggeraction.data[:to_phone].is_a?(Array) && triggeraction.data[:to_phone].include?("contact")
          triggeraction.data[:to_phone] << "contact_mobile"
          triggeraction.data[:to_phone].delete("contact")
          triggeraction.save
        end
      end
    end

    say_with_time "Converting Triggeraction's text_message hash tag replacements..." do
      Triggeraction.where( "data LIKE ?", '%#{phone}%').each do |triggeraction|

        if triggeraction.data.include?(:text_message) && triggeraction.data[:text_message].include?('#{phone}')
          triggeraction.data[:text_message] = triggeraction.data[:text_message].gsub('#{phone}', '#{phone_mobile}')
          triggeraction.save
        end
      end
    end

    say_with_time "Converting DelayedJobs..." do
      DelayedJob.where( process: "send_text" ).each do |delayed_job|

        begin
          handler = YAML.load(delayed_job.handler)

          if handler.args.length > 0 && handler.args[0].include?(:content) && handler.args[0][:content].include?('#{phone}')
            handler.args[0][:content] = handler.args[0][:content].gsub('#{phone}', '#{phone-mobile}')

            data = delayed_job.data

            if data && data.include?("content")
              data["content"] = data["content"].gsub('#{phone}', '#{phone-mobile}')
            end

            delayed_job.update( handler: handler.to_yaml, data: data )
          end
        rescue ArgumentError => e

          if e.message[0,23] == "undefined class/module "
            say "Model: #{e.message.split(" ")[2]} constantized!"
            e.message.split(" ")[2].constantize rescue handler = nil
            handler = YAML.load(delayed_job.handler) rescue handler = nil
          end
        end
      end
    end

    say_with_time "Converting UserContactForm's phone & alt_phone fields..." do
      UserContactForm.where("formatting @> ?", {version: 3}.to_json).each do |user_contact_form|
        user_contact_form.form_fields["phone_mobile"] = user_contact_form.form_fields["phone"]
        user_contact_form.form_fields.delete("phone")

        user_contact_form.form_fields["phone_other"] = user_contact_form.form_fields["alt_phone"]
        user_contact_form.form_fields.delete("alt_phone")
        user_contact_form.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say "Turned on timestamps."
  end

  def down
  	drop_table     :contact_phones

    ActiveRecord::Base.record_timestamps = false

    Triggeraction.where( action_type: [100, 750] ).each do |triggeraction|

      if triggeraction.data && triggeraction.data.include?(:send_to) && triggeraction.data[:send_to].include?("contact")
        triggeraction.data[:send_to] = "contact"
        triggeraction.save
      end
    end

    Triggeraction.where( action_type: [550, 551] ).each do |triggeraction|

      if triggeraction.data && triggeraction.data.include?(:to_phone) && triggeraction.data[:to_phone].is_a?(Array)
        add_contact = false

        triggeraction.data[:to_phone].each do |to_phone|

          if to_phone.include?("contact_")
            add_contact = true
            triggeraction.data.delete(to_phone)
          end
        end

        triggeraction.data[:to_phone] << "contact" if add_contact
        triggeraction.save
      end
    end

    UserContactForm.where("formatting @> ?", {version: 3}.to_json).each do |user_contact_form|
      user_contact_form.form_fields["phone"] = user_contact_form.form_fields["phone_mobile"]
      user_contact_form.form_fields.delete("phone_mobile")

      user_contact_form.form_fields["alt_phone"] = user_contact_form.form_fields["phone_other"]
      user_contact_form.form_fields.delete("phone_other")
      user_contact_form.save
    end

    ActiveRecord::Base.record_timestamps = true
  end
end
