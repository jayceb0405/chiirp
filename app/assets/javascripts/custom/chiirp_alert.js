// app/assets/javascripts/custom/chiirp_alert.js
//
// ChiirpAlert({
//   'title':      'string',
//   'header':     'string',
//   'body':       'string',
//   'buttons':    'string',
//   'footer':     'string',
//   'type':       'primary/secondary/success/danger/warning/question/info',
//   'persistent': boolean
// });
function ChiirpAlertElement(element) {
  var title = element.getAttribute('data-alert-title');
  var header = element.getAttribute('data-alert-header');
  var body = element.getAttribute('data-alert-body');
  var buttons = element.getAttribute('data-alert-buttons');
  var footer = element.getAttribute('data-alert-footer');
  var type = element.getAttribute('data-alert-type');
  var persistent = element.getAttribute('data-alert-persistent');

  alertHeader(header);
  alertTitle(title);
  alertBody(body);
  alertFooter(footer);

  $('#alert_modal').modal('show');
}
function ChiirpAlert(options) {

  if (options.buttons) {
    buttons = options.buttons;
  } else {
    buttons = [{ label: 'Close', id: 'button_close' }];
  }

  options = ChiirpAlert.setOptions(options);
  options.buttons = buttons

  ChiirpAlert.alertHeader(options);
  ChiirpAlert.alertTitle(options);
  ChiirpAlert.alertBody(options);
  ChiirpAlert.alertFooter(options);

  $('#alert_modal').modal('show');
};
ChiirpAlert.setOptions = function (options) {
  var options = ChiirpAlert.applyDefaults({
    title: '',
    header: '',
    body: '',
    footer: '',
    type: 'primary',
    dismissButtonLabel: 'Close',
    persistent: true
  }, options);

  return options
}
ChiirpAlert.alertHeader = function (options) {
  if (options.persistent) {
    $('#alert_modal').addClass('modal-alert');
    $('#alert_modal').attr('data-backdrop', 'static');
  } else {
    $('#alert_modal').removeClass('modal-alert');
    $('#alert_modal').removeAttr('data-backdrop');
    setTimeout(function () { $('#alert_modal').modal('hide'); }, 4000);
  }

  if (options.header) {
    $('#alert_modal_header').html(options.header);
  }
}
ChiirpAlert.alertTitle = function (options) {
  if (options.type === 'primary') {
    title = '<i class="fa fa-info text-primary mr-2"></i>' + ((options.title) ? options.title : '');
  } else if (options.type === 'secondary') {
    title = '<i class="fa fa-info text-secondary mr-2"></i>' + ((options.title) ? options.title : '');
  } else if (options.type === 'success') {
    title = '<i class="fa fa-check text-success mr-2"></i>' + ((options.title) ? options.title : 'Success');
  } else if (options.type === 'danger') {
    title = '<i class="fa fa-ban text-danger mr-2"></i>' + ((options.title) ? options.title : 'Alert: Danger');
  } else if (options.type === 'warning') {
    title = '<i class="fa fa-exclamation-triangle text-warning mr-2"></i>' + ((options.title) ? options.title : 'Alert: Warning');
  } else if (options.type === 'question') {
    title = '<i class="fa fa-question text-primary mr-2"></i>' + ((options.title) ? options.title : 'Input Needed');
  } else if (options.type === 'info') {
    title = '<i class="fa fa-info text-info mr-2"></i>' + ((options.title) ? options.title : 'Important Information');
  } else {
    title = '';
  }
  if (title) {
    $('#alert_modal_title').html(title);
  }
}
ChiirpAlert.alertBody = function (options) {
  if (options.body) {
    $('#alert_modal_body').html(options.body);
  }
}
ChiirpAlert.alertFooter = function (options) {
  var buttons = '';

  if (options.persistent) {
    $.each(options.buttons, function (index, button) {
      buttons += '<button type="button" class="btn btn-light ml-2" id="' + button.id + '" data-dismiss="modal">' + button.label + '</button>';
    });
  }

  if (options.footer || buttons) {
    $('#alert_modal_footer').html(options.footer + buttons);
  } else {
    $('#alert_modal_footer').html('');
  }
}
ChiirpAlert.applyDefaults = function (defaults, prefs) {
  prefs = prefs || {};
  var prop, result = {};
  for (prop in defaults) result[prop] = prefs[prop] !== undefined ? prefs[prop] : defaults[prop];
  return result;
}
