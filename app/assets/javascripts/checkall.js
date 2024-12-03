$(document).on('ready', function () {
  // switch Select
  $('body').on('click','#select_switch',function(e) {
    if (e.currentTarget.checked) {
      $('.rows').find('input[type="checkbox"]').prop('checked', true);
    } else {
      $('.rows').find('input[type="checkbox"]').prop('checked', false);
    }
  });

  // Select all
  $('body').on('click','#select_all',function() {
    $("#" + $(this).attr('rel') + " INPUT[type='checkbox']").attr('checked', true);
    return false;
  });

  // Select none
  $('body').on('click','#select_none',function() {
    $("#" + $(this).attr('rel') + " INPUT[type='checkbox']").attr('checked', false);
    return false;
  });

  // Invert selection
  $('body').on('click','#invert_selection',function() {
    $("#" + $(this).attr('rel') + " INPUT[type='checkbox']").each( function() {
      $(this).attr('checked', !$(this).attr('checked'));
    });
    return false;
  });
});
