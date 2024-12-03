# frozen_string_literal: true

################
# The following config was used to modify dev data to work with a
# production customer's ST credentials that allowed us to test with them.
################

# ST testing keys used by Client 3030 in production. This is for testing the ST integration with Aiagent.
ClientApiIntegration.find_by(client_id: 1, target: 'servicetitan', name: '')&.destroy

ccf = ClientCustomField.create!(
  client_id:       1,
  var_name:        'Is The Caller Authorized To Pay For This Work?',
  var_var:         'is_the_caller_authorized_to_pay_for_this_work_',
  var_type:        'string',
  var_placeholder: 'Is The Caller Authorized To Pay For This Work?',
  var_important:   true,
  image_is_valid:  false
)
ccf.var_options = { string_options: 'Yes - Authorized to Approve the Work Required,No if not they can not book the job,Property Manager - Authorized to Approve the Work Required Commercial Client - Authorized to Approve the Work Required,Home Warranty Provider - Authorized to Approve the Work Required' }
ccf.save!

ClientApiIntegration.create! client_id:      1,
                             target:         'servicetitan',
                             name:           '',
                             api_key:        '',
                             tenant_api_key: '',
                             credentials:    { 'app_id'               => '',
                                               'client_id'            => '',
                                               'tenant_id'            => '',
                                               'access_token'         => '',
                                               'client_secret'        => '',
                                               'access_token_expires' => 0 },
                             booking_fields: {
                               '119778' => { 'use' => 'req', 'name' => 'Is The Caller Authorized To Pay For The Work?', 'order' => '0', 'client_custom_field_id' => ccf.id }
                             }

# wayne gretzky
Contact.find(29_777).ext_references.destroy_all
Contact.find(29_777).ext_references.create! target: 'servicetitan', ext_id: ''

################
# END
################
