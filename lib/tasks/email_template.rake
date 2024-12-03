# frozen_string_literal: true

namespace :email_template do
  task import: :environment do
    css = Dir.glob('email_templates/**/*.css')
    html = Dir.glob('email_templates/**/*.html')
    templates = Hash.new { |hash, key| hash[key] = {} }
    (css + html).each do |file|
      id = File.basename(file).split('_').first.to_i
      name = File.basename(file).split('_')[1..].join(' ').split('.').first.strip
      html = File.basename(file).include?('.html') ? File.read(file) : nil
      css = File.basename(file).include?('.css') ? File.read(file) : nil
      if templates.include?(id)
        templates[id][:css] = css if css
        templates[id][:html] = html if html
      else
        templates[id] = {
          id:,
          name:,
          css:,
          html:
        }
      end
    end
    templates.each do |id, data|
      # puts "Template id: #{id}" unless data[:html]
      puts "Importing template ##{id} - #{data[:name]}"
      EmailTemplate.transaction do
        data[:name] = EmailTemplate.where(name: data[:name]).any? ? "#{data[:name]} #{id}" : data[:name]
        EmailTemplate.create!(
          client_id: nil,
          name:      data[:name],
          subject:   data[:name],
          content:   'not used',
          css:       data[:css],
          html:      data[:html]
        )
      end
    end
  end

  task remove_logo: :environment do
    EmailTemplate.where(client_id: nil).find_each do |email_template|
      doc = Nokogiri.HTML5(email_template.html)
      doc.css('.made_with').each do |elem|
        # find parent table with class es-content
        parent = elem.parent.parent.parent.parent.parent.parent.parent.parent.parent.parent.parent.parent.parent.parent.parent
        parent.remove
      end
      email_template.update html: doc.to_html
    end
  end

  # get all missing thumbnails
  task queue_thumbnails: :environment do
    EmailTemplate.global.with_attached_thumbnail.find_each(batch_size: 100) do |email_template|
      next if email_template.content.blank?
      next if email_template.thumbnail.attached?

      email_template.delay(
        run_at:              Time.current,
        priority:            DelayedJob.job_priority('email_render_thumbnail'),
        queue:               DelayedJob.job_queue('email_render_thumbnail'),
        user_id:             0,
        triggeraction_id:    0,
        contact_campaign_id: 0,
        group_process:       1,
        process:             'email_render_thumbnail',
        data:                { email_template_id: email_template.id }
      ).render_thumbnail
    end
  end
end
