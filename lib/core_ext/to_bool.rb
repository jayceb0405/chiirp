# frozen_string_literal: true

# lib/core_ext/to_bool.rb
class String
  # Returns a Boolean from a String

  # strip and convert String
  # String.to_bool
  def to_bool
    %w[1 true].include?(self.to_s.strip.downcase)
  end
end

class NilClass
  # Returns a Boolean from a NilClass

  # strip and convert String
  # String.to_bool
  def to_bool
    self.to_s.to_bool
  end
end

class Integer
  # Returns a Boolean from a Integer

  # strip and convert String
  # String.to_bool
  def to_bool
    self.positive?
  end
end

class TrueClass
  # Returns a Boolean from a Boolean

  # strip and convert String
  # String.to_bool
  def to_bool
    self
  end
end

class FalseClass
  # Returns a Boolean from a Boolean

  # strip and convert String
  # String.to_bool
  def to_bool
    self
  end
end
