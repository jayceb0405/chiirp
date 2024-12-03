# frozen_string_literal: true

# app/lib/random_code.rb
class RandomCode
  # create a random code of (len) length
  # RandomCode.new.create(len Integer)
  #   (opt) len:         (Integer)
  #   (opt) req_integer: (Boolean)
  def create(len = 6, req_integer: false)
    response = SecureRandom.alphanumeric(len)

    response = SecureRandom.alphanumeric(len) while (response !~ %r{\d}) && req_integer

    response
  end

  # generate a simple random salt of (len) length
  # RandomCode.new.salt(20)
  #   (opt) len: (Integer)
  def salt(len = 20)
    SecureRandom.alphanumeric(len)
  end

  # generate a string with a length of (len) characters that does not contain easily confused characters
  def easy_alphanumeric(len = 20)
    response = SecureRandom.alphanumeric(len * 3).downcase.delete('oil10').slice(0, len)
    response = SecureRandom.alphanumeric(len * 3).downcase.delete('oil10').slice(0, len) while response.length < len
    response
  end
end
