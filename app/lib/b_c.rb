# frozen_string_literal: true

# app/lib/b_c.rb
class BC
  def initialize
    @bc = ActiveSupport::BacktraceCleaner.new
    @bc.add_filter { |line| line.gsub(Rails.root.to_s, '') } # strip the Rails.root prefix
    @bc.add_silencer { |line| %r{puma|rubygems}.match?(line) } # skip any lines from puma or rubygems
  end

  def clean(backtrace)
    @bc.clean(backtrace)
  end
end
