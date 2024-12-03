# frozen_string_literal: true

# initializers/delayed_jobs_plugins.rb
# require 'delayed_job'

class DelayedJobsPlugins < Delayed::Plugin
  # rubocop:disable Lint/RescueException

  callbacks do |lifecycle|
    lifecycle.after(:perform) do |_worker, job|
      if Rails.env.production? && %w[show_active_contacts show_message_thread_message update_unread_message_indicators].exclude?(job.process)
        Contacts::Campaigns::Triggeraction.completed(job.contact_campaign_id, job.triggeraction_id)

        klass = if job.payload_object.respond_to?(:object) && job.payload_object.object.respond_to?(:class) && job.payload_object.object.class.respond_to?(:name) && job.payload_object.object.class.name&.casecmp?('class')
                  job.payload_object.object
                elsif job.payload_object.respond_to?(:job_data) && job.payload_object.job_data.respond_to?(:dig) && job.payload_object.job_data.dig('job_class').present?
                  job.payload_object.job_data.dig('job_class')
                elsif job.payload_object.respond_to?(:object) && job.payload_object.object.respond_to?(:class) && job.payload_object.object.class.respond_to?(:name) && job.payload_object.object.class.name.present?
                  job.payload_object.object.class.name
                else
                  'Unknown Object Class'
                end
        method = if job.payload_object.respond_to?(:method_name)
                   job.payload_object.method_name
                 else
                   'Undefined'
                 end
        arguments = if job.payload_object.respond_to?(:args)
                      job.payload_object.args
                    elsif job.payload_object.respond_to?(:job_data) && job.payload_object.job_data.dig('arguments').present?
                      job.payload_object.job_data['arguments']
                    else
                      'Undefined'
                    end

        JsonLog.info 'DELAYED_JOB_COMPLETE', { process: job.process, klass:, method:, arguments:, payload_object: job.payload_object, payload_object_methods: job.payload_object.public_methods }
      end
    end

    lifecycle.around(:invoke_job) do |job, *args, &block|
      begin
        # Forward the call to the next callback in the callback chain
        block.call(job, *args)
      rescue Exception => e
        unless e.class.name == 'SignalException'
          e.set_backtrace(BC.new.clean(caller))

          Appsignal.report_error(e) do |transaction|
            # Only needed if it needs to be different or there's no active transaction from which to inherit it
            Appsignal.set_action('DelayedJobsPlugins#invoke_job')

            # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
            Appsignal.add_params({ job:, args:, block: })

            Appsignal.set_tags(
              error_level: 'error',
              error_code:  0
            )
            Appsignal.add_custom_data(
              file: __FILE__,
              line: __LINE__
            )
          end
        end

        # Make sure we propagate the failure!
        raise e
      end
    end
  end

  # rubocop:enable Lint/RescueException
end
