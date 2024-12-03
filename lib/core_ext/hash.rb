# frozen_string_literal: true

# lib/core_ext/hash.rb
class Hash
  def normalize_non_ascii(replacement = '')
    self.each do |key, value|
      self[key] = if value.is_a?(Array) || value.is_a?(Hash) || value.is_a?(String)
                    value.normalize_non_ascii(replacement)
                  else
                    value
                  end
    end
  end
end
