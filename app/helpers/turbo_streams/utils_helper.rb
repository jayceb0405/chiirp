# frozen_string_literal: true

module TurboStreams
  module UtilsHelper
    def log(message)
      turbo_stream_action_tag :log, message:
    end

    def open_modal(id)
      turbo_stream_action_tag :openModal, id:
    end
  end
end
Turbo::Streams::TagBuilder.prepend(TurboStreams::UtilsHelper)
