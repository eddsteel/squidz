(function(){
  function kvS(map, key)
  {
    return key + "=" + map[key];
  }

  function render(obj, amount, callback)
  {
    var queryString = "/render?" + [kvS(obj, 'base'),
      kvS(obj, 'target'), kvS(obj, 'value'),
      'amount='+amount].join('&');
    $.get(queryString, callback);
  }

  function displayLoading()
  {
    var message = '<article id="loadmessage">thinking hard...<div class="links">&nbsp;</div><div class="flip">&nbsp;</div></article>';
    $('#message').prepend(message);
    $('#loadmessage').hide();
    $('#message').attr('className', 'box info');
    $('#loadmessage').slideDown('slow');
  }

  var displayError = function(result) {
    displayMessage('error', '<article>' + result
        + '<div class="links">&nbsp;</div><div class="flip">&nbsp;</div></article>');
  }

  function displayResult(result, amount)
  {
/* TODO Check all errors are served 4* or 5* status codes*/
   if (result['status'] === 'error')
   {
     displayError(result.result.message)
   }
   else if (result['status'] === 'ok')
   {
     var callback = function(html) {
       displayMessage('result', html);
       document.title = $('#message article:first .target-value').text()
     };
     render(result.result, amount, callback);
   }
   else
   {
     displayMessage('error', 'something bad happened.');
   }
   focus_amount();
  }

  function createFlipLink(link)
  {
    var parts = link.attr('href').match(
        /\/([^\/]*)\/([^\/]*)\/([0-9.]*)$/)
    if (parts)
    {
      var fire = function() {
        return fireQuery(parts[3], parts[2], parts[1])
      }

      link.click(fire);
    }
  }

  function displayMessage(cssClass, message)
  {
    $('#message').attr('className', "box " + cssClass);
    $('#loadmessage').replaceWith(message);
    var newArticle = $('#message article:first');
    newArticle.hide();
    newArticle.fadeIn('slow');
    createFlipLink($('#message article:first .flip a'))
  }

  function query(source, target, amount, callback)
  {
    var url = "/" + [source, target, amount].join("/") + ".json";
    $.ajax({
        type: "GET",
        url: url,
        dataType: "json",
        success: callback,
        error: function (xhr, ajaxOptions, thrownError){
          displayError(xhr.responseText)
        }
    });
  }

  function fireQuery(amount, target, source) {
    displayLoading();
    var callback = function(json){
      displayResult(json, amount)
    };
    query(source, target, amount, callback);
    return false;
  }

  var fire = function()
  {
    var amount = $('#amount').val();
    var target = $('#target').val();
    var source = $('#source').val();

    return fireQuery(amount, target, source);
  };

  var focus_amount = function()
  {
    $('#amount').select();
  }

  var start = function()
  {
    $('#form').bind('submit', fire);
    var fliplink = $('#message article:first .flip a');
    if (fliplink.length > 0)
    {
      createFlipLink(fliplink);
    }
  };

  $(document).ready(start);
  $(document).bind('amount_ready', function(){
    if (! Modernizr.input.autofocus)
    {
      focus_amount();
    }
  });
 
// TODO
// * make the form submit to a # url instead, and use
// that.
})();
