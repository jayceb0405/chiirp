# frozen_string_literal: true

# lib/core_ext/string.rb
class String
  NO_RESPONSES = ['absolutely not', 'definitely not', 'false', 'nah', 'negative', 'never', 'no', 'nona', 'no na', 'nope', 'no way', 'not interested', 'thumbsdn'].freeze

  YES_RESPONSES = ['alright', 'affirmative', 'absolutely', 'cool', 'definitely', 'fine', 'k', 'of course', 'ok', 'okhand', 'sure', 'thumbsup', 'true', 'y', 'ya', 'yah', 'yea', 'yeah', 'yep', 'yes', 'you bet', 'yup'].freeze

  # strip and validate phone number
  # String.clean_phone
  def clean_phone(area_code = '801')
    if self.nil? || self.to_s.empty?
      phone_number = ''
    else
      phone_number = self.to_s
      # phone_number = phone_number.split(%r{[,.;]})[0] # the split includes "." (period) / causes issues with phone numbers such as 802.555.5136
      phone_number = phone_number.split(%r{[,;]})[0] # split off only the first phone number if a comma separated list of numbers is received
      phone_number = phone_number.delete('^0-9') if phone_number.present?
      phone_number = "+#{phone_number}" if phone_number&.length == 11 && phone_number.strip[0, 1] == '1' # append string with + to define mutable String
      phone_number = Phoner::Phone.parse(phone_number, country_code: '1', area_code: area_code.presence || '801')
      phone_number = phone_number.nil? ? '' : phone_number.format('%a%n')
    end

    phone_number
  end

  def clean_smart_quotes
    content = self.to_s
    content = content.tr("\u201c", '"') # replace left double smart quotation marks
    content = content.tr("\u201d", '"') # replace right double smart quotation marks
    content = content.tr("\u0218", "'") # replace left single smart quotation marks
    content = content.tr("\u0219", "'") # replace right single smart quotation marks
    content.normalize_non_ascii
  end

  # rubocop:disable Naming/PredicateName
  def is_match?(match_array)
    self.match_in_array(match_array).present?
  end

  # break a string down and determne if it "means" no
  def is_no?
    test_string = " #{self.to_s.gsub(%r{\u{1F44E}}, ' thumbsdn ').gsub(%r{[^0-9a-z ]}i, '').downcase.strip} "
    NO_RESPONSES.map { |n| test_string.include?("#{n} ") || test_string.include?(" #{n} ") || test_string.include?(" #{n}") }.any?
  end

  # break a string down and determne if it "means" no
  def is_yes?
    test_string = " #{self.to_s.gsub(%r{\u{1F44D}}, ' thumbsup ').gsub(%r{\u{1F44C}}, ' okhand ').gsub(%r{[^0-9a-z ]}i, '').downcase.strip} "
    !self.is_no? && YES_RESPONSES.map { |y| test_string.include?("#{y} ") || test_string.include?(" #{y} ") || test_string.include?(" #{y}") }.any?
  end
  # rubocop:enable Naming/PredicateName

  def match_in_array(match_array)
    test_string_array = self.to_s.downcase.strip.gsub(%r{[^0-9a-z ]}i, '').split
    match_array_downcase = match_array.map { |ma| ma.downcase.gsub(%r{[^0-9a-z ]}i, '') }
    match_array[match_array_downcase.map { |ma| test_string_array.index(ma)&.zero? || test_string_array.index(ma)&.positive? }.index(true) || match_array.length] || ''
  end

  def parse_phone
    self[%r{\(?\d{3}\)?[\s|-]?\d{3}-?\d{4}}].to_s
  end

  # returns a possessive form of a string
  # String.possessive
  def possessive
    return self if self.empty?

    self + (self[-1, 1] == 's' ? "'" : "'s")
  end

  # remove HTML tags from String
  # String.remove_tags
  def remove_tags
    Loofah.fragment(ActionController::Base.helpers.strip_tags(Loofah.fragment(ActionController::Base.helpers.strip_tags(self)).text(encode_special_chars: false))).text(encode_special_chars: false)
  end

  def normalize_non_ascii(replacement = '')
    self.gsub(%r{[\u0000]}, replacement).encode('UTF-8', invalid: :replace, undef: :replace, replace: "\uFFFD")
  end

  def strip_phone
    self.parse_phone&.gsub(%r{\D+}, '')
  end

  def valid_url?
    uri = URI.parse(self)
    uri.is_a?(URI::HTTP) && !uri.host.nil?
  rescue URI::InvalidURIError
    false
  end
end
