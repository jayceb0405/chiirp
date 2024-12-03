# frozen_string_literal: true

# app/models/email/address.rb
module Email
  class Address
    attr_accessor :name, :email

    def initialize(name, email)
      self.name = name
      self.email = email
    end

    def to_hash
      {
        email:,
        name:
      }
    end

    def to_s
      name.present? ? "\"#{name}\" <#{email}>" : "<#{email}>"
    end
  end
end
