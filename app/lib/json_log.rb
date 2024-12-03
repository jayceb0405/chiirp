# frozen_string_literal: true

class JsonLog
  @@logger = Rails.logger

  class << self
    def info(type, data = nil, client_id: nil, contact_id: nil, user_id: nil)
    end
    # JsonLog.info 'Integration::Servicetitan::V2::Tags.apply_servicetitan_tags', { contact: }, contact_id: contact&.id
    # JsonLog.info 'AiagentsController#show', { fullname: current_user&.fullname }, user_id: current_user&.id
    # JsonLog.info 'current_user', { fullname: current_user&.fullname }, user_id: current_user&.id
    # JsonLog.info 'current_user', nil, user_id: current_user&.id
    # JsonLog.info 'current_user', nil
    # def info(type, data = nil, client_id: nil, contact_id: nil, user_id: nil)
    #   callers = local_paths_in_callstack(caller_locations(1..10))

    #   @@logger.info do
    #     out = {
    #       type:,
    #       client_id:,
    #       user_id:,
    #       contact_id:,
    #       file:       callers.first || nil,
    #       file2:      callers.second || nil,
    #       file3:      callers.third || nil
    #     }.compact

    #     out = case data
    #           when Hash
    #             out.merge(data)
    #           when Array
    #             out.merge({ data: }).compact
    #           else
    #             out.merge({ message: data }).compact
    #           end

    #     out.to_json
    #   end
    # end
    alias error info

    private

    def local_paths_in_callstack(callstack)
      callstack
        .delete_if { |call| call.path.exclude?('app/') }
        .delete_if { |call| call.path.include?('vendor/bundle') }
        .map { |call| "#{call.path.gsub('/usr/src/app/app/', '')}:#{call.lineno}" }
    end
  end
end

# Benchmark.bm do |x|
#   x.report { 1_000_000.times { JsonLog.info 'asdf', { value: 1 }, contact_id: 257 } }
# end
