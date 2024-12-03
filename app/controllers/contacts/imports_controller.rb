# frozen_string_literal: true

# app/controllers/contacts/imports_controller.rb
module Contacts
  class ImportsController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_user!

    # (GET) show Contacts import screen
    # /contacts/import
    # contacts_import_path
    # contacts_import_url
    def show
      render 'contacts/import/show'
    end

    # (PUT/PATCH) receive CSV/XLSX file to import
    # /contacts/import
    # contacts_import_path
    # contacts_import_url
    def update
      response = self.parse_file_response_initialize
      sanitized_params = params.permit(:commit, header: [])

      if params.dig(:import_file).present?
        Rails.logger.info "Contacts::ImportsController#update: #{{ file_size: File.size(params[:import_file].path), client_id: current_user.client_id, user_id: current_user.id }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"

        response = self.parse_import_file(params[:import_file])
      elsif sanitized_params.dig(:commit).to_s.casecmp?('header')
        header = [sanitized_params.dig(:header) || []].flatten
        @matching_fields = self.parse_header_fields(header)
      else
        self.import_data_from_file
      end

      respond_to do |format|
        format.json { render json: response, status: (response[:error].present? ? 415 : :ok) }
        format.js   { render partial: 'contacts/import/js/show', locals: { cards: %w[import_actions header_designer], header: } }
        format.html { render 'contacts/import/show' }
      end
    end

    private

    def authorize_user!
      super
      return if current_user.access_controller?('import_contacts', 'allowed', session)

      raise ExceptionHandlers::UserNotAuthorized.new('Import Contacts', root_path)
    end

    def import_data_from_file
      return unless (user_settings = current_user.user_settings.find_by(controller_action: 'contacts_import', current: 1))

      sanitized_params     = params.permit(:group_id, :header_row, :overwrite, :tag_id, :user_id)

      user                 = user_settings.user.client.users.find_by(id: sanitized_params.dig(:user_id))
      user_id              = user ? user.id : current_user.client.def_user_id
      overwrite            = sanitized_params.dig(:overwrite).to_bool
      group_id             = sanitized_params.dig(:group_id).to_i
      tag_id               = sanitized_params.dig(:tag_id).to_i
      header_row           = sanitized_params.dig(:header_row) == 'true' ? 0 : 1
      new_contact_count    = 0
      batch_rows           = []
      header_fields        = params.include?(:header_fields) ? params.require(:header_fields).permit(params[:header_fields].keys).to_h : {}
      spreadsheet          = user_settings.data.dig(:spreadsheet) || []
      run_at               = Time.current

      begin
        spreadsheet.each do |row|
          # scan through each row of the data
          if new_contact_count.zero? && header_row.zero?
            header_row = 1
            next
          end

          begin
            batch_rows << row
            new_contact_count += 1

            if (new_contact_count % 50).zero?
              # queue up the 50 rows to process
              Contacts::ImportCsvRowJob.set(wait_until: run_at).perform_later(
                batch_rows:,
                overwrite:,
                user_id:,
                group_id:,
                tag_id:,
                current_user_id: current_user.id,
                header_fields:
              )

              batch_rows = []
              run_at    += rand(15..30).seconds
            end
          rescue StandardError => e
            e.set_backtrace(BC.new.clean(caller))

            Appsignal.report_error(e) do |transaction|
              # Only needed if it needs to be different or there's no active transaction from which to inherit it
              Appsignal.set_action('Contacts::ImportsController#import_data_from_file')

              # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
              Appsignal.add_params(params)

              Appsignal.set_tags(
                error_level: 'error',
                error_code:  0
              )
              Appsignal.add_custom_data(
                new_contact_count: new_contact_count.to_s,
                row:               row.inspect,
                batch_rows:        batch_rows.inspect,
                file:              __FILE__,
                line:              __LINE__
              )
            end

            next
          end

          break if new_contact_count >= current_user.client.import_contacts_count.to_i
        end

        if (new_contact_count % 50).positive?
          # queue the balance of the imported rows to process
          Contacts::ImportCsvRowJob.set(wait_until: run_at).perform_later(
            batch_rows:,
            overwrite:,
            user_id:,
            group_id:,
            tag_id:,
            current_user_id: current_user.id,
            header_fields:
          )
        end
      rescue CSV::MalformedCSVError => e
        e.set_backtrace(BC.new.clean(caller))

        Appsignal.report_error(e) do |transaction|
          # Only needed if it needs to be different or there's no active transaction from which to inherit it
          Appsignal.set_action('Contacts::ImportsController#import_data_from_file')

          # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
          Appsignal.add_params(params)

          Appsignal.set_tags(
            error_level: 'error',
            error_code:  0
          )
          Appsignal.add_custom_data(
            file: __FILE__,
            line: __LINE__
          )
        end

        sweetalert_error('Unable to Read File!', "#{e.message} Please correct and try again.", '', { persistent: 'OK' })
      rescue StandardError => e
        e.set_backtrace(BC.new.clean(caller))

        Appsignal.report_error(e) do |transaction|
          # Only needed if it needs to be different or there's no active transaction from which to inherit it
          Appsignal.set_action('Contacts::ImportsController#import_data_from_file')

          # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
          Appsignal.add_params(params)

          Appsignal.set_tags(
            error_level: 'error',
            error_code:  0
          )
          Appsignal.add_custom_data(
            file: __FILE__,
            line: __LINE__
          )
        end
      end
    end

    def parse_csv_file(import_file)
      Users::Setting.where(user_id: current_user.id, controller_action: 'contacts_import').delete_all
      user_settings = current_user.user_settings.new(controller_action: 'contacts_import', name: '', data: { spreadsheet: [] }, current: 1)
      response      = self.parse_file_response_initialize

      begin
        imported_file = Roo::CSV.new(import_file.path)

        (1..imported_file.last_row).each do |row|
          user_settings.data[:spreadsheet] << imported_file.row(row)
        end

        user_settings.save

        response[:header]   = imported_file.row(1)
        response[:filename] = import_file.original_filename
      rescue CSV::MalformedCSVError => e
        response[:error]  = "Unable to Read File! Error: #{e.message} Please correct and try again."
        response[:error] += ' (This may be due to an incorrectly formatted file. This sometimes happens when sharing files between different operating systems. Try opening the file and saving it again.)' if e.message.downcase.include?('unquoted fields')
      rescue StandardError => e
        response[:error]  = "Unable to Read File! Error: #{e.message} Please correct and try again."

        e.set_backtrace(BC.new.clean(caller))

        Appsignal.report_error(e) do |transaction|
          # Only needed if it needs to be different or there's no active transaction from which to inherit it
          Appsignal.set_action('Contacts::ImportsController#parse_csv_file')

          # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
          Appsignal.add_params(params)

          Appsignal.set_tags(
            error_level: 'error',
            error_code:  0
          )
          Appsignal.add_custom_data(
            user_settings: user_settings.data,
            file:          __FILE__,
            line:          __LINE__
          )
        end
      end

      response
    end

    def parse_file_response_initialize
      { header: [], filename: '', error: '' }
    end

    # match user supplied header names with internal fields
    def parse_header_fields(header)
      available_matches = {
        'firstname'    => %w[firstname],
        'lastname'     => %w[lastname],
        'fullname'     => %w[name fullname customer],
        'companyname'  => %w[company],
        'email'        => %w[email],
        'phone_mobile' => %w[phone cell mobile],
        'phone_home'   => %w[home],
        'phone_work'   => %w[office work],
        'phone_fax'    => %w[fax],
        'address1'     => %w[address address1 street],
        'address2'     => %w[address address2 street],
        'city'         => %w[city],
        'state'        => %w[state],
        'zipcode'      => %w[zip postalcode],
        'birthdate'    => %w[birthday birthdate born],
        'ok2text'      => %w[ok2text oktotext],
        'ok2email'     => %w[ok2email oktoemail],
        'tag'          => %w[tag]
      }

      header.uniq.index_with do |field|
        if (match = available_matches.find { |_k, v| v.map { |x| %r{#{x}}.match?(field.downcase.delete(' ').delete('_').strip) }.include?(true) }&.first)
          # only allow matches to be found one time
          available_matches.delete(match).nil? ? nil : match
        end
      end
    end

    def parse_import_file(import_file)
      response = self.parse_file_response_initialize

      if ['.csv', '.xlsx'].include?(File.extname(import_file.original_filename))

        case File.extname(import_file.original_filename)
        when '.csv'
          response = self.parse_csv_file(import_file)
        when '.xlsx'
          response = self.parse_xlsx_file(import_file)
        else
          response[:error] = 'Unknown file type.'
        end
      end

      response
    end

    def parse_xlsx_file(import_file)
      Users::Setting.where(user_id: current_user.id, controller_action: 'contacts_import').delete_all
      user_settings = current_user.user_settings.new(controller_action: 'contacts_import', name: '', data: { spreadsheet: [] }, current: 1)
      response      = self.parse_file_response_initialize

      begin
        imported_file = Roo::Excelx.new(import_file.path)

        imported_file.each_row_streaming(pad_cells: true) do |row|
          user_settings.data[:spreadsheet] << row.map { |x| x ? ActionController::Base.helpers.sanitize(x.value.to_s, tags: []) : '' }
        end

        user_settings.save

        response[:header]   = user_settings.data[:spreadsheet][0]
        response[:filename] = import_file.original_filename
      rescue StandardError => e
        response[:error] = "Unable to Read File! Error: #{e.message} Please correct and try again."

        e.set_backtrace(BC.new.clean(caller))

        Appsignal.report_error(e) do |transaction|
          # Only needed if it needs to be different or there's no active transaction from which to inherit it
          Appsignal.set_action('Contacts::ImportsController#parse_xlsx_file')

          # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
          Appsignal.add_params(params)

          Appsignal.set_tags(
            error_level: 'error',
            error_code:  0
          )
          Appsignal.add_custom_data(
            response:           response.inspect,
            user_settings:      user_settings.inspect,
            user_settings_data: user_settings.data.inspect,
            file:               __FILE__,
            line:               __LINE__
          )
        end
      end

      response
    end
  end
end

# create a fake CSV file for import testing
# require 'faker'
# require 'csv'
# csv = CSV.new(File.new('contacts.csv', 'w'))
# csv << %w[FirstName LastName email phone address1 city state zip]
# 1_000.times do
#   csv << [Faker::Name.first_name, Faker::Name.last_name, "#{Faker::Internet.username}@gmail.com", Faker::PhoneNumber.cell_phone, Faker::Address.street_address, Faker::Address.city, Faker::Address.state_abbr, Faker::Address.zip_code]
# end
# csv.close
