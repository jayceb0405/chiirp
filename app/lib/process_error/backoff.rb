# frozen_string_literal: true

# app/lib/process_error/backoff.rb
module ProcessError
  # calculate backoff (sleep) amount between retries
  # based on AWS Exponential Backoff And Jitter
  # https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
  module Backoff
    # rubocop:disable Style/ComparableClamp
    # calculate backoff
    def self.backoff(**args)
      [[args.dig(:cap).to_i, 5].max, [args.dig(:base).to_i, 1].max * (2**[args.dig(:retries).to_i, 1].max)].min
    end

    # calculate backoff using decorrelated jitter
    def self.decorr_jitter(**args)
      [[args.dig(:cap).to_i, 5].max, rand([args.dig(:base).to_i, 1].max..(self.equal_jitter(**args) * 3))].min
    end
    # rubocop:enable Style/ComparableClamp

    # calculate backoff using equal jitter
    def self.equal_jitter(**args)
      (self.backoff(**args) / 2) + rand(0..(self.backoff(**args) / 2))
    end

    ##### PREFERRED #####
    # calculate backoff using full jitter
    # ProcessError::Backoff.full_jitter(base: 1, cap: 5, retries: Integer)
    # ProcessError::Backoff.full_jitter(retries: retries)
    def self.full_jitter(**args)
      rand(0..self.backoff(**args))
    end
  end
end
