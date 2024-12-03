# frozen_string_literal: true

# app/lib/integrations/success_ware/v202311/jobs.rb
module Integrations
  module SuccessWare
    module V202311
      module Jobs
        # call Successware API for a job
        # sw_client.job()
        #   (req) successware_job_id: (String)
        def job(successware_job_id = 0)
          reset_attributes
          @result = {}

          unless successware_job_id.to_i.positive?
            @message = 'Successware job ID is required.'
            return @result
          end

          body = {
            query: <<-GRAPHQL.squish
              query {
                searchJobs(page: 0, size: 1, input: { ids: #{successware_job_id}}) {
                  content {
                    id
                    number
                    jobClass
                    jobType
                    jobTypeDescription
                    status
                    serviceAccountId
                    locationId
                    department
                    startDate
                    endDate
                    scheduledFor
                    contact
                    visits {
                      id
                      type
                      scheduleDate
                      status
                    }
                    invoices {
                      id
                      type
                      number
                      totalAmount
                    }
                    assignments {
                      id
                      employeeCode
                      status
                    }
                  }
                  successful
                  message
                  errors {
                    path
                    errorMessage
                  }
                  totalElements
                  totalPages
                  pageSize
                  pageNumber
                  numberOfElements
                }
              }
            GRAPHQL
          }

          successware_request(
            body:,
            error_message_prepend: 'Integrations::SuccessWare::V202311::Jobs.job',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   api_url
          )

          @result  = (@result.is_a?(Hash) && @result.dig(:data, :searchJobs, :content)&.first) || {}
          @success = @result.present?

          @result
        end
        # example Successware job
        # {
        #   id:                 '1094200628',
        #   number:             '200628',
        #   jobClass:           'Plumb-repair',
        #   jobType:            'PLREP',
        #   jobTypeDescription: 'Plumbing Repair',
        #   status:             'CLOSED',
        #   serviceAccountId:   '1094349605',
        #   locationId:         '1094349605',
        #   department:         nil,
        #   startDate:          '2008-02-11T14:45:00Z',
        #   endDate:            '2008-02-11T05:00:00Z',
        #   scheduledFor:       '2008-02-11T12:45:00Z',
        #   contact:            nil,
        #   visits:             [],
        #   invoices:           [{ id: '1094300620', type: 'JOB', number: '300620', totalAmount: 991.0 }],
        #   assignments:        [{ id: '1094006774', employeeCode: 'SHEWES', status: 'COMPLETED' }]
        # }

        def job_classes
          reset_attributes
          @result = []

          body = {
            query: <<-GRAPHQL.squish
              query {
                getJobClasses(inactive: false) {
                  jobClassId
                  code
                  saleEst
                  active
                  jobTypes {
                    id
                    code
                    description
                    estimatedDuration
                    active
                    department {
                      id
                      departmentName
                      description
                      active
                    }
                  }
                }
              }
            GRAPHQL
          }

          successware_request(
            body:,
            error_message_prepend: 'Integrations::SuccessWare::V202311::Jobs.job_classes',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   api_url
          )

          @result = (@result.is_a?(Hash) ? @result.dig(:data, :getJobClasses) : nil) || []
        end

        # call Successware API for a specific location
        # sw_client.job_location()
        #   (req) successware_location_id: (String)
        def job_location(successware_location_id)
          reset_attributes
          @result = {}

          unless successware_location_id.to_i.positive?
            @message = 'Successware location ID is required.'
            return @result
          end

          body = {
            query: <<-GRAPHQL.squish
              query {
                queryLocationById (id: #{successware_location_id}) {
                  successful
                  message
                  errors {
                    path
                    errorMessage
                  }
                  location {
                    id
                    address1
                    address2
                    city
                    state
                    zipCode
                    type
                    companyName
                  }
                }
              }
            GRAPHQL
          }

          successware_request(
            body:,
            error_message_prepend: 'Integrations::SuccessWare::V202311::Jobs.job_location',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   api_url
          )

          @result  = (@result.is_a?(Hash) && @result.dig(:data, :queryLocationById, :location)) || {}
          @success = @result.present?

          @result
        end

        # call Successware API for job types
        # sw_client.job_types()
        def job_types
          reset_attributes
          @result = []

          body = {
            query: <<-GRAPHQL.squish
              query {
                getJobAndCall(inactive: false) {
                  id
                  code
                  description
                  jobClass
                  department
                  active
                }
              }
            GRAPHQL
          }

          successware_request(
            body:,
            error_message_prepend: 'Integrations::SuccessWare::V202311::Jobs.job_types',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   api_url
          )

          @result  = (@result.is_a?(Hash) && @result.dig(:data, :getJobAndCall)) || []
          @success = @result.present?

          @result
        end
        # example Successware job types
        # [
        #   { id: '1094000158', code: '2ndOPI', description: '2nd Opinion',                   jobClass: 'Repair',          department: 'R1 - Residential Service',      active: true },
        #   { id: '1094000094', code: 'ACECR',  description: 'AC and Evap Coil Replacement',  jobClass: 'Install/Replace', department: 'I1 - Replacement Installation', active: true },
        #   { id: '1094000095', code: 'ACR',    description: 'AC Condenser Only Replacement', jobClass: 'Install/Replace', department: 'I1 - Replacement Installation', active: true },
        #   { id: '1094000096', code: 'AIRHR',  description: 'Air Handler Only Replacement',  jobClass: 'Install/Replace', department: 'I1 - Replacement Installation', active: true },
        #   { id: '1094000020', code: 'BAKFLO', description: 'Comm Backflow Test',            jobClass: 'Comm-Plumbing',   department: 'P1 - Plumbing Service',         active: true },
        #   { id: '1094000051', code: 'BIOCID', description: 'Microbiocide',                  jobClass: 'Duct Cleaning',   department: 'D1 - Duct Cleaning',            active: true },
        #   { id: '1094000167', code: 'CBINST', description: 'Callback on Install',           jobClass: 'Repair',          department: 'R1 - Residential Service',      active: true },
        #   { id: '1094000169', code: 'CBSRV',  description: 'Callback on Service',           jobClass: 'Repair',          department: 'R1 - Residential Service',      active: true },
        #   { id: '1094000287', code: 'CLUBSI', description: 'Silver Club',                   jobClass: 'Sch/Ser',         department: 'S1 - Scheduled Service',        active: true }
        # ]

        # call Successware API for jobs
        # sw_client.jobs
        #   (opt) filter:     (Hash)
        #     canceled:         (Boolean)
        #     closed:           (Boolean)
        #     status:           (String)
        #     ids:              (Integer)
        #     locationId:       (Integer)
        #     serviceAccountId: (Integer)
        #     jobType:          (String)
        #     jobClass:         (String)
        #   (opt) page:       (Integer)
        def jobs(args = {})
          reset_attributes
          @result = []

          jobs = []
          page = args.dig(:page).to_i

          loop do
            body = {
              query: <<-GRAPHQL.squish
                query {
                  searchJobs(page: #{page}, size: #{Integrations::SuccessWare::V202311::Base::PAGE_SIZE}, input: #{self.hash_to_graphql(args.dig(:filter).presence || {})}) {
                    content{
                      id
                      jobClass
                      jobType
                      jobTypeDescription
                      status
                      serviceAccountId
                      locationId
                      department
                      startDate
                      endDate
                      contact
                    }
                    successful
                    message
                    errors {
                      path
                      errorMessage
                    }
                    totalElements
                    totalPages
                    pageSize
                    pageNumber
                    numberOfElements
                  }
                }
              GRAPHQL
            }

            successware_request(
              body:,
              error_message_prepend: 'Integrations::SuccessWare::V202311::Jobs.jobs',
              method:                'post',
              params:                nil,
              default_result:        @result,
              url:                   api_url
            )

            jobs += @result.dig(:data, :searchJobs, :content) || []
            break unless args.dig(:page).blank? || (@result.dig(:data, :searchJobs, :totalPages).to_i - 1) == page

            page += 1
            # sleep_before_throttling(@result.dig(:extensions), @result.dig(:extensions, :cost, :actualQueryCost))
          end

          @result = jobs.compact_blank
        end
        # example Successware jobs
        # [
        #   {
        #     id:                 '1094200714',
        #     jobClass:           'Repair',
        #     jobType:            'NOHEAT',
        #     jobTypeDescription: 'Unit Not Heating',
        #     status:             'CLOSED',
        #     serviceAccountId:   '1094335031',
        #     locationId:         '1094335031',
        #     department:         nil,
        #     startDate:          '2008-02-09T19:30:00Z',
        #     endDate:            '2008-02-09T05:00:00Z',
        #     contact:            nil
        #   },
        #   {
        #     id:                 '1094200386',
        #     jobClass:           'Sch/Ser',
        #     jobType:            'SS H1',
        #     jobTypeDescription: nil,
        #     status:             'CLOSED',
        #     serviceAccountId:   '1094310455',
        #     locationId:         '1094310455',
        #     department:         nil,
        #     startDate:          '2008-02-09T20:00:00Z',
        #     endDate:            '2008-02-09T05:00:00Z',
        #     contact:            nil
        #   },
        #   {
        #     id:                 '1094200322',
        #     jobClass:           'Plumb-repair',
        #     jobType:            'PLREP',
        #     jobTypeDescription: 'Plumbing Repair',
        #     status:             'CLOSED',
        #     serviceAccountId:   '1094238152',
        #     locationId:         '1094238152',
        #     department:         nil,
        #     startDate:          '2008-02-09T20:00:00Z',
        #     endDate:            '2008-02-09T05:00:00Z',
        #     contact:            nil
        #   },
        #   {
        #     id:                 '1094200730',
        #     jobClass:           'Sales',
        #     jobType:            'FURNO',
        #     jobTypeDescription: nil,
        #     status:             'CLOSED',
        #     serviceAccountId:   '1094334673',
        #     locationId:         '1094334673',
        #     department:         nil,
        #     startDate:          '2008-02-09T21:15:00Z',
        #     endDate:            '2008-02-09T05:00:00Z',
        #     contact:            nil
        #   },
        #   {
        #     id:                 '1094200698',
        #     jobClass:           'Sales',
        #     jobType:            'ESTSYS',
        #     jobTypeDescription: 'ESTIMATE System Replacement',
        #     status:             'CLOSED',
        #     serviceAccountId:   '1094279930',
        #     locationId:         '1094279930',
        #     department:         nil,
        #     startDate:          '2008-02-09T21:30:00Z',
        #     endDate:            '2008-02-09T05:00:00Z',
        #     contact:            nil
        #   },
        #   ...
        # ]
      end
    end
  end
end
