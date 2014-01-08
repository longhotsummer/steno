(function($, exports) {
  exports.Steno.GithubAuth = function(clientId, scope) {
    var self = this;
    
    self.clientId = clientId;
    self.scope = scope;

    // ensure we're authenticated with github.
    //
    // Calls +cb(token)+ on completion.
    self.authenticate = function(cb) {
      if (self.getToken()) {
        // we have a token, see if it's valid
        var github = new Github({
          token: self.getToken(),
          auth: 'oauth'
        });

        github.getUser().show(null, function(err, u) {
          if (u) {
            // cool, we're authenticated!
            cb(self.getToken());
          } else {
            // ask user to authenticate
            self.authenticatePopup(cb);
          }
        });
      } else {
        // no token, authenticate
        self.authenticatePopup(cb);
      }
    };

    // open a popup and run the oath pipeline
    self.authenticatePopup = function(cb) {
      var wnd;
      var url = 'https://github.com/login/oauth/authorize?client_id=' + self.clientId + 
                '&scope=' + scope +
                '&state=' + self.newNonce();

      // the popup will post a message when it's done
      var callback = function(e) {
        $('window').off('message', callback);

        var token = e.originalEvent.data.authToken;
        if (token) {
          self.setToken(token);
          cb(self.getToken());
        } else {
          cb(null);
        }
      };
      $('window').on('message', callback);

      // create popup
      var wnd_settings = {
        width: Math.floor(window.outerWidth * 0.8),
        height: Math.floor(window.outerHeight * 0.5)
      };
      if (wnd_settings.height < 350) { wnd_settings.height = 350; }
      if (wnd_settings.width < 800) { wnd_settings.width = 800; }
      wnd_settings.left = window.screenX + (window.outerWidth - wnd_settings.width) / 2;
      wnd_settings.top = window.screenY + (window.outerHeight - wnd_settings.height) / 8;

      var wnd_options = "width=" + wnd_settings.width + ",height=" + wnd_settings.height;
      wnd_options += ",toolbar=0,scrollbars=1,status=1,resizable=1,location=1,menuBar=0";
      wnd_options += ",left=" + wnd_settings.left + ",top=" + wnd_settings.top;

      setTimeout(function() {
        cb(null);
      }, 600 * 1000); // 10 minutes timeout

      // open it
      wnd = window.open(url, "Authorization", wnd_options);
      if (wnd) {
        wnd.focus();
      }
    };

    self.getToken = function() {
      return localStorage['steno.github_token'];
    };

    self.setToken = function(token) {
      localStorage['steno.github_token'] = token;
    };

    self.newNonce = function() {
      var nonce = "";
      for (i = 0; i < 10; i++) {
        nonce += String.fromCharCode(Math.floor(Math.random() * (90-64) + 65));
      }
      return nonce;
    };

  };
})(jQuery, window);
