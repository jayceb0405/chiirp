# frozen_string_literal: true

module Integrations
  module Sendgrid
    module Images
      def attach_images(message_email, images)
        images.each do |attachment, file|
          begin
            if file.dig('filename').to_s.present? && params[attachment].tempfile.to_path.to_s.present?
              blob = ActiveStorage::Blob.create_and_upload!(
                io:           File.open(params[attachment].tempfile.to_path.to_s),
                filename:     file.dig('filename').to_s,
                content_type: file.dig('type').to_s
              )

              if message_email.images.attach(blob)
                message_email.html_body = message_email.html_body.gsub("cid:#{file.dig('content-id')}", message_email.images.find_by(blob_id: blob.id).url)
                message_email.save
              end
            end
          rescue StandardError => e
            e.set_backtrace(BC.new.clean(caller))

            Appsignal.report_error(e) do |transaction|
              # Only needed if it needs to be different or there's no active transaction from which to inherit it
              Appsignal.set_action('Integrations::Sendgrid::Images#attach_images')

              # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
              Appsignal.add_params(params)

              Appsignal.set_tags(
                error_level: 'error',
                error_code:  0
              )
              Appsignal.add_custom_data(
                attachment:,
                image_file:    file,
                images:,
                message_email:,
                temp_file:     params[attachment].tempfile.to_path,
                file:          __FILE__,
                line:          __LINE__
              )
            end
          end
        end
      end
    end
  end
end
