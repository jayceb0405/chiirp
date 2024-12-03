# frozen_string_literal: true

# app/models/package_page.rb
class PackagePage < ApplicationRecord
  belongs_to :package_01, class_name: :Package, optional: true
  belongs_to :package_02, class_name: :Package, optional: true
  belongs_to :package_03, class_name: :Package, optional: true
  belongs_to :package_04, class_name: :Package, optional: true

  has_many :clients, dependent: :nullify

  validates :name, presence: true, length: { minimum: 3 }
  validates :tenant, presence: true

  after_initialize     :apply_new_record_data, if: :new_record?
  before_validation    :before_validation_method

  scope :persistent, -> { where(onetime: false) }
  scope :onetime, -> { where(onetime: true) }
  scope :expired, -> { where(expired_on: ...Date.current) }

  # copy PackagePage
  # @package_page.copy
  def copy
    new_package_page = self.dup
    new_package_page.name        = "Copy of #{new_package_page.name}" if PackagePage.find_by(name: new_package_page.name)
    new_package_page.sys_default = 0
    new_package_page.page_key    = ''
    new_package_page.set_page_key
    new_package_page.save

    new_package_page
  end

  # generate a random page_key
  # @package.get_package_key
  def set_page_key
    self.page_key = RandomCode.new.create(20) unless self.page_key.to_s.length == 20
    self.page_key = RandomCode.new.create(20) while PackagePage.find_by(page_key: self.page_key)
  end

  private

  def after_destroy_commit_actions
    super

    return unless self.sys_default == 1 && (package_page = PackagePage.find_by(tenant: self.tenant, sys_default: 0))

    package_page.update(sys_default: 1)
  end

  def apply_new_record_data
    self.tenant = self.tenant.to_s.present? ? self.tenant : I18n.locale.to_s

    self.set_page_key
  end

  def before_validation_method
    if self.sys_default == 1
      # this is the default PackagePage
      # rubocop:disable Rails/SkipsModelValidations
      PackagePage.where(tenant: self.tenant, sys_default: 1).where.not(id: self.id).update_all(sys_default: 0)
      # rubocop:enable Rails/SkipsModelValidations
    else
      # make this PackagePage default if no others

      self.sys_default = 1 unless PackagePage.find_by(tenant: self.tenant, sys_default: 1)
    end
  end
end
