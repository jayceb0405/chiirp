import "@hotwired/turbo-rails"
Turbo.session.drive = false

Turbo.StreamActions.append_class = function () {
  const new_class = this.getAttribute('new_class')
  this.targetElements.forEach(element => element.classList.add(new_class))
};

Turbo.StreamActions.bootstrap_init = function () {
  $('.tooltip').remove();
  Looper.init()
}

Turbo.StreamActions.collapse_show = function () {
  this.targetElements.forEach((target) => {
    $('#' + target.id).collapse('show')
  });
};

Turbo.StreamActions.collapse_hide = function () {
  this.targetElements.forEach((target) => {
    $('#' + target.id).collapse('hide')
  });
};

Turbo.StreamActions.collapse_toggle = function () {
  this.targetElements.forEach((target) => {
    $('#' + target.id).collapse('toggle')
  });
};

Turbo.StreamActions.console_log = function () {
  console.log(this.getAttribute("message"))
}

Turbo.StreamActions.hide = function () {
  this.targetElements.forEach((target) => {
    $('#' + target.id).hide()
  });
};

Turbo.StreamActions.hide_modal = function () {
  this.targetElements.forEach((target) => {
    $('#' + target.id).modal('hide')
  });
};

Turbo.StreamActions.remove_class = function () {
  const old_class = this.getAttribute('old_class')
  this.targetElements.forEach(element => element.classList.remove(old_class))
};

Turbo.StreamActions.rotate_button = function () {
  this.targetElements.forEach((target) => {
    if (target.classList.contains('rotate-90')) {
      target.classList.remove('rotate-90')
    } else {
      target.classList.add('rotate-90')
    }
  });
};

Turbo.StreamActions.rotate_button_closed = function () {
  this.targetElements.forEach((target) => {
    target.classList.remove('rotate-90')
  });
};

Turbo.StreamActions.rotate_button_open = function () {
  this.targetElements.forEach((target) => {
    if (!target.classList.contains('rotate-90')) {
      target.classList.add('rotate-90')
    }
  });
};

Turbo.StreamActions.redirect_to = function () {
  const location = this.getAttribute('location')
  window.location = location;
};

Turbo.StreamActions.show = function () {
  this.targetElements.forEach((target) => {
    $('#' + target.id).show()
  });
};

Turbo.StreamActions.show_modal = function () {
  this.targetElements.forEach((target) => {
    $('#' + target.id).modal('show')
  });
};

Turbo.StreamActions.toast = function () {
  const type = this.getAttribute('type')
  const body = this.getAttribute('body')
  const subject = this.getAttribute('subject')
  const timeout = this.getAttribute('timeout')
  const extended_timeout = this.getAttribute('extendedtimeout')

  if (type == 'success') {
    toastr.success(body, subject, { timeOut: timeout, extendedTimeOut: extended_timeout })
  } else if (type == 'info') {
    toastr.info(body, subject, { timeOut: timeout, extendedTimeOut: extended_timeout })
  } else if (type == 'warning') {
    toastr.warning(body, subject, { timeOut: timeout, extendedTimeOut: extended_timeout })
  } else if (type == 'error') {
    toastr.error(body, subject, { timeOut: timeout, extendedTimeOut: extended_timeout })
  }
};

// handle turbo:frame-missing event
document.addEventListener('turbo:frame-missing', function (event) {
  // this handles the case where the user is not signed in and a turbo frame page is redirected to the sign in page
  if (event.detail.response.redirected == true && event.detail.response.url.endsWith('/users/sign_in?expired=true')) {
    event.detail.visit(event.detail.response.url);
  }
});
