# frozen_string_literal: true

# lib/core_ext/nil_class.rb
class NilClass
  def normalize_non_ascii(replacement = '')
    self
  end
end
