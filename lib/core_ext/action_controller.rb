# frozen_string_literal: true

# lib/core_ext/action_controller.rb
class ActionController::Parameters
  def normalize_non_ascii(replacement = '')
    self.to_unsafe_hash.normalize_non_ascii
  end
end
