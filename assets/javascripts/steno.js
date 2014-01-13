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

      // editors
      self.sourceTextEd = self.createEditor('#text-step .editor', 'ace/mode/text');
      self.xmlEd = self.createEditor("#xml-step .editor", 'ace/mode/xml');

      self.initSyncScrolling($('#source-doc-html'), self.sourceTextEd);
      self.initSyncScrolling($('#xml-doc-html'), self.xmlEd);
    };

    /**
     * Create a new editor, using the controls inside
     * +container+.
     *
     * Returns the ACE editor object.
     */
    self.createEditor = function(container, mode) {
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
    };

    /**
     * Update based on a parse of the source text
     */
    self.parsedSource = function(data) {
      console.log(data);

      // update the source text
      var ed = self.sourceTextEd;
      var posn = ed.getCursorPosition();
      var sourceChanged = ed.getValue() != data.source_text;

      if (sourceChanged) {
        ed.setValue(data.source_text);
        ed.clearSelection();
      }

      if (self.setParseErrors(data.parse_errors)) {
        // errors
        ed.gotoLine(data.parse_errors[0].line, data.parse_errors[0].column);
        ed.focus();
      } else {
        // no errors
        // kick of a background render
        self.renderSourceOutput(data.xml);

        if (sourceChanged) {
          ed.gotoLine(posn.row+1, posn.column);
        }
      }
      ed.renderer.scrollCursorIntoView();

      self.setXml(data.xml);
    };

    self.setXml = function(xml) {
      // update the XML
      self.xmlEd.setValue(xml);
      self.xmlEd.clearSelection();
    };

    self.getXml = function() {
      return self.xmlEd.getValue();
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

      return (errors.length > 0);
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

      return (errors.length > 0);
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
      $.ajax('/render', {
        method: 'POST',
        data: {'doc[xml]': xml},
        success: function(data) {
          // update the HTML
          $('#source-doc-html, #xml-doc-html').html(data.html);
          $('#source-doc-toc, #xml-doc-toc').html(data.toc);
        },
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
              if (self.setValidateErrors(data.validate_errors)) {
                // errors
                self.xmlEd.gotoLine(data.validate_errors[0].line, data.validate_errors[0].column);
                self.xmlEd.focus();
              }
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
      $.ajax('/render', {
        method: 'POST',
        data: {'doc[xml]': self.getXml()},
        success: function(data) {
          // update the HTML
          $('#xml-doc-html').html(data.html);
          $('#xml-doc-toc').html(data.toc);
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

      var region = $('[name="doc[meta][region]"').val();
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

      var year = $('[name="doc[meta][pub_date]"').val().split(/-|\//)[0];

      var branch    = ['steno', region, year, shortname].join('-');
      var filename  = [region, year, shortname + '.xml'].join('/');
      var commitmsg = 'Steno export of ' + name + ' of ' + year;

      var btn = $('#export-btn').attr('disabled', 'disabled').addClass('spin');
      
      var exporter = new Steno.GithubExporter();
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
  };
})(jQuery, window);

