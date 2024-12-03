// app/views/snippets/js/stop_campaign_alert.js
//
// StopCampaignAlert({
//   'campaign_id': 'string',
//   'name':        'string',
//   'active':      'string',
//   'return_to':   'string'
// });
function StopCampaignAlert(options) {
  console.log(options);
  var campaignId = options.campaign_id;
  var campaignName = options.name;
  var campaignActive = options.active;
  var returnTo = options.return_to;

  console.log(campaignActive);

  if (campaignActive) {
    ChiirpAlert({
      'body': 'Deactivating "' + campaignName + '" will stop any more Campaigns from starting. You may also choose to stop all "' + campaignName + '" Campaigns currently in progress. Is it your intention to deactivate this campaign?',
      'buttons': [{ label: '<i class="fa fa-thumbs-down"></i> No, Wait!', id: 'button_no_wait' }, { label: '<i class="fa fa-thumbs-up"></i> Yup, Go for it!', id: 'button_do_it' }, { label: '<i class="fa fa-thumbs-up"></i> Yup, stop all Campaigns!', id: 'button_stop_all' }],
      'type': 'danger',
      'persistent': true
    });

    $(document).off('click', '#button_do_it');
    $(document).on('click', '#button_do_it', function (e) {
      e.preventDefault();

      $.ajax({
        type: 'PATCH',
        dataType: 'script',
        url: '/campaigns/' + campaignId,
        data: {
          confirm: 'deactivate',
          return_to: returnTo,
          stop_all: 'false'
        }
      });
    });

    $(document).off('click', '#button_stop_all');
    $(document).on('click', '#button_stop_all', function (e) {
      e.preventDefault();

      $.ajax({
        type: 'PATCH',
        dataType: 'script',
        url: '/campaigns/' + campaignId,
        data: {
          confirm: 'deactivate',
          return_to: returnTo,
          stop_all: 'true'
        }
      });
    });
  } else {
    $.ajax({
      type: 'PATCH',
      dataType: 'script',
      url: '/campaigns/' + campaignId,
      data: {
        confirm: 'activate',
        return_to: returnTo
      }
    });
  }
}
