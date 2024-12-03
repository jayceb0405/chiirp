# frozen_string_literal: true

# app/presenters/welcome_presenter.rb
class WelcomePresenter
  attr_reader :client, :contact, :package, :package_page, :package_position, :upgrade

  def initialize(args = {})
    self.package_page = args.dig(:package_page)
    @upgrade          = args.dig(:upgrade).to_bool
  end

  def card_body_class
    response = %w[card-body p-4]

    case self.package_page_package_count
    when 1, 2, 3
      response << 'p-lg-5'
    end

    response.join(' ')
  end

  def card_class
    response = %w[card font-size-lg]

    case self.package_page_package_count
    when 2
      response += self.package_position == 1 ? ['shadow-lg'] : %w[card-inverse bg-primary shadow]
    when 3

      case self.package_position
      when 1, 3
        response << 'shadow-lg'
      when 2
        response += %w[card-inverse bg-primary shadow]
      end
    when 4

      case self.package_position
      when 1, 3
        response << 'shadow-lg'
      when 2, 4
        response += %w[card-inverse bg-primary shadow]
      end
    end

    response.join(' ')
  end

  def card_header_class
    response = %w[card-header text-center px-lg-5 p-4]

    case self.package_page_package_count
    when 1
      response << 'text-success'
    when 2
      response << 'text-success' if self.package_position == 1
    when 3, 4

      case self.package_position
      when 1, 3
        response << 'text-success'
      end
    end

    response.join(' ')
  end

  def card_sub_heading_class
    response = %w[text-center mb-4]

    case self.package_page_package_count
    when 1
      response << 'text-danger'
    when 2

      case self.package_position
      when 1
        response << 'text-danger'
      when 2
        response << 'text-white'
      end
    when 3

      case self.package_position
      when 1, 3
        response << 'text-danger'
      when 2
        response << 'text-white'
      end
    when 4

      case self.package_position
      when 1, 3
        response << 'text-danger'
      when 2, 4
        response << 'text-white'
      end
    end

    response.join(' ')
  end

  def client=(client)
    @client = case client
              when Client
                client
              when Integer
                self.client&.id == client ? self.client : Client.find_by(id: client)
              else
                Client.new
              end
  end

  def contact=(contact)
    @contact = case contact
               when Contact
                 contact
               when Integer
                 self.contact&.id == contact ? self.contact : Contact.find_by(id: contact)
               else
                 Contact.new
               end
  end

  def container_class
    response = %w[col-12 py-md-4]

    case self.package_page_package_count
    when 1
      response += %w[col-md-6 offset-md-3 pr-md-0]
    when 2
      response << 'col-md-5'
      response += self.package_position == 1 ? %w[offset-md-1 pr-md-0] : ['pl-md-0']
    when 3
      response << 'col-md-3'

      case self.package_position
      when 1
        response += %w[offset-md-1 pr-md-0]
      when 2
        response += %w[pl-md-0 pr-md-0]
      when 3
        response += ['pl-md-0']
      end
    when 4
      response << 'col-md-3'

      case self.package_position
      when 1
        response += ['pr-md-0']
      when 2, 3
        response += %w[pl-md-0 pr-md-0]
      when 4
        response += ['pl-md-0']
      end
    end

    response.join(' ')
  end

  def data_aos_delay
    self.package_position.even? ? 'data-aos-delay="200"' : ''
  end

  def link_method
    self.upgrade ? :post : :get
  end

  def link_path
    self.upgrade ? Rails.application.routes.url_helpers.client_upgrade_account_path(self.client, pk: self.package.package_key, pp: self.package_page.page_key) : Rails.application.routes.url_helpers.welcome_join_path(self.package.package_key, pp: self.package_page.page_key, contact_id: self.contact.id.to_s)
  end

  def package=(package)
    @package = case package
               when Package
                 package
               when Integer
                 self.package&.id == package ? self.package : Package.find_by(id: package)
               else
                 Package.new
               end
  end

  def package_monthly_charge
    if self.package.promo_months.positive?
      self.package.promo_mo_charge.to_i.to_d == self.package.promo_mo_charge.to_d ? self.package.promo_mo_charge.to_i : self.package.promo_mo_charge.to_d
    else
      self.package.mo_charge.to_i.to_d == self.package.mo_charge.to_d ? self.package.mo_charge.to_i : self.package.mo_charge.to_d
    end
  end

  def package_monthly_charge_after_promo
    if self.package.promo_months.positive?
      "$#{self.package.mo_charge.to_i.to_d == self.package.mo_charge.to_d ? self.package.mo_charge.to_i : self.package.mo_charge.to_d}/mo After Promo"
    else
      ''
    end
  end

  def package_page=(package_page)
    @package_page = case package_page
                    when PackagePage
                      package_page
                    when Integer
                      PackagePage.find_by(id: package_page)
                    else
                      PackagePage.new
                    end
  end

  def package_page_package_count
    (@package_page.package_01_id.positive? ? 1 : 0) +
      (@package_page.package_02_id.positive? ? 1 : 0) +
      (@package_page.package_03_id.positive? ? 1 : 0) +
      (@package_page.package_04_id.positive? ? 1 : 0)
  end

  def package_position=(package_position)
    @package_position = package_position.to_i
  end

  def package_sub_heading
    if self.upgrade && self.client.package_id == self.package.id
      'YOUR PACKAGE'
    elsif self.package_page.primary_package == self.package_position
      'MOST POPULAR'
    elsif (self.package.promo_mo_charge.to_d + self.package.mo_charge.to_d + self.package.setup_fee.to_d).zero?
      'NO CREDIT CARD'
    elsif (self.package.first_payment_delay_days + self.package.first_payment_delay_months).positive?
      "#{self.package.first_payment_delay_days + (self.package.first_payment_delay_months * 30)} DAY TRIAL"
    elsif self.package.promo_months.positive?
      "#{self.package.promo_months} MONTH PROMO"
    else
      '&nbsp;'
    end
  end
end
