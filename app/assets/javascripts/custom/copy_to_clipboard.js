function copyToClipboard(elementId) {
  var el = document.getElementById(elementId);

  if (!navigator.clipboard) {
    ChiirpAlert({
      'body':       'Broswer does NOT support copy to clipboard!',
      'type':       'info',
      'persistent': false
    });
  } else {

    if (el.nodeName === 'INPUT') {
      content = el.value;
    } else {
      content = el.innerHTML;
    }

    navigator.clipboard.writeText(content)
      .then(function() {

        if (content.includes('</') || content.includes('/>')) {
          bodyText = 'Copied code to Clipboard.'
        } else if (content.length > 40) {
          bodyText = 'Copied to Clipboard.'
        } else {
          bodyText = 'Copied \'' + content.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;') + '\' to Clipboard.'
        }

        ChiirpAlert({
          'body':       bodyText,
          'type':       'info',
          'persistent': false
        });
      })
      .catch(function() {
        ChiirpAlert({
          'body':       'Copy Failed!',
          'type':       'info',
          'persistent': false
        });
    });
  }    
}
