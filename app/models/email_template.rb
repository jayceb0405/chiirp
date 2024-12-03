# frozen_string_literal: true

# app/models/email_template.rb
class EmailTemplate < ApplicationRecord
  class EmailTemplateNotRenderedError < StandardError; end

  has_one_attached :thumbnail

  belongs_to :client, optional: true

  validates :name, :subject, :version, presence: true
  # rubocop:disable Rails/I18nLocaleTexts
  validates :name, uniqueness: { scope: :client, case_sensitive: false, message: 'must be unique.' }, unless: -> { client_id.nil? }
  # rubocop:enable Rails/I18nLocaleTexts
  validates :share_code, uniqueness: true
  validate :count_is_approved, on: [:create]

  before_validation    :ensure_share_code
  before_validation    :ensure_version
  before_validation    :nullify_category

  after_destroy        :unlink_triggeraction
  after_commit         :enqueue_render_content, on: %i[create update], if: :v2?
  after_commit         :enqueue_render_thumbnail, on: %i[create update], if: :v2?

  scope :categories, -> {
    select(:category)
      .group(:category)
      .where.not(category: nil)
  }
  scope :global, -> { where(client_id: nil) }

  def copy(new_client_id:, campaign_id_prefix: nil)
    return if self.global?

    new_email_template = self.dup
    new_email_template.client_id = new_client_id
    new_email_template.name = new_name
    new_email_template.share_code = nil

    new_email_template.content = copy_trackable_links(new_client_id:, campaign_id_prefix:)

    new_email_template.save ? new_email_template : nil
  end

  def global?
    self.client_id.nil?
  end

  def yield?
    content&.include?("\#{custom_email_section}")
  end
  alias yieldable? yield?

  def render_content
    so_client = Integrations::StripO::Base.new
    res = so_client.compiled_html(html:, css:)

    if so_client.success?
      self.update content: res
    else
      error = EmailTemplateNotRenderedError.new("Can not render content: #{so_client.message}")
      error.set_backtrace(BC.new.clean(caller))

      Appsignal.report_error(error) do |transaction|
        # Only needed if it needs to be different or there's no active transaction from which to inherit it
        Appsignal.set_action('EmailTemplate.render_content')

        Appsignal.set_tags(
          error_level: 'error',
          error_code:  0
        )
        Appsignal.add_custom_data(
          email_template_id: self.id,
          file:              __FILE__,
          line:              __LINE__
        )
      end
    end
  end

  def render_thumbnail
    return if self.content.blank?

    # TODO: fix this
    return if Rails.env.test?

    # set options for chrome
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    options.add_argument('--remote-debugging-port=9222')
    options.add_argument('--window-size=1280,1024')
    options.add_argument('--disable-gpu')

    # start chrome using Selenium::WebDriver
    driver = Selenium::WebDriver.for(:chrome, options:)

    # tell chrome to load the html from the db
    driver.get("data:text/html;base64,#{Base64.encode64(self.content)}")

    # get a screenshot
    screenshot = driver.screenshot_as(:png)

    # quit driver
    driver.quit

    # crop and resize screenshot
    image = MiniMagick::Image.read(screenshot)
    image.combine_options do |m|
      m.gravity(:north_west)
      m.crop('650x650+306+0')
      m.resize('200x200')
    end

    # save the screenshot to the db and activestorage
    self.thumbnail.attach(io: StringIO.open(image.to_blob), filename: "#{self.id}.png")
  end

  def v2?
    self.version == 2
  end

  private

  def enqueue_render_content
    return unless self.v2?
    return unless self.html_previously_changed? || self.css_previously_changed?

    self.delay(
      run_at:              Time.current,
      priority:            DelayedJob.job_priority('email_render_content'),
      queue:               DelayedJob.job_queue('email_render_content'),
      user_id:             0,
      triggeraction_id:    0,
      contact_campaign_id: 0,
      group_process:       1,
      process:             'email_render_content',
      data:                { email_template_id: self.id }
    ).render_content
  end

  def enqueue_render_thumbnail
    return unless self.v2?
    return unless self.content_previously_changed?
    return unless self.client_id.nil?

    self.delay(
      run_at:              Time.current,
      priority:            DelayedJob.job_priority('email_render_thumbnail'),
      queue:               DelayedJob.job_queue('email_render_thumbnail'),
      user_id:             0,
      triggeraction_id:    0,
      contact_campaign_id: 0,
      group_process:       1,
      process:             'email_render_thumbnail',
      data:                { email_template_id: self.id }
    ).render_thumbnail
  end

  def ensure_share_code
    self.share_code = self.new_share_code if self.share_code.blank?
  end

  def ensure_version
    self.version = 2 if self.version.blank?
  end

  def count_is_approved
    return if self.client.nil? || self.client.max_email_templates.to_i == -1 || self.client.email_templates.count < self.client.max_email_templates.to_i

    errors.add(:base, "Maximum Email Templates for #{self.client.name} has been met.")
  end

  def copy_trackable_links(new_client_id:, campaign_id_prefix:)
    new_content = self.content.clone

    # copy any EmailTemplates if copying to a different Client
    return new_content unless self.client_id != new_client_id
    return new_content unless content.length.positive?

    self.client.trackable_links.each do |trackable_link|
      hashtag = "\#{trackable_link_#{trackable_link.id}}" # '#{trackable_link_1234}'

      if new_content.include?(hashtag) && (new_trackable_link = trackable_link.copy(new_client: new_client_id, campaign_id_prefix:))
        new_content = new_content.gsub(hashtag, "\#{trackable_link_#{new_trackable_link.id}}")
      end
    end

    new_content
  end

  def new_name
    "#{name} - #{EmailTemplate.order(:id).last.id + 1}"
  end

  def new_share_code
    share_code = RandomCode.new.create(20)
    share_code = RandomCode.new.create(20) while EmailTemplate.find_by(share_code:)

    share_code
  end

  def nullify_category
    self.category = nil if self.category.blank?
  end

  def unlink_triggeraction
    Triggeraction.where(action_type: 170).where("#{Triggeraction.table_name}.data @> ?", { email_template_id: id }.to_json).find_each do |triggeraction|
      triggeraction.update! email_template_id: nil
    end
  end
end
