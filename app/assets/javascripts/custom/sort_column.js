// app/assets/javascripts/custom/sort_column.js
//
// SortColumn({
//   'path_method':   'string',
//   'path':          'string',
//   'next_sort_dir': 'string',
//   'params':        'hash',
//   'turbo':         'boolean'
// });
function SortColumn(options) {
  var params = {};
  var path_method = 'GET';

  if (options.params) {
    params = options.params;
  }
  if (options.path_methods) {
    path_methods = options.path_method;
  }

  $('.sort_arrow').hover(function () {
    $(this).css('cursor', 'pointer');
  });

  $('.sort_arrow').on('click', function (e) {
    e.preventDefault();
    e.stopPropagation();

    var col = e.target.id.split('-')[1];
    var dir = e.target.id.split('-')[2];
    var target = 'sort-link-' + col;

    $('#' + target).append(' <span class=\"spinner-border spinner-border-sm\"></span>');

    var ajax_data = $.extend({}, params, { sort: { col: col, dir: dir } });
    if (options.turbo) {
      $.ajax({
        method: path_method,
        dataType: 'turbo_stream',
        accepts: {
          'turbo_stream': 'text/vnd.turbo-stream.html'
        },
        converters: {
          'text turbo_stream': function (data) {
            Turbo.renderStreamMessage(data);
          }
        },
        url: options.path,
        data: ajax_data
      });
    } else {
      $.ajax({
        method: path_method,
        dataType: 'script',
        url: options.path,
        data: ajax_data
      });
    }
  });

  $('.sort_link').on('click', function (e) {
    e.preventDefault();
    e.stopPropagation();

    var col = e.target.id.split('-')[2];

    $('#' + e.target.id).append(' <span class=\"spinner-border spinner-border-sm\"></span>');

    var ajax_data = $.extend({}, params, { sort: { col: col, dir: options.next_sort_dir } });
    if (options.turbo) {
      $.ajax({
        method: path_method,
        dataType: 'turbo_stream',
        accepts: {
          'turbo_stream': 'text/vnd.turbo-stream.html'
        },
        converters: {
          'text turbo_stream': function (data) {
            Turbo.renderStreamMessage(data);
          }
        },
        url: options.path,
        data: ajax_data
      });
    } else {
      $.ajax({
        method: path_method,
        dataType: 'script',
        url: options.path,
        data: ajax_data
      });
    }
  });
};
