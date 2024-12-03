// app/assets/javascripts/custom/multi_typeahead.js.erb
//
// Example:
//   MultiTypeahead('#emoji_textarea', < %= options_for_hashtag(client: cp.client).to_json.html_safe %>, '#', true);
//
// include style to drop-up menu
// <style>
//   .tt-menu.tt-open{
//     bottom:100% !important;
//     top:auto!important;
//   }
// </style>
function MultiTypeahead(id, data, trigger, vertAdjustMenu) {
  trigger = (undefined !== trigger) ? trigger : '';
  var validChars = /^[a-zA-Z]+$/;

  data_keys = []
  $.each(data, function(key, value) { data_keys.push(key) });

  function extractor(query) {
    var result = (new RegExp('([^,; \r\n]+)$')).exec(query);
    if(result && result[1])
      return result[1].trim();
    return '';
  }

  var lastUpper = false;
  function strMatcher(id, strs) {
    return function findMatches(q, sync, async) {
      var pos = $(id).caret('pos');
      q = (0 < pos) ? extractor(q.substring(0, pos)) : '';

      if (q.length < trigger.length)
        return;

      if (trigger.length)
      {
        if (trigger != q.substr(q.indexOf(trigger), trigger.length))
          return;
        
        q = q.substr(q.indexOf(trigger) + trigger.length);
      }

      var firstChar = q.substr(0, 1);
      lastUpper = (firstChar === firstChar.toUpperCase() && firstChar !== firstChar.toLowerCase());

      // position pop-up/down
      var cpos = $(id).caret('position');
      $(id).parent().find('.tt-menu').css('left', cpos.left + 'px');
      if (vertAdjustMenu) {
        $('<style>.tt-menu.tt-open { bottom:100%!important;top:auto!important;max-width:300px; }</style>').appendTo('body');
        $(id).parent().find('.tt-menu').css('top', (cpos.top + cpos.height) + 'px');
      } else {
        $('<style>.tt-menu.tt-open { max-width:300px; }</style>').appendTo('body');
      }

      var matches = [];
      var matches = [], substrRegex = new RegExp(q, 'i');
      $.each(strs, function(i, str) 
      {
        if (str.length > q.length && substrRegex.test(str))
          matches.push(str);
      });
    
      if (!matches.length)
        return;
    
      sync(matches);
    };
  };

  var hashPos = 0;
  var hashLen = 0;

  function onChange(event, suggestion) {
    // Normalized version of the native change event.
    lastVal = $(id).typeahead('val');
    // if (lastVal) {
      // $(id).typeahead('val', lastVal);
      // $(id).val(lastVal);
    // }
  }
  function onCursorChange(event, suggestion) {
    // Fired when the results container cursor moves.
    $(id).typeahead('val', lastVal);
    // $(id).val(lastVal);
  }
  function onRender(event, suggestion, async, dataset_name) {
    // Fired when suggestions are rendered for a dataset.
    lastVal = $(id).typeahead('val');
    // lastVal = $(id).val();

    if (lastVal[$(id).caret('pos') - 1] == trigger) {
      hashPos = $(id).caret('pos');
      hashLen = 1;
    } else if (hashLen > 0) {
      hashLen = $(id).caret('pos') - hashPos + 1;
    }
  }
  function onSelect(event, suggestion) {
    // Fired when a suggestion is selected.

    if (!suggestion || !suggestion.length)
      return;

    $(id).typeahead('val', lastVal.slice(0, hashPos - 1) + data[suggestion] + lastVal.slice(hashPos + hashLen - 1));
    // $(id).val(lastVal.slice(0, hashPos - 1) + data[suggestion] + lastVal.slice(hashPos + hashLen - 1))
    $(id).caret('pos', hashPos + data[suggestion].length - 1);
    lastVal = $(id).typeahead('val');
    // lastVal = $(id).val();
    hashPos = 0;
    hashLen = 0;
  }

  this.typeahead = 
    $(id).typeahead({ hint: false, highlight: false }, { 'limit': 100, 'source': strMatcher(id, data_keys) })
      .on('typeahead:render', function(event, suggestion, async, dataset_name) { onRender(event, suggestion, async, dataset_name); })
      .on('typeahead:select', function(event, suggestion) { setTimeout(function() { onSelect(event, suggestion); }, 0); })
      .on('typeahead:cursorchange', function(event, suggestion) { onCursorChange(event, suggestion); })
      .on('typeahead:change', function(event, suggestion) { onChange(event, suggestion); })
      ;
  $(id).attr('spellcheck', true);
  var lastVal = $(id).typeahead('val');
}
