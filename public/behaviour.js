(function(){
  function kv_s(map, key)
  {
    return key + "=" + map[key];
  }

  function render(obj, amount, callback)
  {
    var query_string = "/render?" + [kv_s(obj, 'base'), kv_s(obj, 'target'), kv_s(obj, 'value'), 'amount='+amount].join('&');
    $.get(query_string, callback);
  }

  function display_loading()
  {
    var message = '<article id="loadmessage">thinking hard...</article>';
    $('#message').prepend(message);
    $('#loadmessage').hide();
    $('#message')[0].className = 'box info';
    $('#loadmessage').slideDown('slow');
  }

  var display_error = function(result) {
    display_message('error', result)
  }

  function display_result(result, amount)
  {
/* TODO Check all errors are served 4* or 5* status codes*/
   if (result['status'] === 'error')
   {
     display_error(result.result.message)
   }
   else if (result['status'] === 'ok')
   {
     var callback = function(html) {
       display_message('result', html);
       document.title = $('#message article .target-value')[0].innerHTML
     };
     render(result.result, amount, callback);
   }
   else
   {
     display_message('error', 'something bad happened.');
   }
  }

  function display_message(cssClass, message)
  {
    $('#message')[0].className = "box " + cssClass;
    $('#loadmessage').replaceWith(message);
    var newArticle = $('#message article:first');
    newArticle.hide();
    newArticle.fadeIn('slow')
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
          display_error(xhr.responseText)
        }
    });
  }

  var fire = function()
  {
    display_loading();
    var amount = $('#amount')[0].value;
    var target = $('#target')[0].value;
    var source = $('#source')[0].value;

    var callback = function(json){
      display_result(json, amount)
    };
    query(source, target, amount, callback);
    return false;
  };

  $('#form').bind('submit', fire)
// TODO
// * make the form submit to a # url instead, and use
// that.
// * remove [0]s and use proper jQuery stuff.
// * animation
})();
