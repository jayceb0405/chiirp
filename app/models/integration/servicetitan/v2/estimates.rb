# frozen_string_literal: true

# app/models/Integration/servicetitan/v2/estimates.rb
module Integration
  module Servicetitan
    module V2
      module Estimates
        # expire all open Contacts::Estimates if any Contacts::Estimate is "sold"
        # st_model.expire_open_contact_estimates()
        #   (req) contact_job_id: (Integer)
        def expire_open_contact_estimates(contact_job_id)
          return if contact_job_id.blank?

          contact_estimate_statuses = Contacts::Estimate.where(job_id: contact_job_id).pluck(:status).uniq

          return unless contact_estimate_statuses.include?('sold') && contact_estimate_statuses.include?('open')

          Contacts::Estimate.where(job_id: contact_job_id, status: 'open').update(status: 'expired')
        end

        # count the number of estimates remaining to be imported in DelayedJob
        # st_model.import_estimates_remaining_count()
        #   (req) user_id: (Integer)
        def import_estimates_remaining_count(user_id)
          [0, (DelayedJob.where(user_id:, process: 'servicetitan_estimate_import_by_client_block').count * 50)].max if user_id.to_i.positive?
        end

        # update job_imports_remaining_count element showing remaining ServiceTitan customers to import
        # st_model.import_estimates_remaining_update()
        #   (req) user_id: (Integer)
        def import_estimates_remaining_update(user_id)
          current_logger_level = Rails.logger.level
          Rails.logger.level = :error

          if user_id.to_i.positive? && (user = User.find_by(id: user_id))
            estimates_count = self.import_estimates_remaining_count(user_id)

            if estimates_count <= 1
              UserCable.new.broadcast(user.client, user, { append: 'false', id: 'estimate_imports_remaining_count', html: 'Imports are complete' })
              UserCable.new.broadcast(user.client, user, { enable: 'true', id: 'import_estimates_button' })
            else
              UserCable.new.broadcast(user.client, user, { append: 'false', id: 'estimate_imports_remaining_count', html: "~#{estimates_count} Estimates remaining to be imported" })
            end
          end

          Rails.logger.level = current_logger_level
        end
      end
    end
  end
end
