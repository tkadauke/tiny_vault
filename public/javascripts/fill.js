if (typeof window.TinyVaultKeyIndex == 'undefined') {
  window.TinyVaultKeyIndex = 0;
}

(function () {
  var jQueryAlreadyLoaded = typeof window['jQuery'] != 'undefined';
  var scripts = document.getElementsByTagName('script');
  var scriptURL = scripts[scripts.length - 1].src;
  
  function waitForScript(url, obj) {
    // doesn't work in Opera
    var callback = arguments.callee.caller;
    var args = arguments.callee.caller.arguments;
    var s, ok, timer, doc = document;

    // if the object/function doesn't exist and we've not tried to load it
    // then pull it in and fire the calling function once complete
    if ((typeof window[obj] == 'undefined') && !window['loading' + obj]) {
      window['loading' + obj] = true;

      if (!doc.getElementById('_' + obj)) {
        s = doc.createElement('script');
        s.src = url;
        s.id = '_' + obj;
        doc.body.appendChild(s);
      }

      timer = setInterval(function () {
        ok = false;
        try { 
          ok = (typeof window[obj] != 'undefined');
        } catch (e) {}

        if (ok) {
          clearInterval(timer);
          callback.apply(this);
        }
      }, 10);

      // we're loading in the script now, so we're currently waiting
      return true;
    } else if (typeof window[obj] == 'undefined') {
      // object not defined yet, so we're still waiting
      return true;
    } else {
      // it's already loaded
      return false;
    }
  }

  function getHostname(str) {
    var re = new RegExp('^(?:f|ht)tp(?:s)?\://([^/]+)', 'im');
    return str.match(re)[1].toString();
  }
  
  function fill(jq) {
    var password = jq('form input[type="password"]');
    var form = password.parents('form');
    var username = form.find('input[type="text"],input[type="email"]');
    if (username.length > 0 && password.length > 0) {
      var domain = document.location.host;
      jq.ajax({
        url: 'http://' + getHostname(scriptURL) + '/keys/fill',
        data: {
          "domain" : domain,
        },
        dataType: "jsonp", // Works around same-origin policy
        success: function(data, status, request) {
          if (data) {
            if (data.error) {
              alert(data.error);
            } else {
              var index = window.TinyVaultKeyIndex % data.length;
              username.val(data[index].key.username);
              password.val(data[index].key.password);
              window.TinyVaultKeyIndex ++;
            }
          } else {
            alert('Unerwarteter Fehler');
          }
        }
      });
    } else {
      alert('Konnte Login-Formular nicht ausfüllen');
    }
  }

  (function () {
    if (!waitForScript('http://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js', 'jQuery')) {
      var jq;
      if (jQueryAlreadyLoaded) {
        jq = jQuery;
      } else {
        jq = jQuery.noConflict();
      }
      fill(jq);
    }
  })();
})();
