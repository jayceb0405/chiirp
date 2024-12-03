# frozen_string_literal: true

# /lib/boolean.rb
#
# Example:
# 	xxx.is_a?(Boolean)
#
module Boolean; end
class TrueClass; include Boolean; end
class FalseClass; include Boolean; end
