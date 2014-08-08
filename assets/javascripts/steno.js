//= require github/underscore-min
//= require github/github
//= require_self
//= require github_exporter
//= require github_auth

(function($, exports) {
  var Steno = exports.Steno = {};

  Steno.App = function() {
    var self = this;

    self.sourceTextEd = null;
    self.xmlEd = null;
    self.syncScrolling = true;

    self.init = function() {
      $('#parse-btn').on('click', self.parseSource);
      $('#render-btn').on('click', self.checkAndRenderXml);
      $('#export-btn').on('click', self.exportToGitHub);

      $('#metadata-step button.next-step').on('click', function(e) {
        e.preventDefault();
        $('ul.steps li:eq(1) a').tab('show');
      });
      $('#text-step button.next-step').on('click', function(e) {
        e.preventDefault();
        $('ul.steps li:eq(2) a').tab('show');
      });
      $('#xml-step button.next-step').on('click', function(e) {
        e.preventDefault();
        $('ul.steps li:eq(3) a').tab('show');
      });

      $('#doc-meta-title').on('change', function(e) {
        $('#doc-meta-short_name').val($('#doc-meta-title')
            .val()
            .toLowerCase()
            .replace(/[^\w ]+/g, '')
            .replace(/[0-9]/g, '')
            .trim()
            .replace(/ +/g, '-'));
      });

      // set gazette name
      $('#doc-meta-region').on('change', function(e) {
        $('#doc-meta-pub_name').val($('option:selected', this).data('gazette'));
      });

      // editors
      self.sourceTextEd = self.createEditor('#text-step .editor', 'ace/mode/slaw');
      self.xmlEd = self.createEditor("#xml-step .editor", 'ace/mode/xml');

      self.initSyncScrolling($('#source-doc-html'), self.sourceTextEd);
      self.initSyncScrolling($('#xml-doc-html'), self.xmlEd);

      // dropzone
      self.setupDropzone();

      // github auth
      self.checkAuth();
    };

    /**
     * Create a new editor, using the controls inside
     * +container+.
     *
     * Returns the ACE editor object.
     */
    self.createEditor = function(container, mode) {
      var ed = ace.edit($('pre', container)[0]);
      ed.setTheme("ace/theme/clouds");
      ed.setShowPrintMargin(false);

      var sess = ed.getSession();
      sess.setMode(mode);
      sess.setUseWrapMode(false);

      // setup search bindings
      $('.editor-controls input[name=search]', container).on('keyup', function(event) {
        // enter key
        if (event.keyCode == 13) {
          ed.findNext();
          return;
        }

        var needle = $(this).val();
        ed.find(
          needle, {
          backwards: false,
          start: {row: 0, column: 0},
          });
      });

      $('.editor-controls .find-next', container).on('click', ed.findNext.bind(ed));
      $('.editor-controls .find-prev', container).on('click', ed.findPrevious.bind(ed));
      $('.editor-controls .toggle-wrap', container).on('click', function(e) {
        sess.setUseWrapMode(!$(this).hasClass('active'));
      });

      return ed;
    };

    /**
     * Update based on a parse of the source text
     */
    self.parsedSource = function(data) {
      console.log(data);

      // update the source text
      self.setSourceText(data.source_text);

      if (!self.setParseErrors(data.parse_errors)) {
        // no errors,/ kick of a background render
        self.renderSourceOutput(data.xml);
      }
      self.sourceTextEd.renderer.scrollCursorIntoView();
      self.sourceTextEd.focus();

      self.setXml(data.xml);
    };

    self.setXml = function(xml) {
      var ed = self.xmlEd;

      if (ed.getValue() != xml) {
        var posn = ed.getCursorPosition();
        ed.setValue(xml);
        ed.clearSelection();
        ed.gotoLine(posn.row+1, posn.column);
      }
    };

    self.getXml = function() {
      return self.xmlEd.getValue();
    };

    self.setSourceText = function(text) {
      var ed = self.sourceTextEd;

      if (ed.getValue() != text) {
        var posn = ed.getCursorPosition();
        ed.setValue(text);
        ed.clearSelection();
        ed.gotoLine(posn.row+1, posn.column);
      }
    };

    self.setParseErrors = function(errors) {
      errors = $.map(errors, function(e) { 
        if (e.line && e.column) {
          return {row: e.line-1, column: e.column, text: e.message, type: "error"};
        } else {
          return {};
        }
      });
      self.sourceTextEd.getSession().setAnnotations(errors);

      if (errors.length > 0) {
        self.sourceTextEd.gotoLine(errors[0].row+1, errors[0].column-1);
        return true;
      } else {
        return false;
      }
    };

    self.setValidateErrors = function(errors) {
      errors = $.map(errors, function(e) { 
        if (e.line) {
          return {row: e.line-1, column: e.column, text: e.message, type: "error"};
        } else {
          return {};
        }
      });
      self.xmlEd.getSession().setAnnotations(errors);

      if (errors.length > 0) {
        self.xmlEd.gotoLine(errors[0].row+1, errors[0].column-1);
      }
    };

    /**
     * Parse the source text of the document.
     */
    self.parseSource = function(e) {
      e.preventDefault();

      var btn = $('#parse-btn').attr('disabled', 'disabled').addClass('spin');
      var data = $('#source-form').serializeArray();
      data.push({name: 'doc[source_text]', value: self.sourceTextEd.getValue()});

      $.ajax('/parse', {
        method: 'POST',
        data: data,
        success: self.parsedSource,
        complete: function() {
          btn.removeClass('spin').attr('disabled', null);
        }
      });
    };

    // Synchronise scrolling between the DOM container +node+
    // and the ACE editor +editor+.
    self.initSyncScrolling = function(node, editor) {
      node.on('scroll', function() {
        if (self.syncScrolling) {
          var perc = node.scrollTop() / node[0].scrollHeight;
          var line = Math.floor(editor.getSession().getLength() * perc);
          editor.scrollToLine(line, false, true);
        }
      });
    };

    /**
     * Render the source-to-xml output
     */
    self.renderSourceOutput = function(xml) {
      $('#text-step .render-label').show();
      $.ajax('/render', {
        method: 'POST',
        data: {'doc[xml]': xml},
        success: function(data) {
          // update the HTML
          $('#source-doc-html, #xml-doc-html').html(data.html);
          $('#source-doc-toc, #xml-doc-toc').html(data.toc);
        },
        complete: function() {
          $('#text-step .render-label').hide();
        }
      });
    };

    /**
     * Validate and render the XML editor contents.
     */
    self.checkAndRenderXml = function() {
      var btn = $('#render-btn').attr('disabled', 'disabled').addClass('spin');

      $.ajax('/sanitise', {
        method: 'POST',
        data: {'doc[xml]': self.getXml()},
        success: function(data) {
          console.log(data);

          self.setXml(data.xml);
          self.renderXml();

          $.ajax('/validate', {
            method: 'POST',
            data: {'doc[xml]': self.getXml()},
            success: function(data) {
              console.log(data);
              self.setValidateErrors(data.validate_errors);
              self.xmlEd.focus();
            },
            complete: function() {
              btn.removeClass('spin').attr('disabled', null);
            }
          });
        },
        error: function() {
          btn.removeClass('spin').attr('disabled', null);
        }
      });
    };

    /**
     * Render the XML editor contents.
     */
    self.renderXml = function() {
      $('#xml-step .render-label').show();
      $.ajax('/render', {
        method: 'POST',
        data: {'doc[xml]': self.getXml()},
        success: function(data) {
          // update the HTML
          $('#xml-doc-html').html(data.html);
          $('#xml-doc-toc').html(data.toc);
        },
        complete: function() {
          $('#xml-step .render-label').hide();
        }
      });
    };

    self.exportToGitHub = function(event) {
      var name = $('[name="doc[meta][title]"]').val();
      if (!name) {
        alert("Please give the document a title.");
        $('ul.steps li:eq(0) a').tab('show');
        return;
      }

      var shortname = $('[name="doc[meta][short_name]"]').val();
      if (!shortname) {
        alert("Please enter a short name for the document.");
        $('ul.steps li:eq(0) a').tab('show');
        return;
      }

      var region = $('[name="doc[meta][region]"]').val();
      if (!region) {
        alert("Please choose a region for the document.");
        $('ul.steps li:eq(0) a').tab('show');
        return;
      }

      var filedata = self.getXml();
      if (!filedata) {
        alert("There's nothing to export!");
        $('ul.steps li:eq(1) a').tab('show');
        return;
      }

      var year = $('[name="doc[meta][pub_date]"]').val().split(/-|\//)[0];

      var branch    = ['steno', region, year, shortname].join('-');
      var filename  = ['by-laws', region, year, shortname + '.xml'].join('/');
      var commitmsg = 'Steno export of ' + name + ' of ' + year;

      var btn = $('#export-btn').attr('disabled', 'disabled').addClass('spin');
      
      var exporter = new Steno.GithubExporter(self.githubAuth);
      exporter.exportToGithub(branch, filename, filedata, commitmsg, function(success, msg) {
        btn.removeClass('spin').attr('disabled', null);

        if (success) {
          var url = exporter.getExportedUrl();
          $('#export-info').html('Saved to <a target="_blank" href="' + url + '">' + url + '</a>.');
        } else {
          $('#export-info').text(msg);
        }
      });
    };

    self.setupDropzone = function() {
      // the whole page is a dropzone
      var dropzone = new Dropzone("#wrapper", {
        previewsContainer: '#dropzone',
        maxFilesize: 10,
        acceptedFiles: 'text/plain,application/pdf',
        url: '/convert-to-text',
        clickable: ['button.import-source'],
      });

      var spinner = $("#import-spinner"),
          btn = $('button.import-source');

      dropzone
        .on('addedfile', function(e) {
          btn.prop('disabled', true);
          spinner.show();
        })
        .on('success', self.fileImported)
        .on('complete', function(e) {
          btn.prop('disabled', false);
          spinner.hide();
        });
    };

    self.fileImported = function(file) {
      var json = $.parseJSON(file.xhr.response);

      if (json.error) {
        alert(json.error);
        return;
      }

      if (self.sourceTextEd.getValue()) {
        if (!confirm('This will overwrite any existing text. Are you sure?')) {
          return;
        }
      }

      self.sourceTextEd.setValue(json.text);
      self.sourceTextEd.clearSelection();
      self.sourceTextEd.gotoLine(0, 0);
      self.sourceTextEd.focus();
    };

    // see if the user is logged in, and update the display if they are
    self.checkAuth = function() {
      self.githubAuth = new Steno.GithubAuth('7aeef0a6887e9e035a65', 'public_repo');
      // event handlers
      self.githubAuth.onAuthenticate = self.githubAuth.onAuthenticateFailed = self.setGithubUser;

      self.githubAuth.checkAuthenticated(self.setGithubUser);

      $('header .github-login').on('click', self.login);
      $('header .github-logout').on('click', self.logout);
    };

    self.login = function(e) {
      if (e) e.preventDefault();
      self.githubAuth.authenticate(function() {});
    };

    self.logout = function(e) {
      if (e) e.preventDefault();

      self.githubAuth.clearToken();
      self.setGithubUser(null);
    };

    self.setGithubUser = function(user) {
      if (user) {
        $('header .github-user .username').text(user.login);
        $('header .github-user .user-repo').attr('href', user.html_url + '/za-by-laws');
        $('header .github-user .repo').text(user.login + '/za-by-laws');

        $('header .github-login').hide();
        $('header .github-user').show();
      } else {
        $('header .github-user').hide();
        $('header .github-login').show();
      }
    };
  };
})(jQuery, window);
