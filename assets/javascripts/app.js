//= require bootstrap

$(function() {
  var GitHubExporter = function() {
    this.exportToGitHub = function(branch, filename, data, cb) {
      this.branch = branch;
      this.filename = filename;
      this.filedata = data;
      this.cb = cb;
      
      // kick everything off
      this.ensureAuth();
    };

    // 1. check for a repo, fork if missing
    // 2. check for a branch, create if missing
    // 3. push file
    // 4. create pull request

    // ensure we have an auth token and setup
    // the github client
    this.ensureAuth = function() {
      // TODO: check for token
      
      this.username = 'longhotsummer';
      this.github = new Github({
        token: 'ABC123',
        auth: 'oauth'
      });

      this.repo = github.getRepo(this.username, 'za-by-laws');

      // continue with the chain
      this.ensureRepo();
    };

    // ensure we have a repo, fork if we don't, and ensure
    // we have a correctly named branch
    this.ensureRepo = function() {
      this.repo.show(function(err, repo) {
        if (repo) {
          // repo exists

          this.ensureBranch();
        } else {
          // repo doesn't exist, fork it

          this.github.getRepo('longhotsummer', 'za-by-laws').fork(function(err) {
            if (!err) {
              this.waitForFork();
            } else {
              this.writeFailed('Error forking repo: ' + err.error);
            }
          });
        }
      });
    };

    // wait for the fork operation to complete
    this.waitForFork = function() {
      this.repo.listBranches(function(err, branches) {
        if (typeof branches === 'undefined') {
          // keep waiting
          setTimeout(this.waitForFork, 1000);

        } else {
          // forked, next step

          this.ensureBranch();
        }
      });
    };

    // ensure the appropriate branch exists
    this.ensureBranch = function() {
      // does the branch exist?
      this.repo.branch(this.branch, function(err) {
        if (!err || err.error == 422) {
          // branch exists
          this.writeFile();
        } else {
          this.writeFailed('Error creating branch: ' + err.error);
        }
      });
    };

    // actually write to the file
    this.writeFile = function() {
      this.repo.write(this.branch, this.filename, this.filedata, this.commitmsg, function(err) {
        if (!err) {
          this.createPullRequest();
        } else {
          this.writeFailed('Error writing to github: ' + err);
        }
      });
    };

    // create the final pull request
    this.createPullRequest = function() {
      // TODO
      this.writeSucceeded();
    };

    this.writeSucceeded = function() {
      this.cb(true, null);
    };

    this.writeFailed = function(msg) {
      this.cb(false, msg);
    };
  };

  var Steno = {
    sourceTextEd: null,
    xmlEd: null,
    syncScrolling: true,

    init: function() {
      $('#parse-btn').on('click', Steno.parseSource);
      $('#render-btn').on('click', Steno.checkAndRenderXml);
      $('#export-btn').on('click', Steno.GitHub.exportToGitHub);

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

      // editors
      Steno.sourceTextEd = Steno.createEditor('#text-step .editor', 'ace/mode/text');
      Steno.xmlEd = Steno.createEditor("#xml-step .editor", 'ace/mode/xml');

      Steno.initSyncScrolling($('#source-doc-html'), Steno.sourceTextEd);
      Steno.initSyncScrolling($('#xml-doc-html'), Steno.xmlEd);
    },

    /**
     * Create a new editor, using the controls inside
     * +container+.
     *
     * Returns the ACE editor object.
     */
    createEditor: function(container, mode) {
      var ed = ace.edit($('pre', container)[0]);
      ed.setTheme("ace/theme/chrome");
      ed.setShowPrintMargin(false);

      var sess = ed.getSession();
      sess.setMode(mode);
      sess.setUseWrapMode(true);

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

      return ed;
    },

    /**
     * Update based on a parse of the source text
     */
    parsedSource: function(data) {
      console.log(data);

      // update the source text
      var ed = Steno.sourceTextEd;
      var posn = ed.getCursorPosition();
      var sourceChanged = ed.getValue() != data.source_text;

      if (sourceChanged) {
        ed.setValue(data.source_text);
        ed.clearSelection();
      }

      if (Steno.setParseErrors(data.parse_errors)) {
        // errors
        ed.gotoLine(data.parse_errors[0].line, data.parse_errors[0].column);
        ed.focus();
      } else {
        // no errors
        // kick of a background render
        Steno.renderSourceOutput(data.xml);

        if (sourceChanged) {
          ed.gotoLine(posn.row+1, posn.column);
        }
      }
      ed.renderer.scrollCursorIntoView();

      // update the XML
      ed = Steno.xmlEd;
      ed.setValue(data.xml);
      ed.clearSelection();

    },

    setParseErrors: function(errors) {
      errors = $.map(errors, function(e) { 
        if (e.line && e.column) {
          return {row: e.line-1, column: e.column, text: e.message, type: "error"};
        } else {
          return {};
        }
      });
      Steno.sourceTextEd.getSession().setAnnotations(errors);

      return (errors.length > 0);
    },

    setValidateErrors: function(errors) {
      errors = $.map(errors, function(e) { 
        if (e.line) {
          return {row: e.line-1, column: e.column, text: e.message, type: "error"};
        } else {
          return {};
        }
      });
      Steno.xmlEd.getSession().setAnnotations(errors);

      return (errors.length > 0);
    },

    /**
     * Parse the source text of the document.
     */
    parseSource: function(e) {
      e.preventDefault();

      var btn = $('#parse-btn').attr('disabled', 'disabled').addClass('spin');
      var data = $('#source-form').serializeArray();
      data.push({name: 'doc[source_text]', value: Steno.sourceTextEd.getValue()});

      $.ajax('/parse', {
        method: 'POST',
        data: data,
        success: Steno.parsedSource,
        complete: function() {
          btn.removeClass('spin').attr('disabled', null);
        }
      });
    },

    // Synchronise scrolling between the DOM container +node+
    // and the ACE editor +editor+.
    initSyncScrolling: function(node, editor) {
      node.on('scroll', function() {
        if (Steno.syncScrolling) {
          var perc = node.scrollTop() / node[0].scrollHeight;
          var line = Math.floor(editor.getSession().getLength() * perc);
          editor.scrollToLine(line, false, true);
        }
      });
    },

    /**
     * Render the source-to-xml output
     */
    renderSourceOutput: function(xml) {
      $.ajax('/render', {
        method: 'POST',
        data: {'doc[xml]': xml},
        success: function(data) {
          // update the HTML
          $('#source-doc-html, #xml-doc-html').html(data.html);
          $('#source-doc-toc, #xml-doc-toc').html(data.toc);
        },
      });
    },

    /**
     * Validate and render the XML editor contents.
     */
    checkAndRenderXml: function() {
      var xml = Steno.xmlEd.getValue();

      Steno.renderXml();

      $.ajax('/validate', {
        method: 'POST',
        data: {'doc[xml]': xml},
        success: function(data) {
          console.log(data);
          if (Steno.setValidateErrors(data.validate_errors)) {
            // errors
            Steno.xmlEd.gotoLine(data.validate_errors[0].line, data.validate_errors[0].column);
            Steno.xmlEd.focus();
          }
        }
      });
    },

    /**
     * Render the XML editor contents.
     */
    renderXml: function() {
      var xml = Steno.xmlEd.getValue();

      var btn = $('#render-btn').attr('disabled', 'disabled').addClass('spin');

      $.ajax('/render', {
        method: 'POST',
        data: {'doc[xml]': xml},
        success: function(data) {
          // update the HTML
          $('#xml-doc-html').html(data.html);
          $('#xml-doc-toc').html(data.toc);
        },
        complete: function() {
          btn.removeClass('spin').attr('disabled', null);
        }
      });
    },

    exportToGitHub: function(event) {
      new GitHubExporter().exportToGitHub(branch, filename, filedata, function(success, msg) {
        if (success) {
          // TODO
        } else {
          // TODO
        }
      });
    },
  };

  Steno.init();
});
