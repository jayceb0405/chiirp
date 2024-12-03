# frozen_string_literal: true

# app/lib/sweetify/sweet_alert.rb
module Sweetify
  # Display an alert with a text and an optional title
  # Default without an specific type
  #
  # Example:
  #   sweetalert("Title", "Content", "HTML", opts = {persistent: "Ok", now: false})
  #
  # @param [String] text Body of the alert (gets automatically the title if no title is specified)
  # @param [String] title Title of the alert
  # @param [Hash] opts Optional Parameters
  module SweetAlert
    # rubocop:disable Metrics/ParameterLists
    def sweetalert(title = 'OOPS...', text = '', html = '', opts = {})
      opts = {
        showConfirmButton: false,
        timer:             2000,
        allowOutsideClick: true,
        confirmButtonText: 'OK',
        now:               false,
        ajax:              false
      }.merge(opts)

      if html.blank?
        opts[:text] = text
      else
        opts[:html] = html
      end

      opts[:title] = title

      if opts[:button]
        opts[:showConfirmButton] = true
        opts[:confirmButtonText] = opts[:button] if opts[:button].is_a?(String)

        opts.delete(:button)
      end

      if opts[:persistent]
        opts[:showConfirmButton] = true
        # opts[:allowOutsideClick] = false
        opts[:timer]             = nil
        opts[:confirmButtonText] = opts[:persistent] if opts[:persistent].is_a?(String)

        opts.delete(:persistent)
      end

      flash_config(opts)
    end

    # Information Alert
    #
    # Example:
    #   sweetalert_info("Title", "Content", "HTML", opts = {persistent: "Ok", now: false})
    #
    # @param [String] text Body of the alert (gets automatically the title if no title is specified)
    # @param [String] title Title of the alert
    # @param [Hash] opts Optional Parameters
    def sweetalert_info(title = 'OOPS...', text = '', html = '', opts = {})
      opts[:icon] = :info
      sweetalert(title, text, html, opts)
    end

    # Success Alert
    #
    # Example:
    #   sweetalert_success("Title", "Content", "HTML", opts = {persistent: "Ok", now: false})
    #
    # @param [String] text Body of the alert (gets automatically the title if no title is specified)
    # @param [String] title Title of the alert
    # @param [Hash] opts Optional Parameters
    def sweetalert_success(title = 'OOPS...', text = '', html = '', opts = {})
      opts[:icon] = :success
      sweetalert(title, text, html, opts)
    end

    # Error Alert
    #
    # Example:
    #   sweetalert_error("Title", "Content", "HTML", opts = {persistent: "Ok", now: false})
    #
    # @param [String] text Body of the alert (gets automatically the title if no title is specified)
    # @param [String] title Title of the alert
    # @param [Hash] opts Optional Parameters
    def sweetalert_error(title = 'OOPS...', text = '', html = '', opts = {})
      opts[:icon] = :error
      sweetalert(title, text, html, opts)
    end

    # Warning Alert
    #
    # Example:
    #   sweetalert_warning("Title", "Content", "HTML", opts = {persistent: "Ok", now: false})
    #
    # @param [String] text Body of the alert (gets automatically the title if no title is specified)
    # @param [String] title Title of the alert
    # @param [Hash] opts Optional Parameters
    def sweetalert_warning(title = 'OOPS...', text = '', html = '', opts = {})
      opts[:icon] = :warning
      sweetalert(title, text, html, opts)
    end

    # rubocop:enable Metrics/ParameterLists

    # Flash the configuration as json
    # If no title is specified, use the text as the title
    #
    # @param [Hash] opts
    # @return [Void]
    def flash_config(opts)
      if opts[:title].blank?

        if opts[:html].blank?
          opts[:title] = opts[:text]
          opts.delete(:text)
        else
          opts[:title] = opts[:html]
          opts.delete(:html)
        end
      end

      # opts.delete(:now)

      if opts[:ajax]
        cookies[:sweetify] = opts.to_json
      elsif opts[:now]
        flash.now[:sweetify] = opts.to_json
      else
        flash[:sweetify] = opts.to_json
      end
    end
  end
end

# ActiveSupport.on_load(:action_controller) { include Sweetify::SweetAlert }
