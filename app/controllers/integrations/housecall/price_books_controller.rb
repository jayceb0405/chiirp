# frozen_string_literal: true

# app/controllers/integrations/housecall/price_books_controller.rb
module Integrations
  module Housecall
    class PriceBooksController < Housecall::IntegrationsController
      # (GET) show Price Book import
      # /integrations/housecall/price_book
      # integrations_housecall_price_book_path
      # integrations_housecall_price_book_url
      def show
        respond_to do |format|
          format.js { render partial: 'integrations/housecall/js/show', locals: { cards: %w[price_book_show] } }
          format.html { redirect_to integrations_housecall_path }
        end
      end

      # (PUT/PATCH) import Price Book
      # /integrations/housecall/price_book
      # integrations_housecall_price_book_path
      # integrations_housecall_price_book_url
      def update
        response = { filename: '', error: '', message: '', total_line_items: 0 }

        if params.include?(:import_file) && ['.csv', '.xlsx'].include?(File.extname(params[:import_file].original_filename))
          new_price_book  = params.dig(:merge_line_items).to_bool ? @client_api_integration.price_book : {}
          header_row      = []
          row_count       = 0
          uuid_column     = 0
          name_column     = 0
          category_column = 0

          case File.extname(params[:import_file].original_filename)
          when '.csv'

            begin
              import_file = Roo::CSV.new(params[:import_file].path)

              (1..import_file.last_row).each do |row|
                line_item = import_file.row(row)

                if row_count.zero?
                  header_row      = line_item
                  uuid_column     = header_row.index('uuid')
                  name_column     = header_row.index('name')
                  category_column = header_row.index('category')
                else
                  new_price_book[line_item[uuid_column]] = { name: line_item[name_column], category: line_item[category_column] }
                end

                row_count += 1
              end

              row_count = [row_count - 1, 0].max
              response[:filename] = params[:import_file].original_filename
            rescue CSV::MalformedCSVError => e
              response[:error]  = "Unable to Read File! Error: #{e.message} Please correct and try again."
              response[:error] += ' (This may be due to an incorrectly formatted file. This sometimes happens when sharing files between different operating systems. Try opening the file and saving it again.)' if e.message.downcase.include?('unquoted fields')
            rescue StandardError => e
              response[:error]  = "Unable to Read File! Error: #{e.message} Please correct and try again."

              e.set_backtrace(BC.new.clean(caller))

              Appsignal.report_error(e) do |transaction|
                # Only needed if it needs to be different or there's no active transaction from which to inherit it
                Appsignal.set_action('Integrations::Housecall::PriceBooksController#update')

                # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
                Appsignal.add_params(params)

                Appsignal.set_tags(
                  error_level: 'error',
                  error_code:  0
                )
                Appsignal.add_custom_data(
                  header_row:,
                  import_file:,
                  line_item:      defined?(line_item) ? line_item : 'Undefined',
                  new_price_book:,
                  response:,
                  row_count:,
                  file:           __FILE__,
                  line:           __LINE__
                )
              end
            end
          when '.xlsx'

            begin
              import_file = Roo::Excelx.new(params[:import_file].path)

              import_file.each_row_streaming(pad_cells: true, headers: true) do |row|
                line_item = row.map { |x| x ? x.value : '' }

                if row_count.zero?
                  header_row      = line_item
                  uuid_column     = header_row.index('uuid')
                  name_column     = header_row.index('name')
                  category_column = header_row.index('category')
                elsif row_count.positive?
                  new_price_book[line_item[uuid_column]] = { name: line_item[name_column], category: line_item[category_column] }
                end

                row_count += 1
              end

              row_count = [row_count - 2, 0].max
              response[:filename] = params[:import_file].original_filename
            rescue StandardError => e
              response[:error] = "Unable to Read File! Error: #{e.message} Please correct and try again."

              e.set_backtrace(BC.new.clean(caller))

              Appsignal.report_error(e) do |transaction|
                # Only needed if it needs to be different or there's no active transaction from which to inherit it
                Appsignal.set_action('Integrations::Housecall::PriceBooksController#update')

                # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
                Appsignal.add_params(params)

                Appsignal.set_tags(
                  error_level: 'error',
                  error_code:  0
                )
                Appsignal.add_custom_data(
                  header_row:,
                  import_file:,
                  line_item:      defined?(line_item) ? line_item : 'Undefined',
                  new_price_book:,
                  response:,
                  row:            defined?(row) ? row : 'Undefined',
                  row_count:,
                  file:           __FILE__,
                  line:           __LINE__
                )
              end
            end
          else
            response[:error] = 'Unknown file type.'
          end

          # services header  %w[industry industry_uuid category uuid name description price cost taxable unit_of_measure]
          # materials header %w[category subcategory_1 uuid name description part_number price cost taxable unit_of_measure material_markup_enabled]
          # categories to be removed
          remove_categories = %w[subcategory_01 subcategory_02 subcategory_03 subcategory_1 subcategory_2 subcategory_3 task_code online_booking_enabled]

          if header_row - remove_categories == %w[industry industry_uuid category uuid name description price cost taxable unit_of_measure] || header_row - remove_categories == %w[category uuid name description part_number price cost taxable unit_of_measure material_markup_enabled]
            response[:total_line_items] = row_count
            response[:message]          = "#{response[:total_line_items]} line items imported successfully."
            @client_api_integration.update(price_book: new_price_book)
          else
            response[:error] = 'Unknown file format. Was the file received from Housecall Pro?'
          end
        end

        respond_to do |format|
          format.json { render json: response, status: (response[:error].present? ? 415 : :ok) }
          format.js { render partial: 'integrations/housecall/js/show', locals: { cards: %w[price_book_show] } }
          format.html { redirect_to integrations_housecall_path }
        end
      end
    end
  end
end
