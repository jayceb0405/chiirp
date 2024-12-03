# frozen_string_literal: true

# app/models/concerns/email_validator.rb
require 'mail'

class EmailValidator < ActiveModel::EachValidator
  def add_error(record, attribute)
    record.errors.add(attribute, (options[:message] || 'is not a valid email address'))
  end

  def validate_each(record, attribute, value)
    begin
      a = Mail::Address.new(value)
    rescue Mail::Field::ParseError
      add_error(record, attribute)
    end

    # regexp from http://guides.rubyonrails.org/active_record_validations.html
    value = a.address unless a.nil?
    add_error(record, attribute) unless %r{\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z}i.match?(value)
  end
end
