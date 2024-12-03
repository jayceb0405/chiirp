# frozen_string_literal: true

# lib/core_ext/array.rb
class Array
  def normalize_non_ascii(replacement = '')
    self.map do |v|
      if v.is_a?(Array) || v.is_a?(Hash) || v.is_a?(String)
        v.normalize_non_ascii(replacement)
      else
        v
      end
    end
  end
end
