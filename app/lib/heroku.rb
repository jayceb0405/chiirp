# frozen_string_literal: true

# app/lib/heroku.rb
class Heroku
  # process various API calls to Heroku

  # delete a hostname in Heroku at chiirpapp
  # Heroku.new.delete_hostname(hostname: String)
  def delete_hostname(args)
    hostname = args[:hostname].to_s
    response = { success: false, result: [], error_code: '', error_message: '' }

    if hostname.present?

      begin
        heroku_client  = PlatformAPI.connect_oauth Rails.application.credentials[:heroku][:platform_api_key]
        heroku_domain  = heroku_client.domain
        heroku_deleted_domain = heroku_domain.delete('chiirpapp', hostname)

        if heroku_deleted_domain['status'].to_s.casecmp?('succeeded')
          response[:success] = true
          response[:result]  = heroku_deleted_domain
        else
          response[:error_code]    = ''
          response[:error_message] = heroku_deleted_domain['status']
        end
      rescue Excon::Error::NotFound
        response[:success] = true
      rescue StandardError => e
        ProcessError::Report.send(
          error_message: "Heroku::Unknown: #{e.message}",
          variables:     {
            e:                     e.inspect,
            args:                  args.inspect,
            heroku_client:         (defined?(heroku_client) ? heroku_client.inspect : nil),
            heroku_domain:         (defined?(heroku_domain) ? heroku_domain.inspect : nil),
            heroku_deleted_domain: (defined?(heroku_deleted_domain) ? heroku_deleted_domain.inspect : nil),
            success:               response[:success],
            result:                response[:result],
            error_code:            response[:error_code],
            error_message:         response[:error_message]
          },
          file:          __FILE__,
          line:          __LINE__
        )
      end
    end

    response
  end

  # return cname for a specific hostname in Heroku at chiirpapp
  # Heroku.new.get_cname(hostname: String)
  def get_cname(args)
    hostname = args[:hostname].to_s
    response = ''

    if hostname.present?
      domains = list_domains

      if domains && (domains_index = domains.index { |domain| domain['hostname'] == hostname })
        response = domains[domains_index]['cname']
      end
    end

    response
  end

  # return array of Hostnames in Heroku at chiirpapp
  # Heroku.new.get_hostnames
  #
  # rubocop:disable Naming/AccessorMethodName
  def get_hostnames
    # rubocop:enable Naming/AccessorMethodName
    domains = list_domains

    (domains ? domains.pluck('hostname') : [])
  end

  # list domains set up in Heroku at chiirpapp
  # Heroku.new.list_domains
  def list_domains
    response = nil

    begin
      heroku_client  = PlatformAPI.connect_oauth Rails.application.credentials[:heroku][:platform_api_key]
      heroku_domain  = heroku_client.domain
      heroku_domains = heroku_domain.list 'chiirpapp'

      response = heroku_domains
    rescue StandardError => e
      ProcessError::Report.send(
        error_message: "Heroku::Unknown: #{e.message}",
        variables:     {
          e:              e.inspect,
          heroku_client:  (defined?(heroku_client) ? heroku_client.inspect : nil),
          heroku_domain:  (defined?(heroku_domain) ? heroku_domain.inspect : nil),
          heroku_domains: (defined?(heroku_domains) ? heroku_domains.inspect : nil)
        },
        file:          __FILE__,
        line:          __LINE__
      )
    end

    response
  end

  # restart a Heroku dyno
  # Heroku.new.restart_dyno String
  def restart_dyno(dyno_name)
    JsonLog.info 'Heroku.restart_dyno', { dyno_name: }

    begin
      heroku_connection = PlatformAPI.connect_oauth Rails.application.credentials[:heroku][:platform_api_key]
      heroku_connection.dyno.restart('chiirpapp', dyno_name)
    rescue Excon::Error::InternalServerError => e
      ProcessError::Report.send(
        error_message: "Heroku::RestartDyno: #{e.message}",
        variables:     {
          dyno_name:         dyno_name.inspect,
          e:                 e.inspect,
          heroku_connection: (defined?(heroku_connection) ? heroku_connection.inspect : nil)
        },
        file:          __FILE__,
        line:          __LINE__
      )
    rescue StandardError => e
      ProcessError::Report.send(
        error_message: "Heroku::RestartDyno: #{e.message}",
        variables:     {
          dyno_name:         dyno_name.inspect,
          e:                 e.inspect,
          heroku_connection: (defined?(heroku_connection) ? heroku_connection.inspect : nil)
        },
        file:          __FILE__,
        line:          __LINE__
      )
    end
  end

  # save a hostname in Heroku at chiirpapp
  # Heroku.new.set_hostname(hostname: String)
  #
  # rubocop:disable Naming/AccessorMethodName
  def set_hostname(args)
    # rubocop:enable Naming/AccessorMethodName
    hostname = args[:hostname].to_s
    response = { success: false, result: [], error_code: '', error_message: '' }

    if hostname.present?

      begin
        heroku_client     = PlatformAPI.connect_oauth Rails.application.credentials[:heroku][:platform_api_key]
        heroku_domain     = heroku_client.domain
        heroku_new_domain = heroku_domain.create('chiirpapp', { hostname: })

        if %w[succeeded pending].include?(heroku_new_domain['status'].to_s.downcase)
          response[:success] = true
          response[:result]  = heroku_new_domain
        else
          response[:error_code]    = ''
          response[:error_message] = heroku_new_domain['status']
        end
      rescue Excon::Error::UnprocessableEntity => e
        response[:error_code]    = e.response.data[:status]
        response[:error_message] = JSON.parse(e.response.data[:body])['message']
      rescue StandardError => e
        ProcessError::Report.send(
          error_message: "Heroku::Unknown: #{e.message}",
          variables:     {
            e:                 e.inspect,
            args:              args.inspect,
            heroku_client:     (defined?(heroku_client) ? heroku_client.inspect : nil),
            heroku_domain:     (defined?(heroku_domain) ? heroku_domain.inspect : nil),
            heroku_new_domain: (defined?(heroku_new_domain) ? heroku_new_domain.inspect : nil),
            success:           response[:success],
            result:            response[:result],
            error_code:        response[:error_code],
            error_message:     response[:error_message]
          },
          file:          __FILE__,
          line:          __LINE__
        )
      end
    end

    response
  end
end
